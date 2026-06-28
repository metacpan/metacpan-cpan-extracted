#!/bin/false
# ABSTRACT: Routes API controller
# PODNAME: WebService::OPNsense::Routes
use strictures 2;

package WebService::OPNsense::Routes;
$WebService::OPNsense::Routes::VERSION = '0.002';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/routes/routes';
}

with 'WebService::OPNsense::Role::APIPath';

sub status {
    my ($self) = @_;
    return $self->client->get('/api/routes/status/status');
}

sub search_route {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('searchroute');

    return $self->client->get( $uri, \%params );
}

sub get_route {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'getroute/{uuid}', uuid => $uuid );

    return $self->client->get($uri);
}

sub add_route {
    my ( $self, $route_data ) = @_;
    my $uri = $self->_path('addroute');

    return $self->client->post( $uri, $route_data );
}

sub set_route {
    my ( $self, $uuid, $route_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'setroute/{uuid}', uuid => $uuid );

    return $self->client->post( $uri, $route_data );
}

sub del_route {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'delroute/{uuid}', uuid => $uuid );

    return $self->client->post($uri);
}

sub toggle_route {
    my ( $self, $uuid, $disabled ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'toggleroute/{uuid}{/disabled}', uuid => $uuid, disabled => $disabled );

    return $self->client->post(
        $uri,
    );
}

sub reconfigure {
    my ($self) = @_;
    my $uri = $self->_path('reconfigure');

    return $self->client->post($uri);
}

sub get {
    my ($self) = @_;
    my $uri = $self->_path('get');

    return $self->client->get($uri);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Routes - Routes API controller

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use WebService::OPNsense::Constants qw( $OPN_DISABLED );

    my $routes = $opn->routes;

    my $status = $routes->status;
    my $list   = $routes->search_route(current => 1, rowCount => 50);

    $routes->add_route({
        route => {
            network  => '10.0.0.0/8',
            gateway  => '192.168.1.1',
            disabled => $OPN_DISABLED,
        },
    });

=head1 DESCRIPTION

Manages static routes.

=head1 METHODS

=head2 status

    my $status = $routes->status;

Returns gateway status information.

=head2 search_route

    my $results = $routes->search_route(%params);

Searches for routes.  Parameters: C<current>, C<rowCount>, C<searchPhrase>.

=head2 get_route

    my $route = $routes->get_route($uuid);

Returns a single route by UUID.

=head2 add_route

    my $result = $routes->add_route($route_data);

Creates static route.  C<$route_data> should be a hashref
matching the OPNsense API format (e.g. C<< { route => { ... } } >>).

=head2 set_route

    my $result = $routes->set_route($uuid, $route_data);

Updates route.

=head2 del_route

    my $result = $routes->del_route($uuid);

Deletes a route by UUID.

=head2 toggle_route

    my $result = $routes->toggle_route($uuid, $disabled);

Enables or disables a route.

=head2 reconfigure

    my $result = $routes->reconfigure;

Applies pending route changes.

=head2 get

    my $routes = $routes->get;

Returns all route configuration.

=head1 CONSTANTS

Gateway constants are available from
L<WebService::OPNsense::Constants>:

=over

=item C<$GATEWAY_DEFAULT>

=back

Use them when setting the C<gateway> field in a route.

=head1 SEE ALSO

L<WebService::OPNsense::Role::APIPath>

=head2 client

    my $http_client = $routes->client;

Returns the underlying HTTP client object used for API requests.

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
