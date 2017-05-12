package MMM::Daemon;

use strict;
use warnings;
use Sys::Syslog;
use MMM::Utils;
use MMM::Config;
use Fcntl qw(:flock);
use POSIX qw(:sys_wait_h);

use base qw(MMM);
use base qw(MMM::Report::Mail);

=head1 NAME

MMM::Daemon

=head1 SYNOPSIS

    use MMM::Daemon;
    my $mmm = MMM::Daemon->new() or die "Cannot find MMM installation";
    $mmm->run();

=head1 DESCRIPTION

A daemon for mmm system

=head1 METHODS

=cut

sub new {
    my ($class, @args) = @_;
    my $mmm = $class->SUPER::new(@args) or return;

    if (!$mmm->{nofork}) {
        Sys::Syslog::openlog('mmm', 'pid', $mmm->configval('default', 'syslog_facilities', 'daemon'));
        $mmm->{use_syslog} = 1;
    }

    $mmm
}

sub _create_pid_file {
    my ($self) = @_;
    if (my $pidf = $self->configval('default', 'pidfile', PIDFILE)) {
        if (open(my $h, '>>', $pidf)) {
            autoflush $h 1;
            if (flock($h, LOCK_EX | LOCK_NB)) {
                truncate($h, 0);
                print $h "$$\n";
                $self->{lockfh} = $h;
            } else {
                close($h);
                my $pid;
                if (open($h, '<', $pidf)) {
                    $pid = <$h> || '';
                    close($h);
                }
                chomp($pid);
                $self->log('WARNING', 'Another mmm seems running pid `%s\'',
                    $pid || 'N/A');
                return 0;
            }
            return 1;
        } else {
            $self->log('WARNING', 'Cannot create pid file `%s\' %s', $pidf, $!);
            return 0
        }
    } else {
        $self->log('WARNING', 'No pid file configured');
        return 0;
    }

    0
}

sub _delete_pid_file {
    my ($self) = @_;
    if ($self->{lockfh}) {
        close($self->{lockfh});
    }
    if (my $pidf = $self->configval('default', 'pidfile', PIDFILE)) {
        unlink($pidf) or $self->log('WARNING', 'Cannot delete pid file `%s\' %s', $pidf, $!);
    }
}

sub _reload_config {
    my ($self) = @_;
    my $config = Config::IniFiles->new(
        -file    => $self->{configfile},
        -default => 'default',
    );
    if ($config) {
        $self->{config} = $config;
        $self->_parse_config();
        $self->log('NOTICE', 'Configuration reload');
        return 1;
    } else {
        $self->log('ERROR', 'Failure will reloading configuration');
        return 0;
    }
}

sub run {
    my ($self) = @_;


    if (!$self->{nofork}) {
        $self->log('DEBUG', 'Going into background');
        my $pid = fork;
        if (!defined($pid)) {
            return;
        }

        if ($pid) {
            sleep 1;
            my $ret = waitpid($pid, &WNOHANG);
            if ($ret) {
                die "Daemon has stopped, check log (exit with $ret status)\n";
            }
            exit(0);
        }
    }

    $self->_create_pid_file() or return;

    $0 = 'mmm (DAEMON)';
    $self->log('NOTICE', 'MMM::Daemon started at pid %d', $$);
    $self->{dontdie} = 1;
    $SIG{'ALRM'} = sub { $self->{next_alarm} = 0; $self->_start_pending_queue() };
    $SIG{'TERM'} = sub { $self->{dontdie} = 0 };
    $SIG{'INT'} = sub {
        $self->log('INFO', 'Ctrl+C received, stoping');
        $self->{dontdie} = 0;
    };
    $SIG{'HUP'} = sub {
        alarm(0);
        $self->_reload_config;
        $self->{next_alarm} = 0;
        $self->_start_pending_queue();
    };
    $SIG{'CHLD'} = sub {
        $self->log('DEBUG', 'SIG CHILD received');
        $self->_reap_child();
    };
    $self->_start_pending_queue();
    while ($self->{dontdie}) {
        $self->_reap_child();
        $self->log('DEBUG', 'next alarm in %ss', ($self->{next_alarm} ? $self->{next_alarm} - scalar(time): 'N/A'));
        sleep(3600) if ($self->{dontdie});
    }
    foreach (keys %{ $self->{process} || {} }) {
        kill 15, $_;
    }
    $self->_delete_pid_file();
    1;
}

sub post_process {
    my ($self, $job) = @_;
    $self->log('DEBUG', 'Post process %s', $job->name);
    $self->_start_pending_queue();
}

sub _set_alarm {
    my ($self, $when) = @_;
    ($self->{next_alarm} || 0) != 0 && $when >= $self->{next_alarm}  and return;
    $self->log('DEBUG', 'Re-Alarm for %d, in %ds', $when, $when - scalar(time));
    $self->{next_alarm} = $when;
    my $s_alarm = $when - scalar(time);
    alarm($s_alarm > 0 ? $s_alarm : 1);
}

sub _start_pending_queue {
    my ($self) = @_;
    $self->{dontdie} or return;
    my $waitdelay = 0;
    foreach my $job ($self->get_tasks_by_name($self->list_tasks)) {
        $job->is_disable and next;
        $job->frequency or next;
        my $next_run_time = $job->next_run_time;
        if ($next_run_time <= scalar(time)) {
            $self->_run_fork($job, 'NOTRAPLOG');
            sleep(5) if($waitdelay); # small wait to avoid excessive load
            $waitdelay = 1;
        } else {
            $self->log('DEBUG', '$when < 0: %d %s', $next_run_time, $job->name) if ($next_run_time <= 0);
            $self->_set_alarm($next_run_time);
        }
    }
}

1;

__END__

=head1 SEE ALSO

L<MMM>

=head1 AUTHOR

Olivier Thauvin <nanardon@nanardon.zarb.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Olivier Thauvin

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

=cut

