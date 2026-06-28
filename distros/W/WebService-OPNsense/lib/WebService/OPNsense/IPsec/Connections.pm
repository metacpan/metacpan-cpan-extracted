#!/bin/false
# ABSTRACT: IPsec connection, auth, and child SA controller
# PODNAME: WebService::OPNsense::IPsec::Connections
use strictures 2;

package WebService::OPNsense::IPsec::Connections;
$WebService::OPNsense::IPsec::Connections::VERSION = '0.002';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ipsec/connections';
}

with 'WebService::OPNsense::Role::Settings';

sub search_connection {
    my ( $self, %params ) = @_;
    return $self->_do_search( 'searchConnection', \%params );
}

sub get_connection {
    my ( $self, $uuid ) = @_;
    return $self->_do_get( 'getConnection', $uuid );
}

sub add_connection {
    my ( $self, $connection_data ) = @_;
    return $self->_do_add( 'addConnection', $connection_data );
}

sub set_connection {
    my ( $self, $uuid, $connection_data ) = @_;
    return $self->_do_set( 'setConnection', $uuid, $connection_data );
}

sub del_connection {
    my ( $self, $uuid ) = @_;
    return $self->_do_del( 'delConnection', $uuid );
}

sub toggle_connection {
    my ( $self, $uuid, $enabled ) = @_;
    return $self->_do_toggle( 'toggleConnection', $uuid, $enabled );
}

sub search_local {
    my ( $self, %params ) = @_;
    return $self->_do_search( 'searchLocal', \%params );
}

sub get_local {
    my ( $self, $uuid ) = @_;
    return $self->_do_get( 'getLocal', $uuid );
}

sub add_local {
    my ( $self, $local_data ) = @_;
    return $self->_do_add( 'addLocal', $local_data );
}

sub set_local {
    my ( $self, $uuid, $local_data ) = @_;
    return $self->_do_set( 'setLocal', $uuid, $local_data );
}

sub del_local {
    my ( $self, $uuid ) = @_;
    return $self->_do_del( 'delLocal', $uuid );
}

sub toggle_local {
    my ( $self, $uuid, $enabled ) = @_;
    return $self->_do_toggle( 'toggleLocal', $uuid, $enabled );
}

sub search_remote {
    my ( $self, %params ) = @_;
    return $self->_do_search( 'searchRemote', \%params );
}

sub get_remote {
    my ( $self, $uuid ) = @_;
    return $self->_do_get( 'getRemote', $uuid );
}

sub add_remote {
    my ( $self, $remote_data ) = @_;
    return $self->_do_add( 'addRemote', $remote_data );
}

sub set_remote {
    my ( $self, $uuid, $remote_data ) = @_;
    return $self->_do_set( 'setRemote', $uuid, $remote_data );
}

sub del_remote {
    my ( $self, $uuid ) = @_;
    return $self->_do_del( 'delRemote', $uuid );
}

sub toggle_remote {
    my ( $self, $uuid, $enabled ) = @_;
    return $self->_do_toggle( 'toggleRemote', $uuid, $enabled );
}

sub search_child {
    my ( $self, %params ) = @_;
    return $self->_do_search( 'searchChild', \%params );
}

sub get_child {
    my ( $self, $uuid ) = @_;
    return $self->_do_get( 'getChild', $uuid );
}

sub add_child {
    my ( $self, $child_data ) = @_;
    return $self->_do_add( 'addChild', $child_data );
}

sub set_child {
    my ( $self, $uuid, $child_data ) = @_;
    return $self->_do_set( 'setChild', $uuid, $child_data );
}

sub del_child {
    my ( $self, $uuid ) = @_;
    return $self->_do_del( 'delChild', $uuid );
}

sub toggle_child {
    my ( $self, $uuid, $enabled ) = @_;
    return $self->_do_toggle( 'toggleChild', $uuid, $enabled );
}

sub _do_search {
    my ( $self, $endpoint, $query ) = @_;
    my $uri = $self->_path($endpoint);

    return $self->client->get( $uri, $query );
}

sub _do_get {
    my ( $self, $endpoint, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( "$endpoint/{uuid}", uuid => $uuid );

    return $self->client->get($uri);
}

sub _do_add {
    my ( $self, $endpoint, $item_data ) = @_;
    my $uri = $self->_path($endpoint);

    return $self->client->post( $uri, $item_data );
}

sub _do_set {
    my ( $self, $endpoint, $uuid, $item_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( "$endpoint/{uuid}", uuid => $uuid );

    return $self->client->post( $uri, $item_data );
}

sub _do_del {
    my ( $self, $endpoint, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( "$endpoint/{uuid}", uuid => $uuid );

    return $self->client->post($uri);
}

sub _do_toggle {
    my ( $self, $endpoint, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( "$endpoint/{uuid}{/enabled}", uuid => $uuid, enabled => $enabled );

    return $self->client->post($uri);
}

sub is_enabled {
    my ($self) = @_;
    my $uri = $self->_path('isEnabled');

    return $self->client->get($uri);
}

sub swanctl {
    my ($self) = @_;
    my $uri = $self->_path('swanctl');

    return $self->client->get($uri);
}

sub toggle {
    my ( $self, $enabled ) = @_;
    my $path = $self->_path( 'toggle{/enabled}', enabled => $enabled );
    return $self->client->post($path);
}

sub connection_exists {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'connectionExists/{uuid}', uuid => $uuid );

    return $self->client->get($uri);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::Connections - IPsec connection, auth, and child SA controller

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $conn = $opn->ipsec_connections;

    # Search connections
    my $results = $conn->search_connection;

    # Add a connection
    $conn->add_connection({ ... });

    # Toggle a connection
    $conn->toggle_connection($uuid, 1);

=head1 DESCRIPTION

Manages IPsec connections, local authentication,
remote authentication, and child SA configurations.

=head1 METHODS

=head2 search_connection

    my $results = $conn->search_connection(%params);

Searches for IPsec connections.

=head2 get_connection

    my $connection = $conn->get_connection($uuid);

Returns a single connection by UUID.

=head2 add_connection

    my $result = $conn->add_connection($connection_data);

Creates IPsec connection.

=head2 set_connection

    my $result = $conn->set_connection($uuid, $connection_data);

Updates connection.

=head2 del_connection

    my $result = $conn->del_connection($uuid);

Deletes a connection by UUID.

=head2 toggle_connection

    my $result = $conn->toggle_connection($uuid, $enabled);

Enables or disables a connection.

=head2 search_local

    my $results = $conn->search_local(%params);

Searches for local authentication entries.

=head2 get_local

    my $local = $conn->get_local($uuid);

Returns a single local auth entry by UUID.

=head2 add_local

    my $result = $conn->add_local($local_data);

Creates local authentication entry.

=head2 set_local

    my $result = $conn->set_local($uuid, $local_data);

Updates local auth entry.

=head2 del_local

    my $result = $conn->del_local($uuid);

Deletes a local auth entry by UUID.

=head2 toggle_local

    my $result = $conn->toggle_local($uuid, $enabled);

Enables or disables a local auth entry.

=head2 search_remote

    my $results = $conn->search_remote(%params);

Searches for remote authentication entries.

=head2 get_remote

    my $remote = $conn->get_remote($uuid);

Returns a single remote auth entry by UUID.

=head2 add_remote

    my $result = $conn->add_remote($remote_data);

Creates remote authentication entry.

=head2 set_remote

    my $result = $conn->set_remote($uuid, $remote_data);

Updates remote auth entry.

=head2 del_remote

    my $result = $conn->del_remote($uuid);

Deletes a remote auth entry by UUID.

=head2 toggle_remote

    my $result = $conn->toggle_remote($uuid, $enabled);

Enables or disables a remote auth entry.

=head2 search_child

    my $results = $conn->search_child(%params);

Searches for child SA entries.

=head2 get_child

    my $child = $conn->get_child($uuid);

Returns a single child SA entry by UUID.

=head2 add_child

    my $result = $conn->add_child($child_data);

Creates child SA entry.

=head2 set_child

    my $result = $conn->set_child($uuid, $child_data);

Updates child SA entry.

=head2 del_child

    my $result = $conn->del_child($uuid);

Deletes a child SA entry by UUID.

=head2 toggle_child

    my $result = $conn->toggle_child($uuid, $enabled);

Enables or disables a child SA entry.

=head2 get_settings

    my $config = $conn->get_settings;

Returns the global IPsec connections configuration.

=head2 set_settings

    my $result = $conn->set_settings($settings_data);

Sets the global IPsec connections configuration.

=head2 is_enabled

    my $enabled = $conn->is_enabled;

Returns whether IPsec is enabled.

=head2 swanctl

    my $config = $conn->swanctl;

Returns the swanctl configuration.

=head2 toggle

    my $result = $conn->toggle($enabled);

Enables or disables IPsec globally.

=head2 connection_exists

    my $exists = $conn->connection_exists($uuid);

Checks whether a connection UUID exists.

=head2 client

    my $http_client = $conn->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::Role::Settings>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
