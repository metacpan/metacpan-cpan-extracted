package MMM;

use strict;
use warnings;
use MMM::Host;
use MMM::MirrorTask;
use MMM::Config;
use Config::IniFiles;
use POSIX qw(:sys_wait_h);
use IO::Select;
use Sys::Hostname  ();
use Sys::Syslog    ();

our $VERSION = '0.43';

=head1 NAME

MMM - MMM Mirror Manager

=head1 METHODS

=head2 new( %options )

Create a new MMM object. %options can provide:

=over 4

=item configfile

The configuration file to use (default is 'mmm.cfg')

=item mirror_dir

The location of locales lists (default is '.')

=item loghandle

A ref to an handle where to write message

=item verbosity

The verbosity level (default is 3)

=back

=cut

sub new {
    my ( $class, %options ) = @_;
    my $mmm = {
        configfile => $options{configfile} || CONFIGFILE,
        mirrordir => $options{mirrordir} || MIRRORDIR,
        logcallback => $options{logcallback},
        nofork => $options{nofork},
        dryrun => $options{dryrun},
        verbosity => VERBOSITY, # default is enough at this step
        runtime_verbosity => $options{verbosity},
    };
    $mmm->{config} = Config::IniFiles->new(
        -file    => $mmm->{configfile},
        -default => 'default',
    ) or return;
    bless( $mmm, $class );

    $mmm->_parse_config() or return;
    my ($res, $message) = MMM::Utils::setid(
        $mmm->{config}->val('default', 'user'),
        $mmm->{config}->val('default', 'group')
    );
    if (!$res) {
        $mmm->log('ERROR', $message);
    }

    $mmm
}

sub _parse_config {
    my ($self) = @_;
    
    $self->{statedir} = $self->{config}->val( 'default', 'statedir', STATEDIR );

    $self->{hostinfo} = MMM::Host->new(
        hostname => $self->{config}->val( 'default', 'hostname' )
          || Sys::Hostname::hostname(),
        latitude  => $self->{config}->val( 'default', 'latitude' ),
        longitude => $self->{config}->val( 'default', 'longitude' ),
    );

    $self->set_verbosity(
        defined( $self->{runtime_verbosity} ) 
            ? $self->{runtime_verbosity}
            : $self->{config}->val('default', 'verbosity', VERBOSITY)
    );

    1;
}

=head2 statedir

Return the state directory

=cut

sub statedir {
    my ($self) = @_;
    return $self->{config}->val( 'default', 'statedir', $self->{statedir} );
}

=head2 set_log_callback( $callback )

Set the callback where message are written

=cut

sub set_log_callback {
    my ( $self, $callback ) = @_;
    $self->{logcallback} = $callback;
}

our $loglevel = {
    'PIPE'    => [ -1, '', '' ], # internal use only
    'FATAL'   => [ 0, 'Fatal: ', 'crit' ],
    'ERROR'   => [ 1, 'Error: ', 'err' ],
    'WARNING' => [ 2, 'Warning: ', 'warning' ],
    'NOTICE'  => [ 3, '', 'notice' ],
    'INFO'    => [ 4, '', 'info' ],
    'DEBUG'   => [ 5, 'Debug: ', 'debug' ],
};

=head2 log( $level, $message, @args )

Log a message. $level is one of

    LEVEL
    FATAL
    ERROR
    WARNING
    NOTICE
    INFO
    DEBUG

=cut

sub log {
    my ( $self, $level, $message, @args ) = @_;
    $message or return;
    my ($keylogl) =
      $level =~ /^\d$/
      ? ( grep { $loglevel->{$_}[0] == $level } keys %{$loglevel} )
      : ( uc($level) );
    $loglevel->{$keylogl} or $keylogl = 'NOTICE';
    if ($loglevel->{$keylogl}[0] == -1) { # PIPE
        my ($levelb, $messageb) = $message =~ /^(\w+) (.*)/;
        return $self->log($levelb, $messageb, @args);
    }
    $loglevel->{$keylogl}[0] > $self->{verbosity} and return;
    if ( $self->{logcallback} && ref $self->{logcallback} eq 'CODE' ) {
        $self->{logcallback}
          ->( $level, $message, @args );
    }
    else {
        my $h = $loglevel->{$keylogl}[0] > 2 ? \*STDOUT : \*STDERR;
        if ($self->{use_syslog}) {
            Sys::Syslog::syslog($loglevel->{$keylogl}[2], $message, @args);
        } else {
            printf $h $self->fmt_log($level, $message, @args) . "\n";
        }
    }
}

=head2 fmt_log($level, $message, @args)

Format a log message and return it

=cut

sub fmt_log {
    my ( $self, $level, $message, @args ) = @_;
    $message or return;
    my ($keylogl) =
      $level =~ /^\d$/
      ? ( grep { $loglevel->{$_}[0] == $level } keys %{$loglevel} )
      : ( uc($level) );
    $loglevel->{$keylogl} or $keylogl = 'NOTICE';
    $loglevel->{$keylogl}[0] > $self->{verbosity} and return;
    sprintf( "$loglevel->{$keylogl}[1]$message", @args );
}

=head2 set_verbosity($verbosity)

Set the verbosity

=cut

sub set_verbosity {
    my ($self, $verbosity) = @_;
    if (exists($loglevel->{uc($verbosity)})) {
        $self->{verbosity} = $loglevel->{uc($verbosity)}[0];
    } elsif ($verbosity =~ /^\d+$/) {
        $self->{verbosity} = $verbosity;
    } else {
        $self->log('ERROR', 'Invalid verbosity level %s', $verbosity);
    }
}

=head2 hostname

Return the hostname setup in the configuration

=cut

sub hostname {
    my ($self) = @_;
    $self->{hostinfo}->hostname;
}

=head2 hostinfo

Return the MMM::Host which identify the host where the process is running

=cut

sub hostinfo {
    $_[0]->{hostinfo};
}

=head2 configval($section, $var, $default)

Return a value from configuation

=cut

sub configval {
    my ( $self, $section, $var, $default ) = @_;
    $self->{config}->val( $section, $var, $default );
}

=head2 list_tasks

Return the list of setup task

=cut

sub list_tasks {
    my ($self) = @_;
    return grep { $_ ne 'default' } $self->{config}->Sections;
}

=head2 get_tasks_by_name(@tasks_name)

Return a MMM::MirrorTask object for the each @tasks_name

=cut

sub get_tasks_by_name {
    my ($self, @jobs_name) = @_;
    $self->{config} or return;
    my @res = ();
    foreach my $job ( @jobs_name ) {
        $job eq 'default' and next;
        if (!$self->{config}->SectionExists($job)) {
            $self->log('WARNING', 'Job `%s\' don\'t exists, Ignoring...', $job);
            next;
        }
        push(@res,
            MMM::MirrorTask->new(
                $self,
                $job,
                dryrun => $self->{dryrun},
            )
        );
    }
    grep { $_ } @res;
}

sub _get_geo {
    my ($self, $ml) = @_;
    $self->log('DEBUG', 'Fetching geo loc data From %s %s %s', caller);
    my %src;
    foreach ($self->get_tasks_by_name($self->list_tasks)) {
        $_->is_disable and next;
        if ($_->val('url')) {
            if (my $mi = MMM::Mirror->new(url => $_->val('url'))) {
                $mi->get_geo();
                $ml->add_mirror($mi);
            }
        } else {
            $_->source or next;
            $src{$_->source} = 1;
        }
    }
    $ml->get_geo([ keys %src ]);
    if (open(my $h, '>', $self->statedir . '/hosts.xml')) {
        print $h $ml->xml_hosts;
        close($h);
    }
}

=head2 run

Process all load rsync job

=cut

sub run {
    my ( $self, @job_names ) = @_;

    foreach my $q (grep { (!$_->is_disable) }
        $self->get_tasks_by_name(@job_names)
        ) {
        $self->_run_fork($q);
    }

    $self->_reap_message();
    $self->_reap_child();

}

=head2 post_process

function called at the end of process

=cut

sub post_process {
    my ($self, $job) = @_;
    $self->log('DEBUG', 'Post processing %s', $job->name);
}

sub _reap_child {
    my ($self) = @_;
    my $kid = 0;
    do {
        $kid = waitpid( -1, &WNOHANG );
        if ($kid > 0) {
            $self->log('DEBUG', 'Reaping pid %d', $kid);
            if ($self->{process}{$kid}) {
                $self->log('DEBUG', 'Successive failure %s was: %d is: %d changed: %d',
                    $self->{process}{$kid}->name,
                    map { defined($_) ? $_ : '-1' } $self->{process}{$kid}->failure_count()
                );
                $self->post_process($self->{process}{$kid});
            } else {
                $self->log('WARNING',
                    "I have no trace of subprocess pid %d, please report",
                    $kid
                );
            }
        }
        delete($self->{process}{$kid});
    } until $kid <= 0;
}

sub _reap_message {
    my ($self) = @_;
    $self->{ios} or return;
    while (my @hs = $self->{ios}->can_read() ) {
        foreach my $h (@hs) {
            my $l = <$h>;
            if ( !defined($l) ) {
                $self->{ios}->remove($h);
                next;
            }
            chomp($l);
            $self->log( 'PIPE', $l );
        }
    }
}

sub _task_is_registred {
    my ($self, $taskname) = @_;
    if (my ($pid) = grep { $self->{process}{$_}->name eq $taskname }
        (keys %{ $self->{process} || {} })) {
        return $pid;
    } else {
        return;
    }
}

sub _run_fork {
    my ($self, $process, $notraplog) = @_;
    if (my $pid = $self->_task_is_registred($process->name)) {
        $self->log('DEBUG', '%s is already running ! (pid %d)', $process->name, $pid);
        return;
    }
    $self->log('DEBUG', 'Forking to run %s', $process->name);
    my ($reader, $writer );
    if (!$notraplog) {
        pipe($reader, $writer );
    }
    my $oldInt = $SIG{'INT'};
    $SIG{'INT'} = 'IGNORE';
    my $pid = fork();
    defined($pid) or die("Can't fork");
    if ($pid) {
        $self->log('DEBUG', 'PID %d for %s started', $pid, $process->name);
        $self->{process}{$pid} = $process;
        if (!$notraplog) {
            $self->{ios} ||= IO::Select->new();
            $self->{ios}->add($reader);
            # keep a trac of this process
        }
        $SIG{'INT'} = $oldInt if (defined($oldInt));
    } else {
        $SIG{'CHLD'} = 'DEFAULT';
        $self->set_verbosity(
            $self->configval($process->name, 'verbosity', $self->{verbosity})
        );
        foreach (qw(ALRM TERM INT HUP CHLD)) {
            $SIG{$_} = 'DEFAULT';
        }
        $self->set_log_callback(
            sub {
                my ($level, $message, @args ) = @_;
                print $writer "$level " . sprintf($message, @args) . "\n";
            }
        ) unless($notraplog);
        exit(!$process->sync());
    }
}

=head2 check_config

Check the config

=cut

sub check_config {
    my ($self) = @_;
    my $res = 1;

    if (! -d $self->statedir) {
        $self->log('FATAL', qq{Statedir `%s' don't exists}, $self->statedir);
        $res = 0;
    }

    $res
}

1;

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

