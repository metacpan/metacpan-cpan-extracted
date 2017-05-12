use strict;
use warnings;
package Ubic::Service::ServerStarter;
$Ubic::Service::ServerStarter::VERSION = '0.003';
use base qw(Ubic::Service::Skeleton);

use Params::Validate qw(:all);

use Ubic::Daemon qw(:all);

# ABSTRACT: Run programs using Server::Starter

my $server_command = $ENV{'UBIC_SERVICE_SERVERSTARTER_BIN'} || 'start_server';

sub new {
    my ($class) = (shift);

    my $params = validate(@_, {
        cmd         => { type => ARRAYREF },
        args        => { type => HASHREF, optional => 1 },
        user        => { type => SCALAR, optional => 1 },
        group       => { type => SCALAR | ARRAYREF, optional => 1 },
        status      => { type => CODEREF, optional => 1 },
        ubic_log    => { type => SCALAR, optional => 1 },
        env         => { type => HASHREF, optional => 1 },
        stdout      => { type => SCALAR, optional => 1 },
        stderr      => { type => SCALAR, optional => 1 },
        proxy_logs  => { type => BOOLEAN, optional => 1 },
        pidfile     => { type => SCALAR, optional => 1 },
        cwd         => { type => SCALAR, optional => 1 },
    });

    return bless $params => $class;
}

sub pidfile {
    my ($self) = @_;
    return $self->{pidfile} if defined $self->{pidfile};
    return "/tmp/".$self->full_name.".pid";
}

sub sspidfile {
    my ($self) = @_;
    return $self->{args}{'pid-file'} || $self->pidfile . '.ss';
}

sub statusfile {
    my ($self) = @_;
    return $self->{args}{'status-file'} || $self->pidfile . '.status.ss';
}

sub bin {
    my ($self) = @_;

    my @cmd = split(/\s+/, $server_command);

    my %args = %{ $self->{args} };
    $args{'pid-file'} = $self->sspidfile unless $args{'pid-file'};
    $args{'status-file'} = $self->statusfile unless $args{'status-file'};

    for my $key (keys %args) {
        my $cmd_key = (length $key == 1) ? '-' : '--';
        $cmd_key .= $key;
        my $v = $args{$key};
        next unless defined $v;
        push @cmd, $cmd_key, $v;
    }
    push @cmd, '--', @{ $self->{cmd} };

    return \@cmd;
}

sub start_impl {
    my ($self) = @_;

    my $daemon_opts = {
        bin => $self->bin,
        pidfile => $self->pidfile,
        term_timeout => 5, # TODO - configurable?
    };
    for (qw/ env cwd stdout stderr ubic_log /, ($Ubic::Daemon::VERSION gt '1.48' ? 'proxy_logs' : ())) {
        $daemon_opts->{$_} = $self->{$_} if defined $self->{$_};
    }
    start_daemon($daemon_opts);
    return;
}

sub stop_impl {
    my ($self) = @_;
    return stop_daemon($self->pidfile, { timeout => 7 });
}

sub status_impl {
    my ($self) = @_;
    my $running = check_daemon($self->pidfile);
    return 'not running' unless ($running);
    if ($self->{status}) {
        return $self->{status}->();
    } else {
        return 'running';
    }
}

sub reload {
    my ($self) = @_;
    my $reval = system $server_command, '--restart',
        '--pid-file', $self->sspidfile,
        '--status-file', $self->statusfile;

    return 'reloaded' if $reval == 0;
    die 'failed to reload!';
}

sub user {
    my $self = shift;
    return $self->{user} if defined $self->{user};
    return $self->SUPER::user;
};

sub group {
    my $self = shift;
    my $groups = $self->{group};
    return $self->SUPER::group() if not defined $groups;
    return @$groups if ref $groups eq 'ARRAY';
    return $groups;
}

sub timeout_options {
    # TODO - make them customizable
    return {
        start => { trials => 15, step => 0.1 },
        stop => { trials => 15, step => 0.1 },
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Service::ServerStarter - Run programs using Server::Starter

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Ubic::Service::ServerStarter;
    return Ubic::Service::ServerStarter->new({
        cmd => [
            'starman',
            '--preload-app',
            '--env' => 'development',
            '--workers' => 5,
        ],
        args => {
            interval => 5,
            port => 5003,
            signal-on-hup => 'QUIT',
            signal-on-term => 'QUIT',
        },
        ubic_log => '/var/log/app/ubic.log',
        stdout   => '/var/log/app/stdout.log',
        stderr   => '/var/log/app/stderr.log',
        user     => "www-data",
    });

=head1 DESCRIPTION

This service allows you to wrap any command with L<Server::Starter>, which
enables graceful reloading of that app without any downtime.

=head1 NAME

Ubic::Service::ServerStarter - ubic service class for running commands
with L<Server::Starter>

=head1 METHODS

=over

=item I<args> (optional)

Arguments to send to C<start_server>.

=item I<cmd> (required)

ArrayRef of command + options to run with server starter.  Everything passed
here will go be put after the C<--> in the C<start_server> command:

    start_server [ args ] -- [ cmd ]

This argument is required becasue we have to have something to run!

=item I<status>

Coderef to special function, that will check status of your application.

=item I<ubic_log>

Path to ubic log.

=item I<stdout>

Path to stdout log.

=item I<stderr>

Path to stderr log.

=item I<proxy_logs>

Boolean flag. If enabled, C<ubic-guardian> will replace daemon's stdout and
stderr filehandles with pipes, proxy all data to the log files, and reopen
them on C<SIGHUP>.

=item I<user>

User under which C<start_server> will be started.

=item I<group>

Group under which C<start_server> will be started. Default is all user groups.

=item I<cwd>

Change working directory before starting a daemon.

=item I<pidfile>

Pidfile for C<Ubic::Daemon> module.

=head1 AUTHOR

William Wolf <throughnothing@gmail.com>

=head1 COPYRIGHT AND LICENSE


William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
