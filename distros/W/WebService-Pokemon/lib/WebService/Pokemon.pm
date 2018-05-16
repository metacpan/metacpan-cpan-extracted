package WebService::Pokemon;

use Mouse;
use Types::Standard qw/Str/;

use strictures 2;
use namespace::clean;

with 'Web::API';

use constant DEFAULT_BASE_API_URL => 'http://pokeapi.co/api/';
use constant DEFAULT_API_VERSION => 'v2';

our $VERSION = '0.04';


has 'api_version' => (
    is      => 'rw',
    isa     => Str,
    default => sub { DEFAULT_API_VERSION }
);

has 'v2_endpoints' => (
    is      => 'rw',
    default => sub {
        {
            pokemons => {
                method => 'GET',
                path => 'pokemon/',
                default_attributes => { limit => 20, offset => 0 }
            },
            pokemon => {
                method => 'GET',
                require_id => 1,
                path => 'pokemon/:id/'
            },
            berries => {
                method => 'GET',
                path => 'berry/',
                default_attributes => { limit => 20, offset => 0 }
            },
            berry => {
                method => 'GET',
                require_id => 1,
                path => 'berry/:id/'
            },
            berry_firmness => {
                method => 'GET',
                require_id => 1,
                path => 'berry-firmness/:id/'
            },
            berry_flavor => {
                method => 'GET',
                require_id => 1,
                path => 'berry-flavor/:id/'
            },
        };
    },
);

has 'v1_endpoints' => (
    is      => 'rw',
    default => sub {
        {
        };
    },
);

around 'format_response' => sub {
    my ($method, $self, $response, $ct, $error) = @_;

    my $answer = $self->$method($response, $ct, $error);

    return ($answer->{code} == 200)
        ? $answer->{content}
        : undef;
};

sub commands {
    my ($self) = @_;

    my $api_version = $self->api_version;

    return $self->v1_endpoints if ($api_version eq 'v1');
    return $self->v2_endpoints if ($api_version eq 'v2');
}

sub BUILD {
    my ($self, $args) = @_;

    $self->api_version($args->{api_version}) if (defined $args->{api_version});

    my $base_url = $args->{base_url} || DEFAULT_BASE_API_URL;
    $base_url .= $self->api_version;

    $self->user_agent(__PACKAGE__ . ' ' . $VERSION);
    $self->base_url($base_url);
    $self->content_type('application/json');

    $self->debug(1) if ($ENV{LOGGING});

    return $self;
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::Pokemon - A module to access the Pokémon data through RESTful API
from http://pokeapi.co.

=head1 SYNOPSIS

  use WebService::Pokemon;

=head1 DESCRIPTION

WebService::Pokemon is a Perl client helper library for the Pokemon API (pokeapi.co).

=head1 DEVELOPMENT

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
    $ LOGGING=1 milla run prove t/t/03_pokemon.t

Release the module.

    $ milla build
    $ milla release

=head1 METHODS

=head2 new([%$args])

Construct a new WebService::Pokemon instance. Optionally takes a hash or hash reference.

    # Instantiate the class.
    my $pokemon_api = WebService::Pokemon->new;

=head3 base_url

The URL of the API resource.

    # Instantiate the class by setting the URL of the API endpoints.
    my $pokemon_api = WebService::Pokemon->new({api_url => 'http://example.com/api/v2'});

=head3 api_version

The API version of the API endpoints. By default, the API version was set to
'v2'.

    # Instantiate the class by setting the API version.
    my $pokemon_api = WebService::Pokemon->new({api_version => 'v1'});

=head2 api_version

Get the current API version of the web service.

    my $version = $pokemon_api->api_version();

    # Change the API version.
    $pokemon_api->api_version('v1');

=head2 pokemon

Get the details of a particular Pokémon either by id or name.

    my $pokemon = $pokemon_api->pokemon(id => 1);
    my $pokemon = $pokemon_api->pokemon(id => 'bulbasaur');

=head2 berry

Get the details of a particular berry either by id or name.

    my $pokemon = $pokemon_api->berry(id => 1);
    my $pokemon = $pokemon_api->berry(id => 'cheri');

=head2 berry_firmness

Get the details of a particular berry firmness either by id or name.

    my $pokemon = $pokemon_api->berry_firmness(id => 1);
    my $pokemon = $pokemon_api->berry_firmness(id => 'very-soft');

=head2 berry_flavor

Get the details of a particular berry flavor either by id or name.

    my $pokemon = $pokemon_api->berry_firmness(id => 1);
    my $pokemon = $pokemon_api->berry_firmness(id => 'spicy');

=head2 commands

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Kian Meng, Ang.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=head1 AUTHOR

Kian Meng, Ang E<lt>kianmeng@users.noreply.github.comE<gt>
