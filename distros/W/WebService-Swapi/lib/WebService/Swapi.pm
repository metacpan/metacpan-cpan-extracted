package WebService::Swapi;

use utf8;

use Moo;
use Types::Standard qw(Str);

use strictures 2;
use namespace::clean;

with 'Role::REST::Client';

our $VERSION = '0.1.7';

has api_url => (
    isa     => Str,
    is      => 'rw',
    default => sub { 'https://swapi.co/api/' },
);

sub BUILD {
    my ($self) = @_;

    $self->set_persistent_header('User-Agent' => __PACKAGE__ . q| |
          . ($WebService::Swapi::VERSION || q||));
    $self->server($self->api_url);

    return $self;
}

sub ping {
    my ($self) = @_;

    my $response = $self->resources();

    return (!exists $response->{films}) ? 0 : 1;
}

sub resources {
    my ($self, $format) = @_;

    my $queries;
    $queries->{format} = $format if (defined $format);

    return $self->_request(undef, undef, $queries);
}

sub schema {
    my ($self, $object) = @_;

    return $self->_request(qq|$object/schema|);
}

sub search {
    my ($self, $object, $keyword, $format) = @_;

    my $queries;
    $queries->{search} = $keyword;
    $queries->{format} = $format if (defined $format);

    return $self->_request($object, undef, $queries);
}

sub get_object {
    my ($self, $object, $id, $format) = @_;

    my $queries;
    $queries->{format} = $format if (defined $format);

    return $self->_request($object, $id, $queries);
}

sub _request {
    my ($self, $object, $id, $queries) = @_;

    # In case the api_url was updated.
    $self->server($self->api_url);
    $self->type(qq|application/json|);

    my @paths;
    push @paths, $object if (defined $object);
    push @paths, $id     if (defined $id);

    my $endpoint = q||;
    $endpoint = join q|/|, @paths;

    my $response;
    $response = $self->get($endpoint, $queries);

    return $response->data if ($response->code eq '200');

    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Swapi - A Perl module to interface with the Star Wars API
(swapi.co) webservice.

=head1 SYNOPSIS

    use WebService::Swapi;

    $swapi = WebService::Swapi->new;

    # Check if API server is up
    my $resources = $swapi->ping();

    # Get information of all available resources
    my $resources = $swapi->resources();

    # View the JSON schema for people resource
    my $schema = $swapi->schema('people');

    # Searching
    my $results = $swapi->search('people', 'solo');

    # Get resource item
    my $item = $swapi->get_object('films', '1');

=head1 DESCRIPTION

WebService::Swapi is a Perl client helper library for the Star Wars API (swapi.co).

=head1 DEVELOPMENT

Source repo at L<https://github.com/kianmeng/webservice-swapi|https://github.com/kianmeng/webservice-swapi>.

=head2 Docker

If you have Docker installed, you can build your Docker container for this
project.

    $ docker build -t webservice-swapi .
    $ docker run -it -v $(pwd):/root webservice-swapi bash
    # cpanm --installdeps --notest .

=head2 Milla

Setting up the required packages.

    $ cpanm Dist::Milla
    $ milla listdeps --missing | cpanm

Check you code coverage.

    $ milla cover

Several ways to run the test.

    $ milla test
    $ milla test --author --release
    $ AUTHOR_TESTING=1 RELEASE_TESTING=1 milla test
    $ AUTHOR_TESTING=1 RELEASE_TESTING=1 milla run prove t/01_instantiation.t

Release the module.

    $ milla build
    $ milla release

=head1 METHODS

=head2 new([%$args])

Construct a new WebService::Swapi instance. Optionally takes a hash or hash reference.

    # Instantiate the class.
    my $swapi = WebService::Swapi->new;

=head3 api_url

The URL of the API resource.

    # Instantiate the class by setting the URL of the API endpoints.
    my $swapi = WebService::Swapi->new({api_url => 'http://example.com/api/'});

=head2 get_object($object, [$format])

Get full details of a object or resource. Optionally takes a returned format.

    # Get the details of different available object using id.
    my $object = $swapi->get_object('films', '1');

    # Get the result in different format.
    my $object_json = $swapi->get_object('films', '1', 'json');
    my $object_wookie = $swapi->get_object('films', '1', 'wookiee');

=head2 ping()

Check if the API service or server is responding to a request.

    my $server_status = $swapi->ping();

=head2 resources([$format])

List down all the available objects. Optionally takes a returned format.

    # Get all available resources or objects.
    my $resources = $swapi->resources();

    # Similarly but in different format.
    my $resources_json = $swapi->resources('json');
    my $resources_wookie = $swapi->resources('wookie');

=head2 schema($object)

Show the data structure of a resource or object.

    # Get the schema / structure of a resource or object.
    my $schema = $swapi->schema('people');

=head2 search($object, $keyword, [$format])

Searching by keywords. Takes both an object and keywords. Optionally takes a returned format.

    # Search a resource or object by keywords.
    my $results = $swapi->search('people', 'solo');

    # Or in different format.
    my $results = $swapi->search('people', 'solo', 'json');
    my $results = $swapi->search('people', 'solo', 'wookiee');

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Kian Meng, Ang.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=head1 AUTHOR

Kian-Meng, Ang E<lt>kianmeng@users.noreply.github.comE<gt>

=cut
