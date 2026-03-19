package Testcontainers::Container;
# ABSTRACT: A running Docker container managed by Testcontainers

use strict;
use warnings;
use Moo;
use Carp qw( croak );
use Log::Any qw( $log );

our $VERSION = '0.001';

=head1 SYNOPSIS

    # Containers are created via Testcontainers::run()
    my $container = Testcontainers::run('nginx:alpine',
        exposed_ports => ['80/tcp'],
    );

    # Get connection details
    my $host = $container->host;
    my $port = $container->mapped_port('80/tcp');
    my $id   = $container->id;

    # Execute commands
    my $result = $container->exec(['echo', 'hello']);
    say $result->{output};

    # Get logs
    my $logs = $container->logs;

    # Terminate
    $container->terminate;

=head1 DESCRIPTION

Represents a running Docker container created by Testcontainers. Provides
methods to interact with the container, get connection details, execute
commands, and manage its lifecycle.

=cut

has id => (
    is       => 'ro',
    required => 1,
);

=attr id

The Docker container ID.

=cut

has image => (
    is       => 'ro',
    required => 1,
);

=attr image

The Docker image name used to create this container.

=cut

has docker => (
    is       => 'ro',
    required => 1,
);

has request => (
    is       => 'ro',
    required => 1,
);

has _info => (
    is      => 'rw',
    default => sub { {} },
);

has _port_map => (
    is      => 'rw',
    default => sub { {} },
);

has _terminated => (
    is      => 'rw',
    default => 0,
);

sub refresh {
    my ($self) = @_;

    my $info = $self->docker->inspect_container($self->id);
    $self->_info($info);

    # Build port mapping from NetworkSettings
    my $ports = {};
    my $network_settings = $info->NetworkSettings;
    if ($network_settings && ref $network_settings eq 'HASH') {
        my $port_bindings = $network_settings->{Ports} // {};
        for my $container_port (keys %$port_bindings) {
            my $bindings = $port_bindings->{$container_port};
            if ($bindings && ref $bindings eq 'ARRAY' && @$bindings) {
                $ports->{$container_port} = {
                    host_ip   => $bindings->[0]{HostIp}   // '0.0.0.0',
                    host_port => $bindings->[0]{HostPort},
                };
            }
        }
    }
    $self->_port_map($ports);

    return $self;
}

=method refresh

Refresh container information from Docker. Called automatically after start.

=cut

sub host {
    my ($self) = @_;

    # In most cases, localhost is the right answer for testcontainers
    # For remote Docker, we'd need to parse the docker host
    my $docker_host = $self->docker->docker_host;

    if ($docker_host =~ m{^tcp://([^:]+)}) {
        return $1;
    }

    return 'localhost';
}

=method host

Returns the host address where the container is accessible. For local Docker,
returns C<localhost>. For remote Docker (tcp://), returns the remote host.

=cut

sub mapped_port {
    my ($self, $port) = @_;
    croak "Port required" unless $port;

    # Normalize port format: "80" -> "80/tcp"
    $port = "$port/tcp" unless $port =~ m{/};

    my $mapping = $self->_port_map->{$port};
    croak "No mapping found for port $port" unless $mapping;

    return $mapping->{host_port};
}

=method mapped_port($port)

Returns the host port mapped to the given container port.

    my $port = $container->mapped_port('80/tcp');
    # or
    my $port = $container->mapped_port('80');  # assumes /tcp

=cut

sub mapped_port_info {
    my ($self, $port) = @_;
    croak "Port required" unless $port;

    $port = "$port/tcp" unless $port =~ m{/};

    my $mapping = $self->_port_map->{$port};
    croak "No mapping found for port $port" unless $mapping;

    return $mapping;
}

=method mapped_port_info($port)

Returns a hashref with C<host_ip> and C<host_port> for the given container port.

=cut

sub endpoint {
    my ($self, $port) = @_;
    croak "Port required" unless $port;

    my $host = $self->host;
    my $mapped = $self->mapped_port($port);

    return "$host:$mapped";
}

=method endpoint($port)

Returns "host:port" string for the given container port.

    my $addr = $container->endpoint('80/tcp');
    # e.g., "localhost:32789"

=cut

sub container_id {
    my ($self) = @_;
    return $self->id;
}

=method container_id

Alias for C<id>. Returns the Docker container ID.

=cut

sub name {
    my ($self) = @_;
    my $name = $self->_info->Name // '';
    $name =~ s{^/}{};  # Docker prefixes names with /
    return $name;
}

=method name

Returns the container name (without leading /).

=cut

sub state {
    my ($self) = @_;
    $self->refresh;
    my $state = $self->_info->State;
    return $state if ref $state eq 'HASH';
    return { Status => $state };
}

=method state

Returns the container state hashref. Refresh container info first.

=cut

sub is_running {
    my ($self) = @_;
    my $state = $self->state;
    return $state->{Running} ? 1 : 0 if ref $state eq 'HASH' && exists $state->{Running};
    return lc($state->{Status} // '') eq 'running' ? 1 : 0;
}

=method is_running

Returns true if the container is currently running.

=cut

sub logs {
    my ($self, %opts) = @_;
    return $self->docker->container_logs($self->id, %opts);
}

=method logs(%opts)

Get container logs. Options: C<stdout>, C<stderr>, C<tail>, C<timestamps>.

=cut

sub exec {
    my ($self, $cmd, %opts) = @_;
    return $self->docker->exec_in_container($self->id, $cmd, %opts);
}

=method exec($cmd, %opts)

Execute a command in the container. C<$cmd> is an ArrayRef or string.
Returns hashref with C<exit_code> and C<output>.

    my $result = $container->exec(['echo', 'hello']);
    say $result->{output};      # "hello\n"
    say $result->{exit_code};   # 0

=cut

sub stop {
    my ($self, %opts) = @_;
    $self->docker->stop_container($self->id, %opts);
    return;
}

=method stop(%opts)

Stop the container. Options: C<timeout>.

=cut

sub start {
    my ($self) = @_;
    $self->docker->start_container($self->id);
    $self->refresh;
    return;
}

=method start

Start the container if it was stopped.

=cut

sub terminate {
    my ($self) = @_;
    return if $self->_terminated;

    $log->debugf("Terminating container: %s", $self->id);
    eval { $self->docker->stop_container($self->id, timeout => 5) };
    eval { $self->docker->remove_container($self->id, force => 1, volumes => 1) };
    $self->_terminated(1);

    $log->debugf("Container terminated: %s", $self->id);
    return 1;
}

=method terminate

Stop, remove the container and its volumes. Safe to call multiple times.

=cut

sub DEMOLISH {
    my ($self, $in_global_destruction) = @_;
    return if $in_global_destruction;
    # Auto-cleanup on object destruction if not already terminated
    $self->terminate unless $self->_terminated;
    return;
}

=head1 SEE ALSO

=over

=item * L<Testcontainers> - Main module

=item * L<Testcontainers::Wait> - Wait strategies

=back

=cut

1;
