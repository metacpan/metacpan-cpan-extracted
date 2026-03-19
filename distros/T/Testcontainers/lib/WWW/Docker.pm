package WWW::Docker;
# ABSTRACT: Perl client for the Docker Engine API

use Moo;
use Carp qw( croak );
use Log::Any qw( $log );

our $VERSION = '0.101';

use WWW::Docker::API::System;
use WWW::Docker::API::Containers;
use WWW::Docker::API::Images;
use WWW::Docker::API::Networks;
use WWW::Docker::API::Volumes;
use WWW::Docker::API::Exec;

=head1 SYNOPSIS

    use WWW::Docker;

    # Connect to local Docker daemon via Unix socket
    my $docker = WWW::Docker->new;

    # Or connect to remote Docker daemon
    my $docker = WWW::Docker->new(
        host => 'tcp://192.168.1.100:2375',
    );

    # System information
    my $info = $docker->system->info;
    my $version = $docker->system->version;

    # Container management
    my $containers = $docker->containers->list(all => 1);
    my $result = $docker->containers->create(
        Image => 'nginx:latest',
        name  => 'my-nginx',
    );
    $docker->containers->start($result->{Id});

    # Image operations
    $docker->images->pull(fromImage => 'nginx', tag => 'latest');
    my $images = $docker->images->list;

    # Network and volume management
    my $networks = $docker->networks->list;
    my $volumes = $docker->volumes->list;

=head1 DESCRIPTION

WWW::Docker is a Perl client for the Docker Engine API. It provides a clean
object-oriented interface to manage Docker containers, images, networks, and
volumes.

Key features:

=over

=item * Pure Perl implementation with minimal dependencies

=item * Unix socket and TCP transport support

=item * Automatic API version negotiation

=item * Object-oriented entity classes (Container, Image, Network, Volume)

=item * Comprehensive logging via L<Log::Any>

=back

=head2 Architecture

The distribution is organized into several layers:

=over

=item * B<Main Client> - L<WWW::Docker> - Entry point with API version negotiation

=item * B<API Modules> - Resource-specific API methods:

=over

=item * L<WWW::Docker::API::System> - System info, version, ping

=item * L<WWW::Docker::API::Containers> - Container management

=item * L<WWW::Docker::API::Images> - Image management

=item * L<WWW::Docker::API::Networks> - Network management

=item * L<WWW::Docker::API::Volumes> - Volume management

=item * L<WWW::Docker::API::Exec> - Exec into containers

=back

=item * B<Entity Classes> - Object wrappers for Docker resources:

=over

=item * L<WWW::Docker::Container> - Container entity with convenience methods

=item * L<WWW::Docker::Image> - Image entity

=item * L<WWW::Docker::Network> - Network entity

=item * L<WWW::Docker::Volume> - Volume entity

=back

=item * B<HTTP Role> - L<WWW::Docker::Role::HTTP> - HTTP transport layer

=back

=cut

has host => (
  is      => 'ro',
  default => sub { $ENV{DOCKER_HOST} // 'unix:///var/run/docker.sock' },
);

=attr host

Docker daemon connection URL. Defaults to C<$ENV{DOCKER_HOST}> or
C<unix:///var/run/docker.sock>.

Supported formats:

=over

=item * C<unix:///path/to/socket> - Unix socket (default)

=item * C<tcp://host:port> - TCP connection

=back

=cut

has api_version => (
  is      => 'rwp',
  default => undef,
);

=attr api_version

Docker API version to use (e.g., C<1.41>). If not set, the client will
automatically negotiate the highest API version supported by the daemon.

This attribute is set automatically by L</negotiate_version>.

=cut

has tls => (
  is      => 'ro',
  default => 0,
);

=attr tls

Enable TLS for secure connections. Defaults to C<0>. Currently experimental.

=cut

has cert_path => (
  is      => 'ro',
  default => sub { $ENV{DOCKER_CERT_PATH} },
);

=attr cert_path

Path to TLS certificates. Defaults to C<$ENV{DOCKER_CERT_PATH}>.

=cut

has _version_negotiated => (
  is      => 'rw',
  default => 0,
);

with 'WWW::Docker::Role::HTTP';

has system => (
  is      => 'lazy',
  builder => sub { WWW::Docker::API::System->new(client => $_[0]) },
);

=attr system

Returns L<WWW::Docker::API::System> instance for system operations like
C<info>, C<version>, C<ping>, and C<events>.

=cut

has containers => (
  is      => 'lazy',
  builder => sub { WWW::Docker::API::Containers->new(client => $_[0]) },
);

=attr containers

Returns L<WWW::Docker::API::Containers> instance for container operations like
C<list>, C<create>, C<start>, C<stop>, and C<remove>.

=cut

has images => (
  is      => 'lazy',
  builder => sub { WWW::Docker::API::Images->new(client => $_[0]) },
);

=attr images

Returns L<WWW::Docker::API::Images> instance for image operations like
C<list>, C<pull>, C<push>, and C<remove>.

=cut

has networks => (
  is      => 'lazy',
  builder => sub { WWW::Docker::API::Networks->new(client => $_[0]) },
);

=attr networks

Returns L<WWW::Docker::API::Networks> instance for network operations like
C<list>, C<create>, C<connect>, and C<disconnect>.

=cut

has volumes => (
  is      => 'lazy',
  builder => sub { WWW::Docker::API::Volumes->new(client => $_[0]) },
);

=attr volumes

Returns L<WWW::Docker::API::Volumes> instance for volume operations like
C<list>, C<create>, and C<remove>.

=cut

has exec => (
  is      => 'lazy',
  builder => sub { WWW::Docker::API::Exec->new(client => $_[0]) },
);

=attr exec

Returns L<WWW::Docker::API::Exec> instance for executing commands in containers.

=cut

sub negotiate_version {
  my ($self) = @_;
  return if $self->_version_negotiated;
  return if defined $self->api_version;

  $log->debug("Auto-negotiating API version");
  my $version_info = $self->_request('GET', '/version');
  if ($version_info && $version_info->{ApiVersion}) {
    $self->_set_api_version($version_info->{ApiVersion});
    $log->debugf("Negotiated API version: %s", $version_info->{ApiVersion});
  }
  $self->_version_negotiated(1);
}

=method negotiate_version

    $docker->negotiate_version;

Automatically negotiate the highest API version supported by the Docker daemon.
This is called automatically before the first API request if L</api_version>
is not set.

After negotiation, L</api_version> will contain the negotiated version
(e.g., C<1.41>).

=cut

around _request => sub {
  my ($orig, $self, $method, $path, %opts) = @_;

  # Auto-negotiate before any versioned request, but not for /version itself
  if ($path ne '/version' && !defined $self->api_version && !$self->_version_negotiated) {
    $self->negotiate_version;
  }

  return $self->$orig($method, $path, %opts);
};

=head1 ENVIRONMENT VARIABLES

=over

=item C<DOCKER_HOST>

Docker daemon connection URL. Used as default for L</host> if not explicitly set.

Examples: C<unix:///var/run/docker.sock>, C<tcp://localhost:2375>

=item C<DOCKER_CERT_PATH>

Path to TLS certificates directory. Used as default for L</cert_path>.

=back

=seealso

=over

=item * L<WWW::Docker::Role::HTTP> - HTTP transport implementation

=item * L<WWW::Docker::API::System> - System and daemon operations

=item * L<WWW::Docker::API::Containers> - Container management

=item * L<WWW::Docker::API::Images> - Image management

=item * L<WWW::Docker::API::Networks> - Network management

=item * L<WWW::Docker::API::Volumes> - Volume management

=item * L<WWW::Docker::API::Exec> - Execute commands in containers

=back

=cut

1;
