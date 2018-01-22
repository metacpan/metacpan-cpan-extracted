package cPanel::StateFile;
$cPanel::StateFile::VERSION = '0.850';
use strict;

#use warnings;

use Fcntl        ();
use Scalar::Util ();

my $the_logger;
my $the_locker;

# Simplifies having both classes in the module use the same package.
my $pkg = __PACKAGE__;

# -----------------------------------------------------------------------------
# Policy code: The following allows the calling code to supply two objects that
# specify the behavior for logging and file locking. This approach was applied
# to allow these policies to be changed without requiring the overhead of the
# default implementations.

# The default logging code is simple enough that I am including it inline
# instead of making a separate class file. All methods are forwarded to the
# CORE C<die> and C<warn> functions.
{

    package DefaultLogger;
$DefaultLogger::VERSION = '0.850';
sub new {
        my ($class) = @_;
        return bless {}, $class;
    }

    sub throw {
        my $self = shift;
        die @_;
    }

    sub warn {
        my $self = shift;
        CORE::warn @_;
        return;
    }

    sub info {
        my $self = shift;
        CORE::warn @_;
        return;
    }

    sub notify {
        my $self = shift;
        return;
    }
}

sub _throw {
    my $self = shift;
    _get_logger()->throw(@_);
}

sub _warn {
    my $self = shift;
    _get_logger()->warn(@_);
}

sub _notify {
    my $self = shift;
    _get_logger()->notify(@_);
}

# We never use _info, so remove it

sub _get_logger {
    unless ( defined $the_logger ) {
        $the_logger = DefaultLogger->new();
    }
    return $the_logger;
}

sub _get_locker {
    unless ( defined $the_locker ) {
        eval 'use cPanel::StateFile::FileLocker;';    ## no critic (ProhibitStringyEval)
        $pkg->_throw(@_) if $@;
        $the_locker = cPanel::StateFile::FileLocker->new( { logger => _get_logger() } );
    }
    return $the_locker;
}

my $are_policies_set = 0;

#
# This method allows changing the policies for logging and locking.
sub import {
    my ( $class, @args ) = @_;
    die 'Not an even number of arguments to the $pkg module' if @args % 2;
    die 'Policies already set elsewhere' if $are_policies_set;
    return 1 unless @args;    # Don't set the policies flag.

    while (@args) {
        my ( $policy, $object ) = splice( @args, 0, 2 );
        next unless defined $object;
        if ( '-logger' eq $policy ) {
            unless ( ref $object ) {
                eval "use $object;";    ## no critic (ProhibitStringyEval)
                die $@ if $@;

                # convert module into an object.
                $object = $object->new;
            }
            die 'Supplied logger object does not support the correct interface.'
              unless _valid_logger($object);
            $the_logger = $object;
        }
        elsif ( '-filelock' eq $policy ) {
            unless ( ref $object ) {
                eval "use $object;";    ## no critic (ProhibitStringyEval)
                die $@ if $@;

                # convert module into an object.
                $object = $object->new;
            }
            die 'Supplied filelock object does not support the correct interface.'
              unless _valid_file_locker($object);
            $the_locker = $object;
        }
        else {
            die "Unrecognized policy '$policy'";
        }
    }
    $are_policies_set = 1;
    return 1;
}

{

    #
    # Nested class to handle locking cleanly.
    #
    # Locks the file on creation, throwing on failure. Unlocks the file when
    # the object is destroyed.
    {

        package cPanel::StateFile::Guard;
$cPanel::StateFile::Guard::VERSION = '0.850';
sub new {
            my ( $class, $args_ref ) = @_;
            $pkg->throw('Args parameter must be a hash reference.') unless 'HASH' eq ref $args_ref;
            $pkg->throw('No StateFile.') unless exists $args_ref->{state};

            my $self = bless { state_file => $args_ref->{state} }, $class;

            $self->_lock();

            return $self;
        }

        sub DESTROY {
            my ($self) = @_;

            # make certain that an exception here cannot escape and won't effect
            #   exceptions currently in progress.
            local $@;
            eval { $self->_unlock(); };
            return;
        }

        sub _lock {
            my $self       = shift;
            my $state_file = $self->{state_file};

            my $filename = $state_file->{file_name};
            $self->{lock_file} = $state_file->{locker}->file_lock($filename);
            $state_file->throw("Unable to acquire file lock for '$filename'.") unless $self->{lock_file};
            return;
        }

        sub _unlock {
            my $self       = shift;
            my $state_file = $self->{state_file};
            return unless $self->{lock_file};

            if ( $state_file->{file_handle} ) {

                # TODO probably need to check for failure, but then what do I do?
                eval {
                    local $SIG{'ALRM'} = sub { die "flock 8 timeout\n"; };
                    my $orig_alarm = alarm $state_file->{flock_timeout};
                    flock $state_file->{file_handle}, 8;
                    alarm $orig_alarm;
                };
                close $state_file->{file_handle};
                $state_file->{file_handle} = undef;

                # Update size and timestamp after close.
                @{$state_file}{qw(file_size file_mtime)} = ( stat( $state_file->{file_name} ) )[ 7, 9 ];
            }
            $state_file->{locker}->file_unlock( $self->{lock_file} );
            $self->{lock_file} = undef;
            return;
        }

        sub call_unlocked {
            my ( $self, $code ) = @_;
            my $state_file = $self->{state_file};
            $state_file->throw('Cannot nest call_unlocked calls.')  unless defined $self->{lock_file};
            $state_file->throw('Missing coderef to call_unlocked.') unless 'CODE' eq ref $code;

            # unlock for the duration of the code execution
            $self->_unlock();
            eval { $code->(); };
            my $ex = $@;

            # relock even if exception.
            $self->_lock();

            # probably should resync if necessary.
            $state_file->_resynch($self);

            $pkg->_throw($ex) if $ex;

            return;
        }

        sub _open {
            my ( $self, $mode ) = @_;
            my $state_file = $self->{state_file};
            $state_file->throw('Cannot open state file inside a call_unlocked call.') unless defined $self->{lock_file};

            open my $fh, $mode, $state_file->{file_name}
              or $state_file->throw("Unable to open state file '$state_file->{file_name}': $!");
            eval {
                local $SIG{'ALRM'} = sub { die "flock 2 timeout\n"; };
                my $orig_alarm = alarm $state_file->{flock_timeout};
                flock $fh, 2;
                alarm $orig_alarm;
                1;
            } or do {
                close($fh);
                if ( $@ eq "flock 2 timeout\n" ) {
                    $state_file->throw('Guard timed out trying to open state file.');
                }
                else {
                    $state_file->throw($@);
                }
            };
            $state_file->{file_handle} = $fh;
        }

        sub update_file {
            my ($self) = @_;
            my $state_file = $self->{state_file};
            $state_file->throw('Cannot update_file inside a call_unlocked call.') unless defined $self->{lock_file};

            if ( !$state_file->{file_handle} ) {
                if ( -e $state_file->{file_name} ) {
                    $self->_open('+<');
                }
                else {
                    sysopen( my $fh, $state_file->{file_name}, &Fcntl::O_CREAT | &Fcntl::O_EXCL | &Fcntl::O_RDWR )
                      or $state_file->throw("Cannot create state file '$state_file->{file_name}': $!");
                    $state_file->{file_handle} = $fh;
                }
            }
            seek( $state_file->{file_handle}, 0, 0 );
            truncate( $state_file->{file_handle}, 0 )
              or $state_file->throw("Unable to truncate the state file: $!");

            $state_file->{data_object}->save_to_cache( $state_file->{file_handle} );
            $state_file->{file_mtime} = ( stat( $state_file->{file_handle} ) )[9];

            # Make certain we are at end of file.
            seek( $state_file->{file_handle}, 0, 2 )
              or $state_file->throw("Unable to go to end of file: $!");
            $state_file->{file_size} = tell( $state_file->{file_handle} );
            return;
        }

    }

    # Back to StateFile

    sub new {
        my ( $class, $args_ref ) = @_;
        my $self = bless {}, $class;
        if ( exists $args_ref->{logger} && _valid_logger( $args_ref->{logger} ) ) {
            $self->{logger} = $args_ref->{logger};
        }
        else {
            $self->{logger} = $pkg->_get_logger();
            if ( exists $args_ref->{logger} ) {
                $self->throw('Supplied logger does not support required methods.');
            }
        }
        if ( exists $args_ref->{locker} && _valid_file_locker( $args_ref->{locker} ) ) {
            $self->{locker} = $args_ref->{locker};
        }
        else {
            $self->{locker} = $pkg->_get_locker();
            if ( exists $args_ref->{locker} ) {
                $self->throw('Supplied locker does not support required methods.');
            }
        }
        $args_ref->{state_file} ||= $args_ref->{cache_file} if exists $args_ref->{cache_file};
        $self->throw('No state filename supplied.') unless exists $args_ref->{state_file};
        $self->throw('No data object supplied.')    unless exists $args_ref->{data_obj};
        my $data_obj = $args_ref->{data_obj};
        $self->throw('Data object does not have required interface.')
          unless eval { $data_obj->can('load_from_cache') }
          and eval    { $data_obj->can('save_to_cache') };

        my ( $dirname, $file ) = ( $args_ref->{state_file} =~ m{^(.*)/([^/]*)$}g );
        $dirname =~ s{[^/]+/\.\./}{/}g;    # resolve parent references
        $dirname =~ s{[^/]+/\.\.$}{};
        $dirname =~ s{/\./}{/}g;           # resolve self references
        $dirname =~ s{/\.$}{};
        if ( !-d $dirname ) {
            require File::Path;
            File::Path::mkpath( $dirname, 0, 0700 )
              or $self->throw("Unable to create Cache directory ('$dirname').");
        }
        else {
            chmod( 0700, $dirname ) if ( ( stat(_) )[2] & 0777 ) != 0700;
        }

        $self->{file_name} = "$dirname/$file";

        $self->{data_object}   = $data_obj;
        $self->{file_mtime}    = -1;
        $self->{file_size}     = -1;
        $self->{file_handle}   = undef;
        $self->{flock_timeout} = $args_ref->{timeout} || 60;
        Scalar::Util::weaken( $self->{data_object} );

        $self->synch();

        return $self;
    }

    #
    # Return true if the supplied logger object implements the correct
    # interface, false otherwise.
    sub _valid_logger {
        my ($logger) = @_;

        foreach my $method (qw/throw warn info notify/) {
            return unless eval { $logger->can($method) };
        }

        return 1;
    }

    #
    # Return true if the supplied file locker object implements the correct
    # interface, false otherwise.
    sub _valid_file_locker {
        my ($locker) = @_;

        foreach my $method (qw/file_lock file_unlock/) {
            return unless eval { $locker->can($method) };
        }

        return 1;
    }

    sub synch {
        my ($self) = @_;

        my $caller_needs_a_guard = defined wantarray;

        # need to set the lock asap to avoid any concurrency problem
        my $guard;

        if ( !-e $self->{file_name} ) {
            $guard = cPanel::StateFile::Guard->new( { state => $self } );

            # File doesn't exist or is empty, initialize it.
            $guard->update_file();
        }
        elsif ( -z _ ) {

            # If the file is zero bytes this does not mean that
            # it will be after we get a lock because another process
            # could be writing to it while we did the stat
            $guard = cPanel::StateFile::Guard->new( { state => $self } );

            # After we got our lock we check again to see
            # if its really zero and it wasn't just another process
            # writing to it
            if ( -z $self->{file_name} ) {

                # Its really zero because we have a lock
                # and we re-checked the file
                $guard->update_file();
            }
            else {
                # after the lock the other process
                # had finished with it and its not
                # zero anymore so we reload it now
                # and continue on
                my ( $mtime, $size ) = ( stat(_) )[ 9, 7 ];
                $self->_resynch( $guard, $mtime, $size );

            }
        }
        else {
            if ($caller_needs_a_guard) {
                $guard = cPanel::StateFile::Guard->new( { state => $self } );
            }
            my ( $mtime, $size ) = ( stat(_) )[ 9, 7 ];
            $self->_resynch( $guard, $mtime, $size );
        }

        # if not assigned anywhere, let the guard die.
        return if !$caller_needs_a_guard;

        # Otherwise return it.
        return $guard;
    }

    sub _resynch {
        my ( $self, $guard, $mtime, $size ) = @_;

        if ( !$mtime || !$size ) {
            ( $mtime, $size ) = ( stat( $self->{file_name} ) )[ 9, 7 ];
        }

        # CPANEL-11795: Timewarp safety.  If time moves backwards we can loop forever
        if ( $self->{file_mtime} < $mtime || $self->{file_size} != $size || $self->{file_mtime} > time() ) {

            # File is newer or a different size
            $guard ||= cPanel::StateFile::Guard->new( { state => $self } );
            $guard->_open('+<');
            $self->{data_object}->load_from_cache( $self->{file_handle} );
            ( $self->{file_mtime}, $self->{file_size} ) = ( stat( $self->{file_handle} ) )[ 9, 7 ];
        }

        return $guard;
    }

    sub get_logger { return $_[0]->{logger}; }

    sub throw {
        my $self = shift;
        return $self->{logger}->throw(@_);
    }

    sub warn {
        my $self = shift;
        return $self->{logger}->warn(@_);
    }

    sub info {
        my $self = shift;
        return $self->{logger}->info(@_);
    }
}

1;

__END__

Copyright (c) 2010, cPanel, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

