package cPanel::StateFile::FileLocker;
$cPanel::StateFile::FileLocker::VERSION = '0.903';
#use warnings;
use strict;
use Fcntl ();

sub new {
    my ( $class, $args_hr ) = @_;
    $args_hr = {} unless defined $args_hr;
    die "Argument to new must be a hash reference.\n" unless 'HASH' eq ref $args_hr;
    die "Required logger argument is missing.\n"      unless exists $args_hr->{logger};
    my %args = (
        attempts      => 5,
        max_wait      => 300,    # five minutes
        max_age       => 300,    # five minutes
        flock_timeout => 60,
        sleep_secs    => 0.1,
        %{$args_hr},
    );
    $args{sleep_secs} = 0.05 if $args{sleep_secs} < 0.05;

    return bless \%args, $class;
}

sub file_lock {
    my ( $self, $filename ) = @_;
    my $attempts = $self->{attempts};
    my $lockfile = $filename . '.lock';
    $lockfile =~ tr/<>;&|//d;

    # wait up to the maximum time to hold a lock.
    my $deadline = time + $self->{max_wait};
  ATTEMPT:
    while ( $attempts-- > 0 ) {

        # Try to create a lockfile
        if ( sysopen( my $fh, $lockfile, &Fcntl::O_WRONLY | &Fcntl::O_EXCL | &Fcntl::O_CREAT ) ) {

            # success
            my $ex = _flock_timeout( $fh, &Fcntl::LOCK_EX, $self->{flock_timeout} );
            if ($ex) {
                close $fh;
                $self->_throw("Timeout writing lockfile '$lockfile'.");
            }

            print $fh $$, "\n", $0, "\n", ( time + $self->{max_wait} ), "\n";

            close $fh;
            return $lockfile;
        }

        while ( $deadline > time ) {
            my ( $pid, $name, $max_time ) = $self->_read_lock_file($lockfile);
            unless ($pid) {

                # couldn't read the file. If it doesn't exist, try to create.
                next ATTEMPT unless -e $lockfile;
                select( undef, undef, undef, $self->{sleep_secs} );
                next;
            }
            if ( time > $max_time ) {

                # The file says it is expired.
                my $expired = time - $max_time;
                $self->_info("Stale lock file '$lockfile': lock expired $expired seconds ago, removing...");
                unlink $lockfile;
                next ATTEMPT;
            }
            if ( $pid == $$ and $0 eq $name ) {
                $self->_throw("Attempting to relock '$filename'.");
            }
            elsif ( $pid == $$ ) {

                # Was locked by another process with this PID or $0 changed.
                $self->_warn("Inconsistent lock: my PID but process named '$name': removing lock");
                unlink $lockfile;
                next ATTEMPT;
            }
            elsif ( !_pid_alive( $lockfile, $pid ) ) {
                if ( -e $lockfile ) {
                    $self->_warn('Removing abandoned lock file.');
                    unlink $lockfile;
                }
                next ATTEMPT;
            }

            select( undef, undef, undef, $self->{sleep_secs} );
        }
    }

    $self->_throw("Failed to acquire lock for '$filename'.");
}

sub file_unlock {
    my ( $self, $lockfile ) = @_;

    $self->_throw('Missing lockfile name.') unless $lockfile;
    $lockfile =~ tr/<>;&|//d;
    unless ( -e $lockfile ) {
        $self->_warn("Lockfile '$lockfile' lost!");
        return;
    }
    my ( $pid, $name, $wait_time ) = $self->_read_lock_file($lockfile);
    unless ( defined $pid ) {
        $self->_warn("Lockfile '$lockfile' lost!");
        return;
    }

    if ( 0 == $pid ) {
        $self->_warn('Zero-length lockfile deleted.');
        return;
    }
    if ( $$ == $pid ) {
        unlink $lockfile;
        return;
    }
    else {
        $self->_throw("Attempt to unlock file '$lockfile' locked by another process '$pid'.");
    }

}

sub _throw {
    my $self = shift;
    $self->{logger}->throw(@_);
}

sub _warn {
    my $self = shift;
    return $self->{logger}->warn(@_);
}

sub _info {
    my $self = shift;
    return $self->{logger}->info(@_);
}

#
# Do flock call with a built in timeout.
#
# $fh - filehandle to flock
# $how - parameter for flock
# $when - timeout if it takes this many seconds.
#
# returns undef on success or "Timeout on flock\n" if it timed out.
sub _flock_timeout {
    my ( $fh, $how, $when ) = @_;

    # Try a non-blocking call first as
    # it will avoid two alarm syscalls
    # if possible.
    # If the nonblocking call does not
    # complete right away we fallback to
    # the full expensive
    # signal handler setup/alarm/flock/alarm call
    return undef if flock $fh, $how | Fcntl::LOCK_NB();

    my $orig_alarm;
    eval {
        local $SIG{'ALRM'} = sub { die "Timeout on flock\n"; };
        $orig_alarm = alarm $when;
        flock $fh, $how;
    };
    my $ex = $@;
    alarm $orig_alarm;
    return $ex;
}

# Read information out of a lock file.
# Attempts multiple times, locks file while reading, deals with files that vanish, etc.
# Returns:
#   (pid, name) from file if successful.
#   undef  if lock file vanished
#   (0, 0) if zero-length file and we deleted it.
sub _read_lock_file {
    my ( $self, $lockfile ) = @_;

    my $attempts = $self->{attempts};
    while ( $attempts-- > 0 ) {
        if ( open( my $fh, '<', $lockfile ) ) {
            my $ex = _flock_timeout( $fh, &Fcntl::LOCK_SH, $self->{flock_timeout} );
            $self->_throw("Timeout reading lockfile '$lockfile'.") if $ex;

            # Provide defaults in case we did not have 3 lines.
            my ( $pid, $name, $wait_time ) = ( <$fh>, '', '', '' );

            close $fh;
            unless ($pid) {    # retry, we got between open and lock (probably).
                select( undef, undef, undef, $self->{sleep_secs} );
                next;
            }

            chomp( $pid, $name, $wait_time );
            $self->_throw("Invalid lock file: '$pid' is not a PID.") if $pid =~ /\D/;
            $name      = '<unknown>' unless length $name;
            $wait_time = 0 if $wait_time =~ /\D/;
            return ( $pid, $name, $wait_time );
        }
        return unless -e $lockfile;    # file vanished, no longer locked.

        $self->_throw("Cannot open lock file '$lockfile' for reading.") unless -r _;
        select( undef, undef, undef, $self->{sleep_secs} );
    }

    my $lock_age = time - ( stat($lockfile) )[9];

    # not the same as max_timeout, really looking at 5 minutes as old.
    if ( -z $lockfile ) {
        if ( $lock_age > $self->{max_age} ) {

            # the file has existed for some time but still has nothing in it.
            # kill it.
            $self->_info('Old, but empty lock file deleted.');
            unlink $lockfile;
            return ( 0, 0, 0 );
        }
        return;
    }

    $self->_throw("Unable to read lockfile '$lockfile'");
}

#
# Test the supplied lock and pid to see if the process is still alive.
#
#  $lockfile - file lock we are testing.
#  $pid - expected owner of the lockfile.
#
# Return false is the process no longer exists, true if the process exists
#    or is we can not tell.
sub _pid_alive {
    my ( $lockfile, $pid ) = @_;

    # if we can use kill to check the pid, it is best choice.
    my $fileuid = ( stat($lockfile) )[4];
    if ( $> == 0 || $> == $fileuid ) {
        return 0 unless kill( 0, $pid ) or $!{EPERM};
    }

    # If the proc filesystem is available, it's a good test.
    return -r "/proc/$pid" if -e "/proc/$$" && -r "/proc/$$";

    # Default to alive, because we can't figure it out.
    return 1;
}

1;

__END__


=head1 NAME

cPanel::StateFile::FileLocker - Lock and unlock files using C<flock>.

=head1 SYNOPSIS

    use cPanel::StateFile::FileLocker;

=head1 DESCRIPTION

Provide the ability to lock and unlock a file. This class uses the C<flock>
system call to lock the file.

=head1 INTERFACE

=over 4

=item cPanel::StateFile::FileLocker->new()

Create a new C<FileLocker> object. The constructor takes an optional hash
reference that can be used to customize the behavior of the C<FileLocker>.

=over 4

=item attempts

The maximum number of times to try to create a lock file. This defaults to 5.

=item max_wait

Maximum number of seconds to wait for a lock file to be unlocked. The default
value is 300 (5 minutes).

=item max_age

Maximum number of seconds that a lock file can remain on disk. If a C<FileLocker>
finds a lock file older than this, it is assumed to be stale and is removed.
This value should be no less than the I<max_wait> value. The default value is
300 (5 minutes).

=item flock_timeout

Maximum number of seconds to wait for the C<flock> call to complete. This time
should be significantly less than the I<max_wait> value. The default value is
60 (1 minute).

=item sleep_secs

The number of seconds to sleep between attempts to check the lock file. Higher
numbers reduce CPU and disk load, but reduce responsiveness. The default value
is 0.1. The lowest allowed value is 0.05.

=back

=item $locker->file_lock( $filename )

Lock the file named $filename and return a lock object to be used to unlock
the file later.

=item $locker->file_unlock( $lock )

Unlock the file associated with the $lock.

=back

=head1 DIAGNOSTICS

=over

=item C<< Argument to new must be a hash reference. >>

The constructor was called with an argument that is not a hash reference.

=item C<< Attempt to unlock file '%s' locked by another process '%s'. >>

You attempted to unlock a file locked by someone else. There is no legitimate
reason to do this, so it must be a program error.

=item C<< Attempting to relock '%s'. >>

According to the lockfile, the current program already attempted to lock this
file, so the attempt to lock is terminated. This is likely caused by a
programming error trying to lock and already-locked file.

=item C<< Cannot open lock file '%s' for reading. >>

The lock file is not readable.

=item C<< Failed to acquire lock for '%s'. >>

We ran out of time before being able to acquire the lock. This is probably
caused by one or more other processes holding the lock for longer than we
were willing to wait.

=item C<< Inconsistent lock: my PID but process named '%s': removing lock >>

This warning describes a rare circumstance where the file was locked by a
another process with the same PID as the current program. There are two
ways this could occur:

=over 4

=item 1.

A previous program locked the file and then terminated without locking. We
happen to have the same PID as that program.

=item 2.

This program locked the file and then changed it's name.

=back

The lock is removed because in either case, we are waiting for a lock that
will never be released.

=item C<< Invalid lock file: '%s' is not a PID. >>

The lockfile does not have the expected contents. Are you sure a lockfile
name was supplied?

=item C<< Lockfile '%s' lost! >>

The lockfile name supplied to C<file_unlock> refers to a non-existent file.
Either someone deleted your lockfile, or the name you supplied is not valid.

=item C<< Missing lockfile name. >>

The C<file_unlock> method was called without the name of the lockfile to
unlock.

=item C<< Old, but empty lock file deleted. >>

Informational message that the lock file is empty, but older than the maximum
age expected. The file is discarded and we will try again.

=item C<< Removing abandoned lock file. >>

The program associated with this lock file is no longer running. The lockfile
is being removed.

=item C<< Stale lock file '%s': lock expired %s seconds ago, removing... >>

Informational message stating that the lock file was older than the locking
program expected. This probably means that either the locking program terminated
unexpectedly or is hung. C<FileLocker> is resolving this case by removing the
lock and continuing.

=item C<< Timeout reading lockfile '%s'. >>

When attempting to read the lock file, the file was C<flock>ed for more than
C<flock_timeout> seconds. This can be caused by another process access the
file and crashing.

=item C<< Timeout writing lockfile '%s'. >>

Although we were able to open the lockfile, we failed to lock it. This should
not happen in normal use unless someone C<flock>s the file we just opened and
leaves it C<flock>ed.

=item C<< Unable to create the lockfile, waiting >>

Informational message stating that this attempt to create a lock file was not
successful. After a short pause, the C<FileLocker> will try again.

=item C<< Unable to read lockfile '%s' >>

We failed to read the lock file, so the attempt to lock has been abandonded.

=item C<< Zero-length lockfile deleted. >>

The lockfile name supplied to C<file_unlock> refers to an empty file.
Either someone deleted your lockfile, or the name you supplied is not valid.

=back


=head1 CONFIGURATION AND ENVIRONMENT

cPanel::StateFile::FileLocker requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

G. Wade Johnson  C<< wade@cpanel.net >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, cPanel, Inc. All rights reserved.

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

