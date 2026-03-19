package Testcontainers::DockerClient;
# ABSTRACT: Docker client wrapper using WWW::Docker

use strict;
use warnings;
use Moo;
use Carp qw( croak );
use Log::Any qw( $log );
use WWW::Docker;

our $VERSION = '0.001';

=head1 DESCRIPTION

Internal wrapper around L<WWW::Docker> that provides a simplified interface
for Testcontainers operations. This module handles Docker daemon communication
for container lifecycle management, image operations, and container inspection.

=cut

has docker_host => (
    is      => 'ro',
    default => sub { $ENV{DOCKER_HOST} // 'unix:///var/run/docker.sock' },
);

has _client => (
    is      => 'lazy',
    builder => sub {
        my ($self) = @_;
        WWW::Docker->new(
            host => $self->docker_host,
        );
    },
);

sub pull_image {
    my ($self, $image) = @_;
    croak "Image name required" unless $image;

    my ($name, $tag) = _parse_image($image);
    $log->debugf("Pulling image: %s:%s", $name, $tag);

    eval {
        $self->_client->images->pull(fromImage => $name, tag => $tag);
    };
    if ($@) {
        $log->warnf("Failed to pull image %s:%s: %s", $name, $tag, $@);
        # Don't die - image may already exist locally
    }
    return;
}

=method pull_image($image)

Pull a Docker image. Parses image name and tag from the full image string.
Does not die on failure (image may already exist locally).

=cut

sub create_container {
    my ($self, $config, $name) = @_;
    croak "Container config required" unless $config;

    $config->{name} = $name if defined $name;

    $log->debugf("Creating container with image: %s", $config->{Image});
    my $result = $self->_client->containers->create(%$config);
    croak "Failed to create container" unless $result && $result->{Id};

    return $result;
}

=method create_container($config, $name)

Create a Docker container from configuration hash. Returns hashref with C<Id>.

=cut

sub start_container {
    my ($self, $id) = @_;
    croak "Container ID required" unless $id;

    $log->debugf("Starting container: %s", $id);
    $self->_client->containers->start($id);
    return;
}

=method start_container($id)

Start a container by ID.

=cut

sub stop_container {
    my ($self, $id, %opts) = @_;
    croak "Container ID required" unless $id;

    my $timeout = $opts{timeout} // 10;
    $log->debugf("Stopping container: %s (timeout: %d)", $id, $timeout);
    eval { $self->_client->containers->stop($id, timeout => $timeout) };
    if ($@) {
        $log->warnf("Error stopping container %s: %s", $id, $@);
    }
    return;
}

=method stop_container($id, %opts)

Stop a container. Options: C<timeout> (default 10 seconds).

=cut

sub remove_container {
    my ($self, $id, %opts) = @_;
    croak "Container ID required" unless $id;

    $log->debugf("Removing container: %s", $id);
    eval {
        $self->_client->containers->remove($id,
            force   => $opts{force} // 1,
            volumes => $opts{volumes} // 1,
        );
    };
    if ($@) {
        $log->warnf("Error removing container %s: %s", $id, $@);
    }
    return;
}

=method remove_container($id, %opts)

Remove a container. Options: C<force> (default true), C<volumes> (default true).

=cut

sub inspect_container {
    my ($self, $id) = @_;
    croak "Container ID required" unless $id;

    my $info = $self->_client->containers->inspect($id);
    return $info;
}

=method inspect_container($id)

Inspect container details. Returns L<WWW::Docker::Container> object.

=cut

sub container_logs {
    my ($self, $id, %opts) = @_;
    croak "Container ID required" unless $id;

    return $self->_client->containers->logs($id,
        stdout     => $opts{stdout} // 1,
        stderr     => $opts{stderr} // 1,
        tail       => $opts{tail}   // 'all',
        timestamps => $opts{timestamps} // 0,
    );
}

=method container_logs($id, %opts)

Get container logs. Options: C<stdout>, C<stderr>, C<tail>, C<timestamps>.

=cut

sub exec_in_container {
    my ($self, $id, $cmd, %opts) = @_;
    croak "Container ID required" unless $id;
    croak "Command required" unless $cmd;

    my @cmd = ref $cmd eq 'ARRAY' ? @$cmd : ($cmd);

    my $exec = $self->_client->exec->create($id,
        Cmd          => \@cmd,
        AttachStdout => \1,
        AttachStderr => \1,
        Tty          => $opts{tty} ? \1 : \0,
    );

    my $output = $self->_client->exec->start($exec->{Id});
    my $info   = $self->_client->exec->inspect($exec->{Id});

    return {
        exit_code => $info->{ExitCode} // -1,
        output    => $output // '',
    };
}

=method exec_in_container($id, $cmd, %opts)

Execute a command inside a running container. Returns hashref with
C<exit_code> and C<output>.

=cut

sub _parse_image {
    my ($image) = @_;

    # Handle images with registry prefix (e.g., docker.io/library/nginx:latest)
    my $tag = 'latest';
    if ($image =~ m{^(.+):([^:/]+)$}) {
        return ($1, $2);
    }
    return ($image, $tag);
}

1;
