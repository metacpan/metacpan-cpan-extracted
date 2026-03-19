package WWW::Docker::API::Volumes;
# ABSTRACT: Docker Engine Volumes API

use Moo;
use WWW::Docker::Volume;
use Carp qw( croak );
use namespace::clean;

our $VERSION = '0.101';

=head1 SYNOPSIS

    my $docker = WWW::Docker->new;

    # Create a volume
    my $volume = $docker->volumes->create(
        Name   => 'my-volume',
        Driver => 'local',
    );

    # List volumes
    my $volumes = $docker->volumes->list;

    # Inspect volume
    my $vol = $docker->volumes->inspect('my-volume');
    say $vol->Mountpoint;

    # Remove volume
    $docker->volumes->remove('my-volume');

=head1 DESCRIPTION

This module provides methods for managing Docker volumes including creation,
listing, inspection, and removal.

Accessed via C<< $docker->volumes >>.

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
  return WWW::Docker::Volume->new(
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
  $params{filters} = $opts{filters} if defined $opts{filters};
  my $result = $self->client->get('/volumes', params => \%params);
  return $self->_wrap_list($result->{Volumes} // []);
}

=method list

    my $volumes = $volumes->list;

List volumes. Returns ArrayRef of L<WWW::Docker::Volume> objects.

=cut

sub create {
  my ($self, %config) = @_;
  my $result = $self->client->post('/volumes/create', \%config);
  return $self->_wrap($result);
}

=method create

    my $volume = $volumes->create(
        Name   => 'my-volume',
        Driver => 'local',
    );

Create a volume. Returns L<WWW::Docker::Volume> object.

=cut

sub inspect {
  my ($self, $name) = @_;
  croak "Volume name required" unless $name;
  my $result = $self->client->get("/volumes/$name");
  return $self->_wrap($result);
}

=method inspect

    my $volume = $volumes->inspect('my-volume');

Get detailed information about a volume. Returns L<WWW::Docker::Volume> object.

=cut

sub remove {
  my ($self, $name, %opts) = @_;
  croak "Volume name required" unless $name;
  my %params;
  $params{force} = $opts{force} ? 1 : 0 if defined $opts{force};
  return $self->client->delete_request("/volumes/$name", params => \%params);
}

=method remove

    $volumes->remove('my-volume', force => 1);

Remove a volume. Optional C<force> parameter.

=cut

sub prune {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $opts{filters} if defined $opts{filters};
  return $self->client->post('/volumes/prune', undef, params => \%params);
}

=method prune

    my $result = $volumes->prune;

Delete unused volumes. Returns hashref with C<VolumesDeleted> and C<SpaceReclaimed>.

=cut

=seealso

=over

=item * L<WWW::Docker> - Main Docker client

=item * L<WWW::Docker::Volume> - Volume entity class

=back

=cut

1;
