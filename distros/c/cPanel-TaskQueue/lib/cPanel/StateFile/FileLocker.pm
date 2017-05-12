package cPanel::StateFile::FileLocker;
$cPanel::StateFile::FileLocker::VERSION = '0.800';
# cpanel - cPanel/StateFile/FileLocker.pm         Copyright(c) 2014 cPanel, Inc.
#                                                           All rights Reserved.
# copyright@cpanel.net                                         http://cpanel.net
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the owner nor the names of its contributors may
#       be used to endorse or promote products derived from this software
#       without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL  BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#use warnings;
use strict;
use Fcntl ();

sub new {
    my ( $class, $args_hr ) = @_;
    $args_hr = {} unless defined $args_hr;
    die "Argument to new must be a hash reference.\n" unless 'HASH' eq ref $args_hr;
    die "Required logger argument is missing.\n" unless exists $args_hr->{logger};
    my %args = (
        attempts      => 5,
        max_wait      => 300,    # five minutes
        max_age       => 300,    # five minutes
        flock_timeout => 60,
        sleep_secs    => 1,
        %{$args_hr},
    );
    $args{sleep_secs} = 1 if $args{sleep_secs} < 1;

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
                sleep $self->{sleep_secs};
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

            sleep $self->{sleep_secs};
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
                sleep $self->{sleep_secs};
                next;
            }

            chomp( $pid, $name, $wait_time );
            $self->_throw("Invalid lock file: '$pid' is not a PID.") if $pid =~ /\D/;
            $name = '<unknown>' unless length $name;
            $wait_time = 0 if $wait_time =~ /\D/;
            return ( $pid, $name, $wait_time );
        }
        return unless -e $lockfile;    # file vanished, no longer locked.

        $self->_throw("Cannot open lock file '$lockfile' for reading.") unless -r _;
        sleep $self->{sleep_secs};
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

Copyright (c) 2010, cPanel, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

