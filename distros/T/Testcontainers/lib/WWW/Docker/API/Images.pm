package WWW::Docker::API::Images;
# ABSTRACT: Docker Engine Images API

use Moo;
use WWW::Docker::Image;
use Carp qw( croak );
use namespace::clean;

our $VERSION = '0.101';

=head1 SYNOPSIS

    my $docker = WWW::Docker->new;

    # Build an image from a tar context
    use Path::Tiny;
    my $tar = path('context.tar')->slurp_raw;
    $docker->images->build(context => $tar, t => 'myapp:latest');

    # Pull an image
    $docker->images->pull(fromImage => 'nginx', tag => 'latest');

    # List images
    my $images = $docker->images->list;
    for my $image (@$images) {
        say $image->Id;
        say join ', ', @{$image->RepoTags};
    }

    # Inspect image details
    my $image = $docker->images->inspect('nginx:latest');

    # Tag and push
    $docker->images->tag('nginx:latest', repo => 'myrepo/nginx', tag => 'v1');
    $docker->images->push('myrepo/nginx', tag => 'v1');

    # Remove image
    $docker->images->remove('nginx:latest', force => 1);

=head1 DESCRIPTION

This module provides methods for managing Docker images including pulling,
listing, tagging, pushing to registries, and removal.

All C<list> and C<inspect> methods return L<WWW::Docker::Image> objects.

Accessed via C<< $docker->images >>.

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
  return WWW::Docker::Image->new(
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
  $params{all}     = $opts{all} ? 1 : 0 if defined $opts{all};
  $params{digests} = $opts{digests} ? 1 : 0 if defined $opts{digests};
  $params{filters} = $opts{filters} if defined $opts{filters};
  my $result = $self->client->get('/images/json', params => \%params);
  return $self->_wrap_list($result // []);
}

=method list

    my $images = $images->list(all => 1);

List images. Returns ArrayRef of L<WWW::Docker::Image> objects.

Options:

=over

=item * C<all> - Show all images (default hides intermediate images)

=item * C<digests> - Include digest information

=item * C<filters> - Hashref of filters

=back

=cut

sub build {
  my ($self, %opts) = @_;
  my $context = delete $opts{context};
  croak "Build context required (tar archive as scalar ref or raw bytes)" unless defined $context;

  my %params;
  $params{dockerfile} = $opts{dockerfile} if defined $opts{dockerfile};
  $params{t}          = $opts{t}          if defined $opts{t};
  $params{q}          = $opts{q} ? 1 : 0  if defined $opts{q};
  $params{nocache}    = $opts{nocache} ? 1 : 0 if defined $opts{nocache};
  $params{pull}       = $opts{pull}       if defined $opts{pull};
  $params{rm}         = defined $opts{rm} ? ($opts{rm} ? 1 : 0) : 1;
  $params{forcerm}    = $opts{forcerm} ? 1 : 0 if defined $opts{forcerm};
  $params{memory}     = $opts{memory}     if defined $opts{memory};
  $params{memswap}    = $opts{memswap}    if defined $opts{memswap};
  $params{cpushares}  = $opts{cpushares}  if defined $opts{cpushares};
  $params{cpusetcpus} = $opts{cpusetcpus} if defined $opts{cpusetcpus};
  $params{cpuperiod}  = $opts{cpuperiod}  if defined $opts{cpuperiod};
  $params{cpuquota}   = $opts{cpuquota}   if defined $opts{cpuquota};
  $params{shmsize}    = $opts{shmsize}    if defined $opts{shmsize};
  $params{networkmode} = $opts{networkmode} if defined $opts{networkmode};
  $params{platform}   = $opts{platform}   if defined $opts{platform};
  $params{target}     = $opts{target}     if defined $opts{target};

  if ($opts{buildargs}) {
    require JSON::MaybeXS;
    $params{buildargs} = JSON::MaybeXS::encode_json($opts{buildargs});
  }
  if ($opts{labels}) {
    require JSON::MaybeXS;
    $params{labels} = JSON::MaybeXS::encode_json($opts{labels});
  }

  my $raw = ref $context eq 'SCALAR' ? $$context : $context;

  return $self->client->_request('POST', '/build',
    raw_body     => $raw,
    content_type => 'application/x-tar',
    params       => \%params,
  );
}

=method build

    # Build from a tar archive
    my $tar_data = path('context.tar')->slurp_raw;
    my $result = $docker->images->build(
        context    => $tar_data,
        t          => 'myimage:latest',
        dockerfile => 'Dockerfile',
    );

    # Build with build args
    my $result = $docker->images->build(
        context   => $tar_data,
        t         => 'myapp:v1',
        buildargs => { APP_VERSION => '1.0' },
        nocache   => 1,
    );

Build an image from a tar archive containing a Dockerfile and build context.

The C<context> parameter is required and must contain the raw bytes of a tar
archive (or a scalar reference to one).

Options:

=over

=item * C<context> - Tar archive bytes (required)

=item * C<dockerfile> - Path to Dockerfile within the archive (default: C<Dockerfile>)

=item * C<t> - Tag for the image (e.g. C<name:tag>)

=item * C<q> - Suppress verbose build output

=item * C<nocache> - Do not use cache when building

=item * C<pull> - Always pull base image

=item * C<rm> - Remove intermediate containers (default: true)

=item * C<forcerm> - Always remove intermediate containers

=item * C<buildargs> - HashRef of build-time variables

=item * C<labels> - HashRef of labels to set on the image

=item * C<memory> - Memory limit in bytes

=item * C<memswap> - Total memory (memory + swap), -1 to disable swap

=item * C<cpushares> - CPU shares (relative weight)

=item * C<cpusetcpus> - CPUs to use (e.g. C<0-3>, C<0,1>)

=item * C<cpuperiod> - CPU CFS period (microseconds)

=item * C<cpuquota> - CPU CFS quota (microseconds)

=item * C<shmsize> - Size of /dev/shm in bytes

=item * C<networkmode> - Network mode during build

=item * C<platform> - Platform (e.g. C<linux/amd64>)

=item * C<target> - Multi-stage build target

=back

=cut

sub pull {
  my ($self, %opts) = @_;
  croak "fromImage required" unless $opts{fromImage};
  my %params;
  $params{fromImage} = $opts{fromImage};
  $params{tag}       = $opts{tag} // 'latest';
  return $self->client->post('/images/create', undef, params => \%params);
}

=method pull

    $images->pull(fromImage => 'nginx', tag => 'latest');

Pull an image from a registry. C<tag> defaults to C<latest>.

=cut

sub inspect {
  my ($self, $name) = @_;
  croak "Image name required" unless $name;
  my $result = $self->client->get("/images/$name/json");
  return $self->_wrap($result);
}

=method inspect

    my $image = $images->inspect('nginx:latest');

Get detailed information about an image. Returns L<WWW::Docker::Image> object.

=cut

sub history {
  my ($self, $name) = @_;
  croak "Image name required" unless $name;
  return $self->client->get("/images/$name/history");
}

=method history

    my $history = $images->history('nginx:latest');

Get image history (layers). Returns ArrayRef of layer information.

=cut

sub push {
  my ($self, $name, %opts) = @_;
  croak "Image name required" unless $name;
  my %params;
  $params{tag} = $opts{tag} if defined $opts{tag};
  return $self->client->post("/images/$name/push", undef, params => \%params);
}

=method push

    $images->push('myrepo/nginx', tag => 'v1');

Push an image to a registry. Optionally specify C<tag>.

=cut

sub tag {
  my ($self, $name, %opts) = @_;
  croak "Image name required" unless $name;
  my %params;
  $params{repo} = $opts{repo} if defined $opts{repo};
  $params{tag}  = $opts{tag}  if defined $opts{tag};
  return $self->client->post("/images/$name/tag", undef, params => \%params);
}

=method tag

    $images->tag('nginx:latest', repo => 'myrepo/nginx', tag => 'v1');

Tag an image with a new repository and/or tag name.

=cut

sub remove {
  my ($self, $name, %opts) = @_;
  croak "Image name required" unless $name;
  my %params;
  $params{force}   = $opts{force} ? 1 : 0   if defined $opts{force};
  $params{noprune} = $opts{noprune} ? 1 : 0 if defined $opts{noprune};
  return $self->client->delete_request("/images/$name", params => \%params);
}

=method remove

    $images->remove('nginx:latest', force => 1);

Remove an image.

Options:

=over

=item * C<force> - Force removal

=item * C<noprune> - Do not delete untagged parents

=back

=cut

sub search {
  my ($self, $term, %opts) = @_;
  croak "Search term required" unless $term;
  my %params;
  $params{term}    = $term;
  $params{limit}   = $opts{limit}   if defined $opts{limit};
  $params{filters} = $opts{filters} if defined $opts{filters};
  return $self->client->get('/images/search', params => \%params);
}

=method search

    my $results = $images->search('nginx', limit => 25);

Search Docker Hub for images. Returns ArrayRef of search results.

Options: C<limit>, C<filters>.

=cut

sub prune {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $opts{filters} if defined $opts{filters};
  return $self->client->post('/images/prune', undef, params => \%params);
}

=method prune

    my $result = $images->prune(filters => { dangling => ['true'] });

Delete unused images. Returns hashref with C<ImagesDeleted> and C<SpaceReclaimed>.

=cut

=seealso

=over

=item * L<WWW::Docker> - Main Docker client

=item * L<WWW::Docker::Image> - Image entity class

=back

=cut

1;
