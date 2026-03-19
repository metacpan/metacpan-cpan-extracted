package WWW::Docker::Image;
# ABSTRACT: Docker image entity

use Moo;
use namespace::clean;

our $VERSION = '0.101';

=head1 SYNOPSIS

    my $docker = WWW::Docker->new;
    my $images = $docker->images->list;
    my $image = $images->[0];

    say $image->Id;
    say join ', ', @{$image->RepoTags};
    say $image->Size;

    $image->tag(repo => 'myrepo/app', tag => 'v1');
    $image->remove;

=head1 DESCRIPTION

This class represents a Docker image. Instances are returned by
L<WWW::Docker::API::Images> methods.

=cut

has client => (
  is       => 'ro',
  weak_ref => 1,
);

=attr client

Reference to L<WWW::Docker> client.

=cut

has Id           => (is => 'ro');

=attr Id

Image ID (usually sha256:... hash).

=cut

has ParentId     => (is => 'ro');
has RepoTags     => (is => 'ro');

=attr RepoTags

ArrayRef of repository tags (e.g., C<["nginx:latest", "nginx:1.21"]>).

=cut

has RepoDigests  => (is => 'ro');
has Created      => (is => 'ro');
has Size         => (is => 'ro');

=attr Size

Image size in bytes.

=cut

has SharedSize   => (is => 'ro');
has VirtualSize  => (is => 'ro');
has Labels       => (is => 'ro');
has Containers   => (is => 'ro');

# Attributes from inspect response
has Architecture => (is => 'ro');
has Os           => (is => 'ro');
has Config       => (is => 'ro');
has RootFS       => (is => 'ro');
has Metadata     => (is => 'ro');

sub inspect {
  my ($self) = @_;
  return $self->client->images->inspect($self->Id);
}

=method inspect

    my $updated = $image->inspect;

Get fresh image information.

=cut

sub history {
  my ($self) = @_;
  return $self->client->images->history($self->Id);
}

=method history

    my $history = $image->history;

Get image layer history.

=cut

sub tag {
  my ($self, %opts) = @_;
  return $self->client->images->tag($self->Id, %opts);
}

=method tag

    $image->tag(repo => 'myrepo/app', tag => 'v1');

Tag the image.

=cut

sub remove {
  my ($self, %opts) = @_;
  return $self->client->images->remove($self->Id, %opts);
}

=method remove

    $image->remove(force => 1);

Remove the image.

=cut

=seealso

=over

=item * L<WWW::Docker::API::Images> - Image API operations

=item * L<WWW::Docker> - Main Docker client

=back

=cut

1;
