package WebService::Pokemon;

use utf8;
use strictures 2;
use namespace::clean;

use CHI;
use Digest::MD5 qw(md5_hex);
use Moo;
use Sereal qw(encode_sereal decode_sereal);
use Types::Standard qw(Str);

with 'Role::REST::Client';

use WebService::Pokemon::APIResourceList;
use WebService::Pokemon::NamedAPIResource;

our $VERSION = '0.09';


has 'api_url' => (
    isa     => Str,
    is      => 'rw',
    default => sub { 'https://pokeapi.co/api/v2' },
);

has cache => (
    is      => 'rw',
    lazy    => 1,
    builder => 1,
);

sub _build_cache {
    my $self = shift;

    return CHI->new(
        driver => 'File',
        namespace => 'restcountries',
        root_dir => '/tmp/cache/',
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

    my $response_data;
    my $cache_key = md5_hex($endpoint . encode_sereal($queries));

    my $cache_response_data = $self->cache->get($cache_key);
    if (defined $cache_response_data) {
        $response_data = decode_sereal($cache_response_data);
    }
    else {
        my $response = $self->get($endpoint, $queries);
        $response_data = $response->data;

        $self->cache->set($cache_key, encode_sereal($response->data));
    }

    return $response_data;
}

sub resource {
    my ($self, $resource, $id_or_name, $limit, $offset) = @_;

    my $queries;
    if (!defined $id_or_name) {
        $queries->{limit} = $limit || 20;
        $queries->{offset} = $offset || 0;

        my $response = $self->_request($resource, $id_or_name, $queries);
        return WebService::Pokemon::APIResourceList->new(api => $self, response => $response);
    }

    my $response = $self->_request($resource, $id_or_name, $queries);
    return WebService::Pokemon::NamedAPIResource->new(api => $self, response => $response);
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

    # By id.
    my $pokemon = $pokemon_api->resource('berry', 1);

    # By name.
    my $pokemon = $pokemon_api->resource('berry', 'cheri');

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

=head3 cache

The cache directory of the HTTP reponses. By default, all cached data is stored
as files in /tmp/cache/.

    # Default cache engine is file-based storage.
    my $pokemon_api = WebService::Pokemon->new;

    # Or we define our custom cache engine with settings.
    my $pokemon_api = WebService::Pokemon->new(
        cache => CHI->new(
            driver => 'File',
            namespace => 'restcountries',
            root_dir => $ENV{PWD} . '/tmp/cache/',
        )
    );

    # Or after the object was created.
    my $pokemon_api = WebService::Pokemon->new;
    $pokemon_api->cache(
        cache => CHI->new(
            driver => 'File',
            namespace => 'restcountries',
            root_dir => $ENV{PWD} . '/tmp/cache/',
        )
    );

=head2 resource($resource, [$name], [$limit], [$offset])

Get the details of a particular resource with optional id or name; limit per
page, or offset by the record list.

    # Get paginated list of available berry resource.
    my $berry = $pokemon_api->resource('berry');

    # Or by page through limit and pagination.
    my $berry = $pokemon_api->resource('berry', undef, 60, 20);

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
