package WWW::Docker::API::Exec;
# ABSTRACT: Docker Engine Exec API

use Moo;
use Carp qw( croak );
use namespace::clean;

our $VERSION = '0.101';

=head1 SYNOPSIS

    my $docker = WWW::Docker->new;

    # Create an exec instance
    my $exec = $docker->exec->create($container_id,
        Cmd         => ['/bin/sh', '-c', 'echo hello'],
        AttachStdout => 1,
        AttachStderr => 1,
    );

    # Start the exec
    $docker->exec->start($exec->{Id});

    # Inspect exec instance
    my $info = $docker->exec->inspect($exec->{Id});

=head1 DESCRIPTION

This module provides methods for executing commands inside running containers
using the Docker Exec API.

Accessed via C<< $docker->exec >>.

=cut

has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);

=attr client

Reference to L<WWW::Docker> client. Weak reference to avoid circular dependencies.

=cut

sub create {
  my ($self, $container_id, %config) = @_;
  croak "Container ID required" unless $container_id;
  croak "Cmd required" unless $config{Cmd};
  return $self->client->post("/containers/$container_id/exec", \%config);
}

=method create

    my $exec = $docker->exec->create($container_id,
        Cmd          => ['/bin/sh', '-c', 'echo hello'],
        AttachStdout => 1,
        AttachStderr => 1,
        Tty          => 0,
    );

Create an exec instance. Returns hashref with C<Id>.

Required config: C<Cmd> (ArrayRef of command and arguments).

Common config keys: C<AttachStdin>, C<AttachStdout>, C<AttachStderr>, C<Tty>,
C<Env>, C<User>, C<WorkingDir>.

=cut

sub start {
  my ($self, $exec_id, %opts) = @_;
  croak "Exec ID required" unless $exec_id;
  my $body = {
    Detach => $opts{Detach} ? \1 : \0,
    Tty    => $opts{Tty}    ? \1 : \0,
  };
  return $self->client->post("/exec/$exec_id/start", $body);
}

=method start

    $exec->start($exec_id, Detach => 0);

Start an exec instance. Options: C<Detach>, C<Tty>.

=cut

sub resize {
  my ($self, $exec_id, %opts) = @_;
  croak "Exec ID required" unless $exec_id;
  my %params;
  $params{h} = $opts{h} if defined $opts{h};
  $params{w} = $opts{w} if defined $opts{w};
  return $self->client->post("/exec/$exec_id/resize", undef, params => \%params);
}

=method resize

    $exec->resize($exec_id, h => 40, w => 120);

Resize the TTY for an exec instance. Options: C<h> (height), C<w> (width).

=cut

sub inspect {
  my ($self, $exec_id) = @_;
  croak "Exec ID required" unless $exec_id;
  return $self->client->get("/exec/$exec_id/json");
}

=method inspect

    my $info = $exec->inspect($exec_id);

Get information about an exec instance.

=cut

=seealso

=over

=item * L<WWW::Docker> - Main Docker client

=item * L<WWW::Docker::API::Containers> - Container management

=back

=cut

1;
