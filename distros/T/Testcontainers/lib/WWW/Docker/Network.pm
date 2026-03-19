package WWW::Docker::Network;
# ABSTRACT: Docker network entity

use Moo;
use namespace::clean;

our $VERSION = '0.101';

=head1 SYNOPSIS

    my $docker = WWW::Docker->new;
    my $networks = $docker->networks->list;
    my $network = $networks->[0];

    say $network->Name;
    say $network->Driver;

    $network->connect(Container => $container_id);
    $network->disconnect(Container => $container_id);
    $network->remove;

=head1 DESCRIPTION

This class represents a Docker network. Instances are returned by
L<WWW::Docker::API::Networks> methods.

=cut

has client => (
  is       => 'ro',
  required => 1,
);

=attr client

Reference to L<WWW::Docker> client.

=cut

has Id         => (is => 'ro');

=attr Id

Network ID.

=cut

has Name       => (is => 'ro');

=attr Name

Network name.

=cut

has Created    => (is => 'ro');
has Scope      => (is => 'ro');
has Driver     => (is => 'ro');

=attr Driver

Network driver (e.g., C<bridge>, C<overlay>).

=cut

has EnableIPv6 => (is => 'ro');
has IPAM       => (is => 'ro');
has Internal   => (is => 'ro');
has Attachable => (is => 'ro');
has Ingress    => (is => 'ro');
has Options    => (is => 'ro');
has Labels     => (is => 'ro');
has Containers => (is => 'ro');
has ConfigFrom => (is => 'ro');
has ConfigOnly => (is => 'ro');

sub inspect {
  my ($self) = @_;
  return $self->client->networks->inspect($self->Id);
}

=method inspect

    my $updated = $network->inspect;

Get fresh network information.

=cut

sub remove {
  my ($self) = @_;
  return $self->client->networks->remove($self->Id);
}

=method remove

    $network->remove;

Remove the network.

=cut

sub connect {
  my ($self, %opts) = @_;
  return $self->client->networks->connect($self->Id, %opts);
}

=method connect

    $network->connect(Container => $container_id);

Connect a container to this network.

=cut

sub disconnect {
  my ($self, %opts) = @_;
  return $self->client->networks->disconnect($self->Id, %opts);
}

=method disconnect

    $network->disconnect(Container => $container_id, Force => 1);

Disconnect a container from this network.

=cut

=seealso

=over

=item * L<WWW::Docker::API::Networks> - Network API operations

=item * L<WWW::Docker> - Main Docker client

=back

=cut

1;
