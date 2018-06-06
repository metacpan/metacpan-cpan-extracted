package WebService::Pokemon;

use utf8;
use strictures 2;
use namespace::clean;

use CHI;
use Moo;
use Types::Standard qw(Str);

with 'Role::REST::Client';

our $VERSION = '0.08';


has 'api_url' => (
    isa     => Str,
    is      => 'rw',
    default => sub { 'https://pokeapi.co/api/v2' },
);

has 'cache_path' => (
    isa     => Str,
    is      => 'rw',
    default => sub { '/tmp/cache/' },
);

has cache => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);

sub _build_cache {
    my $self = shift;

    return CHI->new(
        driver => 'File',
        namespace => 'pokemon',
        root_dir => $self->cache_path
    );
}

sub BUILD {
    my ($self, $args) = @_;

    foreach my $arg (keys %$args) {
        $self->$arg($args->{$arg}) if (defined $args->{$arg});
    }

    $self->set_persistent_header('User-Agent' => __PACKAGE__ . q| |
          . ($WebService::Pokemon::VERSION || q||));
    $self->server($self->api_url);

    return $self;
}

sub resource {
    my ($self, $resource, $name, $limit, $offset) = @_;

    my $queries;
    if (!defined $name) {
        $queries->{limit} = $limit || 20;
        $queries->{offset} = $offset || 0;
    }

    return $self->_request($resource, $name, $queries);
}

sub _request {
    my ($self, $resource, $name, $queries) = @_;

    return if (!defined $resource || length $resource <= 0);

    $queries ||= {};

    # In case the api_url was updated.
    $self->server($self->api_url);
    $self->type(qq|application/json|);

    my $endpoint = q||;
    $endpoint .= "/" . $resource;
    $endpoint .= "/" . $name if (defined $name);

    my $cache_decoded_content = $self->cache->get($endpoint);
    if (defined $cache_decoded_content) {
        my $deserializer = $self->_serializer(qq|application/json|);

        return $deserializer->deserialize($cache_decoded_content);
    }
    else {
        my $response = $self->get($endpoint, $queries);
        $self->cache->set($endpoint, $response->response->decoded_content);

        return $response->data;
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::Pokemon - A module to access the Pokémon data through RESTful API
from http://pokeapi.co.

=head1 SYNOPSIS

    use WebService::Pokemon;

    my $pokemon_api = WebService::Pokemon->new;
    my $pokemon = $pokemon_api->pokemon(id => 1);

=head1 DESCRIPTION

WebService::Pokemon is a Perl client helper library for the Pokemon API (pokeapi.co).

=head1 DEVELOPMENT

Source repo at L<https://github.com/kianmeng/webservice-pokemon|https://github.com/kianmeng/webservice-pokemon>.

=head2 Docker

If you have Docker installed, you can build your Docker container for this
project.

    $ docker build -t webservice-pokemon .
    $ docker run -it -v $(pwd):/root webservice-pokemon bash
    # cpanm --installdeps --notest .

=head2 Milla

Setting up the required packages.

    $ milla authordeps --missing | cpanm
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

Construct a new WebService::Pokemon instance. Optionally takes a hash or hash reference.

    # Instantiate the class.
    my $pokemon_api = WebService::Pokemon->new;

=head3 api_url

The URL of the API resource.

    # Instantiate the class by setting the URL of the API endpoints.
    my $pokemon_api = WebService::Pokemon->new({api_url => 'http://example.com/api/v2'});

    # Or after the object was created.
    my $pokemon_api = WebService::Pokemon->new;
    $pokemon_api->api_url('http://example.com/api/v2');

=head2 resource

Get the details of a particular resource either by id or name.

    # Get paginated list of available berry resource.
    my $berry = $pokemon_api->resource('berry');

    # Get by id.
    my $berry_firmness = $pokemon_api->resource('berry-firmnesses', 1);

    # Get by name.
    my $berry_firmness = $pokemon_api->resource('berry-firmnesses', 'very-soft');

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Kian Meng, Ang.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=head1 AUTHOR

Kian Meng, Ang E<lt>kianmeng@users.noreply.github.comE<gt>
