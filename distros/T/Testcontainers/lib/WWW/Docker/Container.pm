package WWW::Docker::Container;
# ABSTRACT: Docker container entity

use Moo;
use namespace::clean;

our $VERSION = '0.101';

=head1 SYNOPSIS

    my $docker = WWW::Docker->new;

    # Get container from list or inspect
    my $containers = $docker->containers->list;
    my $container = $containers->[0];

    # Access container properties
    say $container->Id;
    say $container->Status;
    say $container->Image;

    # Perform operations
    $container->start;
    $container->stop(timeout => 10);
    my $logs = $container->logs(tail => 100);
    $container->remove(force => 1);

    # Check state
    if ($container->is_running) {
        say "Container is running";
    }

=head1 DESCRIPTION

This class represents a Docker container and provides convenient access to
container properties and operations. Instances are returned by
L<WWW::Docker::API::Containers> methods like C<list> and C<inspect>.

Each attribute corresponds to fields in the Docker API container representation.
Methods delegate to L<WWW::Docker::API::Containers> for operations.

=cut

has client => (
  is       => 'ro',
  weak_ref => 1,
);

=attr client

Reference to L<WWW::Docker> client. Used for delegating operations.

=cut

has Id            => (is => 'ro');

=attr Id

Container ID (64-character hex string).

=cut

has Names         => (is => 'ro');

=attr Names

ArrayRef of container names (from C<list>).

=cut

has Image         => (is => 'ro');

=attr Image

Image name used to create the container.

=cut

has ImageID       => (is => 'ro');
has Command       => (is => 'ro');
has Created       => (is => 'ro');

=attr Created

Container creation timestamp (Unix epoch).

=cut

has State         => (is => 'ro');

=attr State

Container state. From C<list>: string like C<running>, C<exited>. From
C<inspect>: hashref with C<Running>, C<Paused>, C<ExitCode>, etc.

=cut

has Status        => (is => 'ro');

=attr Status

Human-readable status string (e.g., "Up 2 hours").

=cut

has Ports         => (is => 'ro');
has Labels        => (is => 'ro');
has SizeRw        => (is => 'ro');
has SizeRootFs    => (is => 'ro');
has HostConfig    => (is => 'ro');
has NetworkSettings => (is => 'ro');
has Mounts        => (is => 'ro');

# Attributes from inspect response
has Name          => (is => 'ro');

=attr Name

Container name (from C<inspect>, includes leading C</>).

=cut

has RestartCount  => (is => 'ro');
has Driver        => (is => 'ro');
has Platform      => (is => 'ro');
has Path          => (is => 'ro');
has Args          => (is => 'ro');
has Config        => (is => 'ro');

sub start {
  my ($self) = @_;
  return $self->client->containers->start($self->Id);
}

=method start

    $container->start;

Start the container. Delegates to L<WWW::Docker::API::Containers/start>.

=cut

sub stop {
  my ($self, %opts) = @_;
  return $self->client->containers->stop($self->Id, %opts);
}

=method stop

    $container->stop(timeout => 10);

Stop the container. Delegates to L<WWW::Docker::API::Containers/stop>.

=cut

sub restart {
  my ($self, %opts) = @_;
  return $self->client->containers->restart($self->Id, %opts);
}

=method restart

    $container->restart;

Restart the container.

=cut

sub kill {
  my ($self, %opts) = @_;
  return $self->client->containers->kill($self->Id, %opts);
}

=method kill

    $container->kill(signal => 'SIGTERM');

Send a signal to the container.

=cut

sub remove {
  my ($self, %opts) = @_;
  return $self->client->containers->remove($self->Id, %opts);
}

=method remove

    $container->remove(force => 1);

Remove the container.

=cut

sub logs {
  my ($self, %opts) = @_;
  return $self->client->containers->logs($self->Id, %opts);
}

=method logs

    my $logs = $container->logs(tail => 100);

Get container logs.

=cut

sub inspect {
  my ($self) = @_;
  return $self->client->containers->inspect($self->Id);
}

=method inspect

    my $updated = $container->inspect;

Get fresh container information.

=cut

sub pause {
  my ($self) = @_;
  return $self->client->containers->pause($self->Id);
}

=method pause

    $container->pause;

Pause all processes in the container.

=cut

sub unpause {
  my ($self) = @_;
  return $self->client->containers->unpause($self->Id);
}

=method unpause

    $container->unpause;

Unpause the container.

=cut

sub top {
  my ($self, %opts) = @_;
  return $self->client->containers->top($self->Id, %opts);
}

=method top

    my $processes = $container->top;

List running processes in the container.

=cut

sub stats {
  my ($self, %opts) = @_;
  return $self->client->containers->stats($self->Id, %opts);
}

=method stats

    my $stats = $container->stats;

Get resource usage statistics.

=cut

sub is_running {
  my ($self) = @_;
  my $state = $self->State;
  return 0 unless defined $state;
  if (ref $state eq 'HASH') {
    return $state->{Running} ? 1 : 0;
  }
  return lc($state) eq 'running' ? 1 : 0;
}

=method is_running

    if ($container->is_running) { ... }

Returns true if container is running, false otherwise. Works with both C<list>
and C<inspect> response formats.

=cut

=seealso

=over

=item * L<WWW::Docker::API::Containers> - Container API operations

=item * L<WWW::Docker> - Main Docker client

=back

=cut

1;
