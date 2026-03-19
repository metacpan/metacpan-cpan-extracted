package WWW::Docker::Volume;
# ABSTRACT: Docker volume entity

use Moo;
use namespace::clean;

our $VERSION = '0.101';

=head1 SYNOPSIS

    my $docker = WWW::Docker->new;
    my $volumes = $docker->volumes->list;
    my $volume = $volumes->[0];

    say $volume->Name;
    say $volume->Driver;
    say $volume->Mountpoint;

    $volume->remove;

=head1 DESCRIPTION

This class represents a Docker volume. Instances are returned by
L<WWW::Docker::API::Volumes> methods.

=cut

has client => (
  is       => 'ro',
  weak_ref => 1,
);

=attr client

Reference to L<WWW::Docker> client.

=cut

has Name       => (is => 'ro');

=attr Name

Volume name.

=cut

has Driver     => (is => 'ro');

=attr Driver

Volume driver (usually C<local>).

=cut

has Mountpoint => (is => 'ro');

=attr Mountpoint

Filesystem path where the volume is mounted on the host.

=cut

has CreatedAt  => (is => 'ro');
has Status     => (is => 'ro');
has Labels     => (is => 'ro');
has Scope      => (is => 'ro');
has Options    => (is => 'ro');
has UsageData  => (is => 'ro');

sub inspect {
  my ($self) = @_;
  return $self->client->volumes->inspect($self->Name);
}

=method inspect

    my $updated = $volume->inspect;

Get fresh volume information.

=cut

sub remove {
  my ($self, %opts) = @_;
  return $self->client->volumes->remove($self->Name, %opts);
}

=method remove

    $volume->remove(force => 1);

Remove the volume.

=cut

=seealso

=over

=item * L<WWW::Docker::API::Volumes> - Volume API operations

=item * L<WWW::Docker> - Main Docker client

=back

=cut

1;
