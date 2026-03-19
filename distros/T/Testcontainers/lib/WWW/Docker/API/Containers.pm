package WWW::Docker::API::Containers;
# ABSTRACT: Docker Engine Containers API

use Moo;
use WWW::Docker::Container;
use Carp qw( croak );
use namespace::clean;

our $VERSION = '0.101';

=head1 SYNOPSIS

    my $docker = WWW::Docker->new;

    # List containers
    my $containers = $docker->containers->list(all => 1);
    for my $container (@$containers) {
        say $container->Id;
        say $container->Status;
    }

    # Create and start a container
    my $result = $docker->containers->create(
        Image => 'nginx:latest',
        name  => 'my-nginx',
        ExposedPorts => { '80/tcp' => {} },
    );
    $docker->containers->start($result->{Id});

    # Inspect container details
    my $container = $docker->containers->inspect($result->{Id});
    say $container->Name;

    # Stop and remove
    $docker->containers->stop($result->{Id}, timeout => 10);
    $docker->containers->remove($result->{Id});

    # View logs
    my $logs = $docker->containers->logs($result->{Id}, tail => 100);

=head1 DESCRIPTION

This module provides methods for managing Docker containers including creation,
lifecycle operations (start, stop, restart), inspection, logs, and more.

All C<list> and C<inspect> methods return L<WWW::Docker::Container> objects
for convenient access to container properties and operations.

Accessed via C<< $docker->containers >>.

=cut

has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);

=attr client

Reference to L<WWW::Docker> client. Weak reference to avoid circular dependencies.

=cut

sub _wrap {
  my ($self, $data) = @_;
  return WWW::Docker::Container->new(
    client => $self->client,
    %$data,
  );
}

sub _wrap_list {
  my ($self, $list) = @_;
  return [ map { $self->_wrap($_) } @$list ];
}

sub list {
  my ($self, %opts) = @_;
  my %params;
  $params{all}     = $opts{all} ? 1 : 0     if defined $opts{all};
  $params{limit}   = $opts{limit}            if defined $opts{limit};
  $params{size}    = $opts{size} ? 1 : 0     if defined $opts{size};
  $params{filters} = $opts{filters}          if defined $opts{filters};
  my $result = $self->client->get('/containers/json', params => \%params);
  return $self->_wrap_list($result // []);
}

=method list

    my $containers = $containers->list(%opts);

List containers. Returns ArrayRef of L<WWW::Docker::Container> objects.

Options:

=over

=item * C<all> - Show all containers (default shows just running)

=item * C<limit> - Limit results to N most recently created containers

=item * C<size> - Include size information

=item * C<filters> - Hashref of filters

=back

=cut

sub create {
  my ($self, %config) = @_;
  my %params;
  $params{name} = delete $config{name} if defined $config{name};
  my $result = $self->client->post('/containers/create', \%config, params => \%params);
  return $result;
}

=method create

    my $result = $containers->create(
        Image => 'nginx:latest',
        name  => 'my-nginx',
        Cmd   => ['/bin/sh'],
        Env   => ['FOO=bar'],
    );

Create a new container. Returns hashref with C<Id> and C<Warnings>.

The C<name> parameter is extracted and passed as query parameter. All other
parameters are Docker container configuration (see Docker API documentation).

Common config keys: C<Image>, C<Cmd>, C<Env>, C<ExposedPorts>, C<HostConfig>.

=cut

sub inspect {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  my $result = $self->client->get("/containers/$id/json");
  return $self->_wrap($result);
}

=method inspect

    my $container = $containers->inspect($id);

Get detailed information about a container. Returns L<WWW::Docker::Container> object.

=cut

sub start {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  return $self->client->post("/containers/$id/start", undef);
}

=method start

    $containers->start($id);

Start a container.

=cut

sub stop {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{t}      = $opts{timeout} if defined $opts{timeout};
  $params{signal} = $opts{signal}  if defined $opts{signal};
  return $self->client->post("/containers/$id/stop", undef, params => \%params);
}

=method stop

    $containers->stop($id, timeout => 10);

Stop a container.

Options:

=over

=item * C<timeout> - Seconds to wait before killing (default 10)

=item * C<signal> - Signal to send (default SIGTERM)

=back

=cut

sub restart {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{t} = $opts{timeout} if defined $opts{timeout};
  return $self->client->post("/containers/$id/restart", undef, params => \%params);
}

=method restart

    $containers->restart($id, timeout => 10);

Restart a container. Optionally specify C<timeout> in seconds.

=cut

sub kill {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{signal} = $opts{signal} if defined $opts{signal};
  return $self->client->post("/containers/$id/kill", undef, params => \%params);
}

=method kill

    $containers->kill($id, signal => 'SIGKILL');

Send a signal to a container. Default signal is C<SIGKILL>.

=cut

sub remove {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{v}     = $opts{volumes} ? 1 : 0 if defined $opts{volumes};
  $params{force} = $opts{force} ? 1 : 0   if defined $opts{force};
  $params{link}  = $opts{link} ? 1 : 0    if defined $opts{link};
  return $self->client->delete_request("/containers/$id", params => \%params);
}

=method remove

    $containers->remove($id, force => 1, volumes => 1);

Remove a container.

Options:

=over

=item * C<force> - Force removal (kill if running)

=item * C<volumes> - Remove associated volumes

=item * C<link> - Remove specified link

=back

=cut

sub logs {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{stdout}     = defined $opts{stdout} ? ($opts{stdout} ? 1 : 0) : 1;
  $params{stderr}     = defined $opts{stderr} ? ($opts{stderr} ? 1 : 0) : 1;
  $params{since}      = $opts{since}      if defined $opts{since};
  $params{until}      = $opts{until}      if defined $opts{until};
  $params{timestamps} = $opts{timestamps} ? 1 : 0 if defined $opts{timestamps};
  $params{tail}       = $opts{tail}       if defined $opts{tail};
  return $self->client->get("/containers/$id/logs", params => \%params);
}

=method logs

    my $logs = $containers->logs($id, tail => 100, timestamps => 1);

Get container logs.

Options:

=over

=item * C<stdout> - Include stdout (default 1)

=item * C<stderr> - Include stderr (default 1)

=item * C<since> - Show logs since timestamp

=item * C<until> - Show logs before timestamp

=item * C<timestamps> - Include timestamps

=item * C<tail> - Number of lines from end (e.g., C<100> or C<all>)

=back

=cut

sub top {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{ps_args} = $opts{ps_args} if defined $opts{ps_args};
  return $self->client->get("/containers/$id/top", params => \%params);
}

=method top

    my $processes = $containers->top($id, ps_args => 'aux');

List running processes in a container. Returns hashref with C<Titles> and C<Processes> arrays.

=cut

sub stats {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{stream}  = 0;
  $params{'one-shot'} = 1;
  return $self->client->get("/containers/$id/stats", params => \%params);
}

=method stats

    my $stats = $containers->stats($id);

Get container resource usage statistics (CPU, memory, network, I/O). Returns one-shot statistics.

=cut

sub wait {
  my ($self, $id, %opts) = @_;
  croak "Container ID required" unless $id;
  my %params;
  $params{condition} = $opts{condition} if defined $opts{condition};
  return $self->client->post("/containers/$id/wait", undef, params => \%params);
}

=method wait

    my $result = $containers->wait($id, condition => 'not-running');

Block until container stops, then return exit code. Optional C<condition> parameter.

=cut

sub pause {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  return $self->client->post("/containers/$id/pause", undef);
}

=method pause

    $containers->pause($id);

Pause all processes in a container.

=cut

sub unpause {
  my ($self, $id) = @_;
  croak "Container ID required" unless $id;
  return $self->client->post("/containers/$id/unpause", undef);
}

=method unpause

    $containers->unpause($id);

Unpause all processes in a container.

=cut

sub rename {
  my ($self, $id, $name) = @_;
  croak "Container ID required" unless $id;
  croak "New name required" unless $name;
  return $self->client->post("/containers/$id/rename", undef, params => { name => $name });
}

=method rename

    $containers->rename($id, 'new-name');

Rename a container.

=cut

sub update {
  my ($self, $id, %config) = @_;
  croak "Container ID required" unless $id;
  return $self->client->post("/containers/$id/update", \%config);
}

=method update

    $containers->update($id, Memory => 314572800);

Update container resource limits and configuration.

=cut

sub prune {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $opts{filters} if defined $opts{filters};
  return $self->client->post('/containers/prune', undef, params => \%params);
}

=method prune

    my $result = $containers->prune(filters => { until => ['24h'] });

Delete stopped containers. Returns hashref with C<ContainersDeleted> and C<SpaceReclaimed>.

=cut

=seealso

=over

=item * L<WWW::Docker> - Main Docker client

=item * L<WWW::Docker::Container> - Container entity class

=item * L<WWW::Docker::API::Exec> - Execute commands in containers

=back

=cut

1;
