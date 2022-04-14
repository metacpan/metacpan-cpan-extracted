package cPanel::StateFile;
$cPanel::StateFile::VERSION = '0.903';
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
$DefaultLogger::VERSION = '0.903';
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
    die 'Policies already set elsewhere'                     if $are_policies_set;
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
$cPanel::StateFile::Guard::VERSION = '0.903';
sub new {
            my ( $class, $args_ref ) = @_;
            $pkg->throw('Args parameter must be a hash reference.') unless 'HASH' eq ref $args_ref;
            $pkg->throw('No StateFile.')                            unless exists $args_ref->{state};

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

        sub _in_child {
            my ($self) = @_;

            # Ensure that the child process does not
            # remove the lock as that is the job of
            # the parent.
            $self->{'lock_file'}   = undef;
            $self->{'file_handle'} = undef;

            return;
        }

        sub _unlock {
            my $self       = shift;
            my $state_file = $self->{state_file};
            return unless $self->{lock_file};

            if ( $state_file->{file_handle} ) {

                # Try a non-blocking call first as
                # it will avoid two alarm syscalls
                # if possible.
                # If the nonblocking call does not
                # complete right away we fallback to
                # the full expensive
                # signal handler setup/alarm/flock/alarm call
                if ( !flock $state_file->{file_handle}, 8 | Fcntl::LOCK_NB() ) {

                    # TODO probably need to check for failure, but then what do I do?
                    eval {
                        local $SIG{'ALRM'} = sub { die "flock 8 timeout\n"; };
                        my $orig_alarm = alarm $state_file->{flock_timeout};
                        flock $state_file->{file_handle}, 8;
                        alarm $orig_alarm;
                    };
                }
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

            # Try a non-blocking call first as
            # it will avoid two alarm syscalls
            # if possible.
            # If the nonblocking call does not
            # complete right away we fallback to
            # the full expensive
            # signal handler setup/alarm/flock/alarm call
            if ( !flock $fh, 2 | Fcntl::LOCK_NB() ) {

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
            }
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
          and eval { $data_obj->can('save_to_cache') };

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


=head1 NAME

cPanel::StateFile - Standardize the handling of file-based state data.

=head1 SYNOPSIS

    use cPanel::StateFile;

    # create some cacheable object $obj.
    # ...

    my $state = cPanel::StateFile->new(
        { state_file => '/path/to/state/file', data_obj => $obj }
    );
    $state->synch(); # now memory and disk match.

    # Prepare to make a change to object.

    {
        my $guard = $state->synch();
        # Cache is now locked against changes
        # make changes to $obj
        $obj->modify();

        # update state
        $guard->update_file();
    }
    # state matches memory and file is unlocked.

=head1 DESCRIPTION

We have a generic need to be able to safely state data in a disk file. Unfortunately,
we've redeveloped this multiple times in slightly different ways. I needed yet another
implementation, so I decided to do it more generically.

The safety is provided by a pair of cooperating classes: C<cPanel::StateFile> and
C<cPanel::StateFile:Guard>. The C<Guard> object provides safe locking and makes
certain that the lock is always released in the face of exceptions and such.

The C<Guard> object is returned by the C<cPanel::StateFile::synch()> method that
reads the disk data into the memory object. If you don't store this object, the
lock is immediately released. If you hold the C<Guard> object, you can write to
the disk using the C<Guard::update_file()> method.

=head1 INTERFACE

The interface for this system is described in two parts: C<cPanel::StateFile> and
C<cPanel::StateFile::Guard>.

=head2 cPanel::StateFile

The C<cPanel::StateFile> interface creates the state file and provides a way to lock
and read the file. For methods to modify the state on disk, see the next section on
L<cPanel::StateFile::Guard>.

=over 4

=item cPanel::StateFile->new( $hashref )

Create a new cPanel::StateFile object. The only parameter is a hashref that contains
the following parameters:

=over 4

=item I<cache_file>

I<Deprecated> option that is now replaced by I<state_file>.

=item I<state_file>

This parameter is I<required>. The path to the state file that we use for this data.

=item I<data_obj>

This parameter is I<required>. The data object that will be cached in the file.
This object must support two methods for dealing with the state file.

=item I<locker>

This optional parameter supplies a file locking object to replace the default
declared for the StateFile class. See the section on L</"FILE LOCKER OBJECT">
for the interface this class must provide.

If this object is not provided, it will default to the class-level object
supplied on C<import> or an object of the default C<cPanel::StateFile::FileLocker>
class. This class is only C<use>d if no object is provided.

=item I<logger>

This optional parameter supplies a logging object to replace the default
declared for the StateFile class. See the section on L</"LOGGER OBJECT">
for the interface this class must provide.

If this object is not provided, it will default to the class-level object
supplied on C<import> or an object of the C<DefaultLogger> class.

=over 4

=item $obj->load_from_cache( $fh )

Will receive an opened file handle to read the data from.

This method is not responsible for opening or closing the filehandle. This
method will only be called when the C<StateFile> object determines that the
data needs to be re-read, so you do not need to try to figure that out yourself.

The method should throw an exception on failure.

=item $obj->save_to_cache( $fh )

Will receive an opened file handle pointing to the truncated file on which to
write the data.

This method is not responsible for opening or closing the filehandle. This
method will only be called when the C<StateFile> object determines that the
data needs to be saved, so you do not need to figure that out in this method.

The method should throw an exception on failure.

=back

=item I<timeout>

This I<optional> parameter specifies the timeout in seconds for C<flock>ing the
file on open. The default value is 60 seconds.

=back

=item $state->synch()

This method is called to make sure that the memory version of the data matches
the disk version. If the state file doesn't exist, this method makes certain
the C<Guard::update_file()> is called to create the initial version.

If the disk file is newer than the version in memory, the data object is given
a chance to load itself. THe file is locked for the duration on the read and the
lifetime of the returned C<Guard> object. If the C<Guard> object is not stored,
the file is immediately closed and unlocked.

=item $cache->get_logger()

Return the logger object used by the C<StateFile> object. See the section on
L</"LOGGER OBJECT"> for the interface this object provides.

=item $state->throw( $msg )

Log the supplied message and C<die>.

=item $state->warn( $msg )

Log the supplied message as a warning.

=item $state->info( $msg )

Log the supplied message as an informational message.

=back

=head2 cPanel::StateFile::Guard

The C<cPanel::StateFile::Guard> interface provides the writing methods and makes the locking
safe. Once you have a guard, there is no reason to load data from the disk file, the
in-memory copy matches the disk copy.

=over 4

=item $guard->update_file()

Overwrite the state file from the memory object. This destroys whatever was in the
file on disk and replaces it with what is in memory.

This method performs its work using the C<save_to_file> method of the data object
associated with the C<StateFile> object.

=item $guard->call_unlocked( $coderef )

Sometimes, it is necessary to call a long-running process while you have the queue
locked. You don't want to leave the queue locked, so that other processes can access
it. But several blocks of locking and unlocking code can quickly result in race
conditions.

This method solves that problem. It is called with a code reference. The queue lock
is temporarily released, we run the code, and then the queue lock is reacquired.
This allows one lock to protect code that works on the queue, without blocking on
other code forever.

=back

=head1 LOGGER OBJECT

By default, the C<StateFile> uses C<die> and C<warn> for all messages during
runtime. However, it supports a mechanism that allows you to insert a
logging/reporting system in place by providing an object to do the logging for
us.

To provide a different method of logging/reporting, supply an object to do the
logging as follows when C<use>ing the module.

   use cPanel::StateFile ( '-logger' => $logger );

The supplied object should supply (at least) 4 methods: C<throw>, C<warn>,
C<info>, and C<notify>. When needed, these methods will be called with the
messages to be logged.

For example, an appropriate class for C<Log::Log4perl> and C<Email::Sender>
might do something like the following:

    package Policy::Log4perl;
    use strict;
    use warnings;
    use Log::Log4perl;
    use Email::Sender::Simple;
    use Email::Simple;
    use Email::Simple::Creator;

    sub new {
        my ($class) = shift;
        my $self = {
            logger => Log::Log4perl->get_logger( @_ )
        };
        return bless, $class;
    }

    sub throw {
        my $self = shift;
        $self->{logger}->error( @_ );
        die @_;
    }

    sub warn {
        my $self = shift;
        $self->{logger}->warn( @_ );
    }

    sub info {
        my $self = shift;
        $self->{logger}->info( @_ );
    }

    sub notify {
        my $self = shift;
        my $subj = shift;
        my $email = Email::Simple->create(
            header => [
                From => 'taskqueue@example.com',
                To => 'sysadmin@example.com',
                Subject => $subj,
            ],
            body => shift,
        );
        Email::Sender::Simple::sendmail( $email );
    }

This would call the C<Log4perl> code as errors or other messages result in
messages.

This only works once for a given program, so you can't reset the policy in
multiple modules and expect it to work.

In addition to setting a global logger, a new logger object can be supplied
when creating a specific C<StateFile> object.

=head2 throw( $msg )

This method is expected to log or report the critical error condition supplied
as an argument and then use C<die> to exit the method.

=head2 warn( $msg )

This method is expected to log or report a warning condition using the supplied
message and then return.

=head2 info( $msg )

This method is expected to optionally report or log the supplied informational
message and then return.

=head2 notify( $subj, $msg )

This method is expected to perform some form of critical notification of the
triggering condition (such as an email to an appropriate administrator). The
first argument is a summary or title and the second is the body of the supplied message.

The method should return on completion.

=head1 FILE LOCKER OBJECT

The default file locking policy is build around the C<flock> function. However,
this method may not be appropriate in all circumstances. So C<StateFile> supports
the ability to replace the locking policy by supplying a file locking object.

To provide a different method of file locking, use the following syntax when
C<use>ing the module.

   use cPanel::StateFile ( '-filelock' => $locker );

The supplied object should supply (at least) 2 methods: C<file_lock>, and
C<file_unlock>.

=over 4

=item file_lock( $file )

To the class name, this method receives the name of the file to protect with
the lock. This is B<not> the name of a lock file. The method should return a
token that is passed to the C<file_unlock> method to tell which lock to unlock.

If the method coannot protect (or lock) the file, the method should throw an exception.

=item file_unlock( $lock )

To the class name, this method receives the return value from the C<file_lock>
method to use when unprotecting the file.

=back

=head1 DEPENDENCIES

L<Fcntl> and L<File::Path>.

=head1 BUGS AND LIMITATIONS

At present, the C<synch> system detects changes in the file by means of the file's
modification time and size. If a file is modified within the resolution of the mtime
and it's size does not change, it may not be detected.

=head1 COPYRIGHT

Copyright (c) 2014, cPanel, Inc. All rights resrved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

