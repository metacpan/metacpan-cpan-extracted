package Testcontainers::ContainerRequest;
# ABSTRACT: Container configuration request

use strict;
use warnings;
use Moo;
use Carp qw( croak );
use Testcontainers::Labels qw(
    default_labels merge_custom_labels
);

our $VERSION = '0.001';

=head1 DESCRIPTION

Represents the configuration for creating a Docker container, similar to
Go's C<testcontainers.ContainerRequest>. Built internally by L<Testcontainers::run()>
from the options passed to it.

=cut

has image => (
    is       => 'ro',
    required => 1,
);

has exposed_ports => (
    is      => 'ro',
    default => sub { [] },
);

has env => (
    is      => 'ro',
    default => sub { {} },
);

has labels => (
    is      => 'ro',
    default => sub { {} },
);

has _internal_labels => (
    is      => 'ro',
    default => sub { {} },
);

has cmd => (
    is      => 'ro',
    default => sub { [] },
);

has entrypoint => (
    is      => 'ro',
    default => sub { [] },
);

has name => (
    is      => 'ro',
    default => undef,
);

has session_id => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Testcontainers::Labels::session_id() },
);

has wait_for => (
    is      => 'ro',
    default => undef,
);

has tmpfs => (
    is      => 'ro',
    default => sub { {} },
);

has startup_timeout => (
    is      => 'ro',
    default => 60,
);

has privileged => (
    is      => 'ro',
    default => 0,
);

has network_mode => (
    is      => 'ro',
    default => undef,
);

has networks => (
    is      => 'ro',
    default => sub { [] },
);

sub to_docker_config {
    my ($self) = @_;

    my $config = {
        Image => $self->image,
    };

    # Exposed ports (Docker API format: { "80/tcp": {} })
    if (@{$self->exposed_ports}) {
        my %exposed;
        for my $port (@{$self->exposed_ports}) {
            my $normalized = $port =~ m{/} ? $port : "$port/tcp";
            $exposed{$normalized} = {};
        }
        $config->{ExposedPorts} = \%exposed;
    }

    # Environment variables
    if (%{$self->env}) {
        $config->{Env} = [ map { "$_=$self->{env}{$_}" } sort keys %{$self->env} ];
    }

    # Labels — merge standard Testcontainers labels with user-supplied ones.
    # User labels starting with 'org.testcontainers' are rejected.
    # Internal (framework) labels bypass the prefix check.
    my %defaults = default_labels($self->session_id);
    my %merged   = merge_custom_labels(\%defaults, $self->labels);
    # Layer in framework-internal labels (e.g. org.testcontainers.module)
    for my $k (keys %{$self->_internal_labels}) {
        $merged{$k} = $self->_internal_labels->{$k};
    }
    $config->{Labels} = \%merged;

    # Command
    if (@{$self->cmd}) {
        $config->{Cmd} = $self->cmd;
    }

    # Entrypoint
    if (@{$self->entrypoint}) {
        $config->{Entrypoint} = $self->entrypoint;
    }

    # HostConfig
    my $host_config = {};

    # Port bindings - publish all exposed ports
    if (@{$self->exposed_ports}) {
        my %port_bindings;
        for my $port (@{$self->exposed_ports}) {
            my $normalized = $port =~ m{/} ? $port : "$port/tcp";
            $port_bindings{$normalized} = [{ HostIp => '', HostPort => '' }];
        }
        $host_config->{PortBindings} = \%port_bindings;
        $host_config->{PublishAllPorts} = \1;
    }

    # Tmpfs mounts
    if (%{$self->tmpfs}) {
        $host_config->{Tmpfs} = $self->tmpfs;
    }

    # Privileged mode
    if ($self->privileged) {
        $host_config->{Privileged} = \1;
    }

    # Network mode
    if ($self->network_mode) {
        $host_config->{NetworkMode} = $self->network_mode;
    }

    $config->{HostConfig} = $host_config;

    # NetworkingConfig for named networks
    if (@{$self->networks}) {
        my %endpoints;
        for my $net (@{$self->networks}) {
            $endpoints{$net} = {};
        }
        $config->{NetworkingConfig} = {
            EndpointsConfig => \%endpoints,
        };
    }

    return $config;
}

=method to_docker_config

Converts the request into a Docker API compatible configuration hashref
suitable for container creation.

=cut

1;
