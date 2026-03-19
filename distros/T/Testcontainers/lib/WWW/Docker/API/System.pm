package WWW::Docker::API::System;
# ABSTRACT: Docker Engine System API

use Moo;
use Carp qw( croak );
use namespace::clean;

our $VERSION = '0.101';

=head1 SYNOPSIS

    my $docker = WWW::Docker->new;

    # System information
    my $info = $docker->system->info;
    say "Docker version: " . $info->{ServerVersion};

    # API version
    my $version = $docker->system->version;
    say "API version: " . $version->{ApiVersion};

    # Health check
    my $pong = $docker->system->ping;

    # Monitor events
    my $events = $docker->system->events(
        since => time() - 3600,
    );

    # Disk usage
    my $df = $docker->system->df;

=head1 DESCRIPTION

This module provides access to Docker system-level operations including daemon
information, version detection, health checks, and event monitoring.

Accessed via C<< $docker->system >>.

=cut

has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);

=attr client

Reference to L<WWW::Docker> client. Weak reference to avoid circular dependencies.

=cut

sub info {
  my ($self) = @_;
  return $self->client->get('/info');
}

=method info

    my $info = $system->info;

Get system-wide information about the Docker daemon.

Returns hashref with keys including:

=over

=item * C<ServerVersion> - Docker version

=item * C<Containers> - Total number of containers

=item * C<Images> - Total number of images

=item * C<Driver> - Storage driver

=item * C<MemTotal> - Total memory

=back

=cut

sub version {
  my ($self) = @_;
  return $self->client->get('/version');
}

=method version

    my $version = $system->version;

Get version information about the Docker daemon and API.

Returns hashref with keys including C<ApiVersion>, C<Version>, C<GitCommit>,
C<GoVersion>, C<Os>, and C<Arch>.

=cut

sub ping {
  my ($self) = @_;
  my $result = $self->client->get('/_ping');
  return $result;
}

=method ping

    my $pong = $system->ping;

Health check endpoint. Returns C<OK> string if daemon is responsive.

=cut

sub events {
  my ($self, %opts) = @_;
  my $callback = delete $opts{callback};
  my %params;
  $params{since}   = $opts{since}   if defined $opts{since};
  $params{until}   = $opts{until}   if defined $opts{until};
  $params{filters} = $opts{filters} if defined $opts{filters};
  if ($callback) {
    return $self->client->stream_get('/events',
      params   => \%params,
      callback => $callback,
    );
  }
  return $self->client->get('/events', params => \%params);
}

=method events

    # Bounded query (since+until) — returns arrayref of event hashrefs:
    my $events = $system->events(
        since   => 1234567890,
        until   => 1234567900,
        filters => { type => ['container'] },
    );

    # Real-time streaming — invokes callback for each event as it arrives:
    $system->events(
        filters  => { type => ['container'] },
        callback => sub {
            my ($event) = @_;
            printf "Event: %s %s\n", $event->{Type}, $event->{Action};
        },
    );

Get real-time events from the Docker daemon.

When C<callback> is provided, events are read incrementally from the socket and
the callback is invoked once per event as JSON objects arrive.  This is required
for long-lived (unbounded) streams; without a C<callback> the response body is
buffered in memory, which is only safe when C<until> bounds the response.

Options:

=over

=item * C<since> - Show events created since this timestamp

=item * C<until> - Show events created before this timestamp

=item * C<filters> - Hashref of filters (e.g., C<< { type => ['container', 'image'] } >>)

=item * C<callback> - CodeRef invoked with each decoded event hashref (enables streaming mode)

=back

=cut

sub df {
  my ($self) = @_;
  return $self->client->get('/system/df');
}

=method df

    my $usage = $system->df;

Get data usage information (disk usage by images, containers, and volumes).

Returns hashref with C<LayersSize>, C<Images>, C<Containers>, and C<Volumes> arrays.

=cut

=seealso

=over

=item * L<WWW::Docker> - Main Docker client

=back

=cut

1;
