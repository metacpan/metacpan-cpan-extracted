package XAS::Lib::Lockmgr::Filesystem;

our $VERSION = '0.03';

use DateTime;
use DateTime::Span;
use Try::Tiny::Retry ':all';
use XAS::Constants 'TRUE FALSE HASHREF';

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Base',
  mixin      => 'XAS::Lib::Mixins::Process XAS::Lib::Mixins::Handlers',
  utils      => 'dotid',
  import     => 'class',
  filesystem => 'Dir File',
  accessors  => 'deadlock breaklock timeout attempts _lockfile _lockdir',
  vars => {
    PARAMS => {
      -key  => 1,
      -args => { optional => 1, type => HASHREF, default => {} },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Overrides
# ----------------------------------------------------------------------

class('Badger::Filesystem')->methods(
    directory_exists => sub {
        my $self = shift;
        my $dir  = shift;
        my $stats = $self->stat_path($dir) || return; 
        return -d $dir ? $stats : 0;  # don't use the cached stat
    },
    file_exists => sub {
        my $self = shift;
        my $file = shift; 
        my $stats = $self->stat_path($file) || return; 
        return -f $file ? $stats : 0;  # don't use the cached stat
    }
);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub lock {
    my $self = shift;

    my $stat = FALSE;
    my $lock = $self->_lockfile();
    my $dir  = $self->_lockdir();

	$self->log->debug(sprintf('lock: %s', $dir));

    retry {

        if (($dir->exists) && ($lock->exists)) {

            $stat = TRUE;

        } elsif ($dir->exists) {

            if ($stat = $self->_dead_lock()) {

                $self->_make_lock();
                $stat = TRUE;

            }

        } else {

            $self->_make_lock();
            $stat = TRUE;

        }

    } retry_if {

        my $ex = $_;
        my $exceptions = $self->exceptions;

        if (ref($ex) && $ex->isa('Badger::Exception')) {

            foreach my $exception (@$exceptions) {

                if ($ex->match_type($exception)) {

                    die $ex;

                }

            }

        }

        $self->exception_handler($ex);

        1;  # always retry

    } delay {

        my $attempts = shift;

        return if ($attempts > $self->attempts);
        sleep int(rand($self->timeout));

    } catch {

        my $ex = $_;
        my $msg = (ref($ex) eq 'Badger::Exception') ? $ex->info : $ex;

        $self->throw_msg(
            dotid($self->class) . '.lock',
            'lock_error',
            $dir, $msg
        );

    };

    return $stat;

}

sub unlock {
    my $self = shift;

    my $stat = FALSE;
    my $lock = $self->_lockfile();
    my $dir  = $self->_lockdir();

	$self->log->debug(sprintf('unlock: %s', $dir));

    try {

        $lock->delete if ($lock->exists);
        $dir->delete  if ($dir->exists);
        $stat = TRUE;

    } catch {

        my $ex = $_;
        my $msg = (ref($ex) eq 'Badger::Exception') ? $ex->info : $ex;

        $self->throw_msg(
            dotid($self->class) . '.unlock',
            'lock_error',
            $dir, $msg
        );

    };

    return $stat;

}

sub try_lock {
    my $self = shift;

    my $stat = TRUE;
    my $lock = $self->_lockfile();
    my $dir  = $self->_lockdir();

	$self->log->debug(sprintf('try_lock: %s', $dir));

    try {

        if ($dir->exists) {

    	    $self->log->warn_msg('lock_dir_error', $dir);
    	    $stat = $self->_dead_lock();

        }

    } catch {

        my $ex = $_;
        my $msg = (ref($ex) eq 'Badger::Exception') ? $ex->info : $ex;

        $self->throw_msg(
            dotid($self->class) . '.unlock',
            'lock_error',
            $dir, $msg
        );

    };
    
    return $stat

}

sub exceptions {
    my $self = shift;

    my $class = dotid($self->class);
    my @exceptions = [
        'filesystem',
        $class,
    ];

    return \@exceptions;

}

sub destroy {
    my $self = shift;

    my $lock = $self->_lockfile();
    my $dir  = $self->_lockdir();

    try {       # removes a potential warning during global destruction

        $lock->delete if ($lock->exists);
        $dir->delete  if ($dir->exists);

    };

    return 1;

}

sub DESTROY {
    my $self = shift;

    $self->destroy();

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _make_lock {
    my $self = shift;
    
    my $lock = $self->_lockfile();
    my $dir  = $self->_lockdir();

	$self->log->debug(sprintf('_make_lock: %s', $dir));

    # temporarily change the umask to create the 
    # directory and files with correct file permissions.
    # this is a noop on windows.

    my $omode = umask(0033);
    $dir->create;
    $lock->create;
    umask($omode);

}

sub _break_lock {
    my $self = shift;

    my $lock = $self->_lockfile();
    my $dir  = $self->_lockdir();

	$self->log->debug(sprintf('_break_lock: %s', $dir));

    if ($dir->exists) {

        foreach my $file (@{$dir->files}) {

            $file->delete if ($file->exists);

        }

        $dir->delete if ($dir->exists);

    }


}

sub _whose_lock {
    my $self = shift;

    my $pid  = undef;
    my $host = undef;
    my $time = undef;
    my $lock = $self->_lockfile();
    my $dir  = $self->_lockdir();

	$self->log->debug(sprintf('_whose_lock: %s', $dir));

    if ($dir->exists) {

        if (my @files = $dir->files) {

            # should only be one file in the directory,
            # but that file may disappear before this
            # check.

            if ($files[0]->exists) {

                $host = $files[0]->basename;
                $pid  = $files[0]->extension;
                $time = DateTime->from_epoch(
                    epoch     => ($files[0]->stat)[9], 
                    time_zone => 'local'
                );

            }

        }

    }

    return $host, $pid, $time;

}

sub _dead_lock {
    my $self = shift;

    my $stat = FALSE;
    my $lock = $self->_lockfile();
    my $dir  = $self->_lockdir();
    my $now  = DateTime->now(time_zone => 'local');
    my ($host, $pid, $time) = $self->_whose_lock();

	$self->log->debug(sprintf('_dead_lock: %s', $dir));

    my $break_lock = sub {

        # break the deadlock, irregardless of who owns the lock

        $self->_break_lock();
        $self->log->warn_msg('lock_broken', $dir);
        $stat = TRUE;

    };

    if (defined($host) && defined($pid) && defined($time)) {

        $time->set_time_zone('local');

        my $span = DateTime::Span->from_datetimes(
            start => $now->clone->subtract(seconds => $self->deadlock),
            end   => $now->clone,
        );

        $self->log->debug(sprintf('_dead_lock: host  - %s', $host));
        $self->log->debug(sprintf('_dead_lock: pid   - %s', $pid));
        $self->log->debug(sprintf('_dead_lock: start - %s', $span->start));
        $self->log->debug(sprintf('_dead_lock: lock  - %s', $time));
        $self->log->debug(sprintf('_dead_lock: end   - %s', $span->end));

        if ($span->contains($time)) {

            $self->log->debug('_dead_lock: within time span');

            if ($host eq $self->env->host) {

                if ($pid == $$) {

                    $self->log->debug('_dead_lock: our lock');
                    $stat = TRUE;

                } else {

                    my $status = $self->proc_status($pid, '_dead_lock');

                    unless (($status == 3) || ($status == 2)) {

                        $break_lock->();

                    }

                }

            } else {

                if ($self->breaklock) {

                    $break_lock->();

                } else {

                    $self->throw_msg(
                        dotid($self->class) . '.deadlock.remote',
                        'lock_remote',
                        $dir
                    );

                }

            }

        } else {

            $break_lock->();

        }

    } else {

        # unable to retrieve lock information, break the deadlock,
        # irregardless of who owns the lock

        $break_lock->();

    }

    return $stat;

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $lockfile = $self->env->host . ".$$";

    $self->{'_lockfile'} = File($self->key, $lockfile);
    $self->{'_lockdir'}  = Dir($self->_lockfile->volume, $self->_lockfile->directory);

    $self->{'deadlock'} = defined($self->args->{'deadlock'})
                            ? $self->args->{'deadlock'}
                            : 1800;
 
    $self->{'breaklock'} = defined($self->args->{'breaklock'})
                            ? $self->args->{'breaklock'}
                            : 0;

    $self->{'timeout'} = defined($self->args->{'timeout'})
                            ? $self->args->{'timeout'}
                            : 30;

    $self->{'attempts'} = defined($self->args->{'attempts'})
                            ? $self->args->{'attempts'}
                            : 30;

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Lockmgr::Filsystem - Use the file system for locking.

=head1 SYNOPSIS

 use XAS::Lib::Lockmgr;

 my $key = '/var/lock/wpm/alerts';
 my $lockmgr = XAS::Lib::Lockmgr->new();

 $lockmgr->add(
     -key    => $key,
     -driver => 'Filesystem',
     -args => {
        timeout   => 10,
        attempts  => 10,
        breaklock => 1,
        deadlock => 900,
     }
 );

 if ($lockmgr->try_lock($key)) {

     $lockmgr->lock($key);

     ...

     $lockmgr->unlock($key);

 }

=head1 DESCRIPTION

This class uses the manipulation of directories within the file system as a 
mutex. This leverages the atomicity of creating directories and allows for 
discretionary locking of resources.

=head1 CONFIGURATION

This module uses the following fields in -args.

=over 4

=item B<attempts>

The number of attempts to aquire the lock. The default is 30.

=item B<timeout>

The number of seconds to wait between lock attempts. The default is 30.

=item B<deadlock>

The number of seconds before a deadlock is declated, defaults to 1800,

=item B<breaklock>

Break the lock irregardless of how owns the lock, defaults to FALSE.

=back

=head1 METHODS

=head2 lock

Attempt to aquire a lock. This is done by creating a directory and writing
a status file into that directory. Returns TRUE for success, FALSE otherwise.

=head2 unlock

Remove the lock. This is done by removing the status file and then the 
directory. Returns TRUE for success, FALSE otherwise.

=head2 try_lock

Check to see if a lock could be aquired. Returns FALSE if the directory exists,
TRUE otherwise.

=head2 exceptions

Returns the exceptions that you may not want to continue lock attemtps if
triggered.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Lockmgr|XAS::Lib::Lockmgr>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
