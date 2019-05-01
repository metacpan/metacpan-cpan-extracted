package WebService::Pokemon;

use 5.008_005;
use strictures 2;
use namespace::clean;
use utf8;

use Moo;
use Types::Standard qw(Bool Str);
use URI::Fast qw(uri);

use WebService::Pokemon::APIResourceList;
use WebService::Pokemon::NamedAPIResource;

with 'Role::REST::Client';

use constant DEFAULT_ITEMS_PER_PAGE => 20;
use constant DEFAULT_ITEMS_OFFSET => 0;

our $VERSION = '0.10';

has 'api_url' => (
    isa => Str,
    is => 'rw',
    default => sub { 'https://pokeapi.co/api/v2' },
);

has autoload => (
    isa => Bool,
    is  => 'rw',
    default => sub { 0 },
);

sub BUILD {
    my ($self, $args) = @_;

    foreach my $arg (keys %{$args}) {
        $self->$arg($args->{$arg}) if (defined $args->{$arg});
    }

    $self->set_persistent_header('User-Agent' => __PACKAGE__ . q| |
            . ($WebService::Pokemon::VERSION || q||));
    $self->server($self->api_url);

    return $self;
}

sub _request {
    my ($self, $resource, $id_or_name, $queries) = @_;

    return if (!defined $resource || length $resource <= 0);

    $queries ||= {};

    # In case the api_url was updated.
    $self->server($self->api_url);
    $self->type(q|application/json|);

    my $endpoint = q||;
    $endpoint .= qq|/$resource|;
    $endpoint .= qq|/$id_or_name| if (defined $id_or_name);

    my $response = $self->get($endpoint, $queries);
    my $response_data = $response->data;

    return $response_data;
}

sub resource {
    my ($self, $resource, $id_or_name, $limit, $offset) = @_;

    my $queries;
    if (!defined $id_or_name) {
        $queries->{limit} = $limit || DEFAULT_ITEMS_PER_PAGE;
        $queries->{offset} = $offset || DEFAULT_ITEMS_OFFSET;

        my $response = $self->_request($resource, $id_or_name, $queries);

        return WebService::Pokemon::APIResourceList->new(
            api => $self,
            response => $response
        );
    }

    my $response = $self->_request($resource, $id_or_name, $queries);

    return WebService::Pokemon::NamedAPIResource->new(
        api => $self,
        response => $response
    );
}

sub resource_by_url {
    my ($self, $url) = @_;

    my $uri = uri($url);

    my ($resource, $id_or_name);

    my $split_path = $uri->split_path;
    if (scalar @{$split_path} == 3) {
        $resource = @{$split_path}[-1];
    }
    else {
        $resource = @{$split_path}[-2];
        $id_or_name = @{$split_path}[-1];
    }

    return $self->resource(
        $resource, $id_or_name,
        $uri->param('limit'),
        $uri->param('offset'));
}

1;
__END__

=encoding utf-8

=for stopwords pokemon pokémon pokeapi autoload

=head1 NAME

WebService::Pokemon - Perl library for accessing the Pokémon data,
http://pokeapi.co.

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

Source repository at L<https://github.com/kianmeng/webservice-pokemon|https://github.com/kianmeng/webservice-pokemon>.

How to contribute? Follow through the L<CONTRIBUTING.md|https://github.com/kianmeng/webservice-pokemon/blob/master/CONTRIBUTING.md> document to setup your development environment.

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

=head3 autoload

Set this if you want to expand all fields point to external URL.

    # Instantiate the class by setting the URL of the API endpoints.
    my $pokemon_api = WebService::Pokemon->new({autoload => 1});

    # Or after the object was created.
    my $pokemon_api = WebService::Pokemon->new;
    $pokemon_api->autoload(1);
    $pokemon_api->resource('berry');

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

=head2 resource_by_url($url)

Get the details of a particular resource by full URL.

    # Get paginated list of available berry resource with default item size.
    my $berries = $pokemon_api->resource_by_url('https://pokeapi.co/api/v2/berry/');

    # Get paginated list of available berry resource with explicit default item size.
    my $berries = $pokemon_api->resource_by_url('https://pokeapi.co/api/v2/berry/?limit=20&offset=40');

    # Get particular berry resource.
    my $berry = $pokemon_api->resource_by_url('https://pokeapi.co/api/v2/berry/1');

=head1 AUTHOR

Kian Meng, Ang E<lt>kianmeng@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Kian Meng, Ang.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

