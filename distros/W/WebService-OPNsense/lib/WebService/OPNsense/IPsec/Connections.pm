#!/bin/false
# ABSTRACT: IPsec connection, auth, and child SA controller
# PODNAME: WebService::OPNsense::IPsec::Connections
use strictures 2;

package WebService::OPNsense::IPsec::Connections;
$WebService::OPNsense::IPsec::Connections::VERSION = '0.001';
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
    return $self->client->get( $self->_path('searchConnection'), \%params );
}

sub get_connection {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getConnection/{uuid}', uuid => $uuid ) );
}

sub add_connection {
    my ( $self, $connection_data ) = @_;
    return $self->client->post( $self->_path('addConnection'), $connection_data );
}

sub set_connection {
    my ( $self, $uuid, $connection_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setConnection/{uuid}', uuid => $uuid ), $connection_data );
}

sub del_connection {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delConnection/{uuid}', uuid => $uuid ) );
}

sub toggle_connection {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    return $self->client->post(
        $self->_path( 'toggleConnection/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled ),
    );
}

sub search_local {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchLocal'), \%params );
}

sub get_local {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getLocal/{uuid}', uuid => $uuid ) );
}

sub add_local {
    my ( $self, $local_data ) = @_;
    return $self->client->post( $self->_path('addLocal'), $local_data );
}

sub set_local {
    my ( $self, $uuid, $local_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setLocal/{uuid}', uuid => $uuid ), $local_data );
}

sub del_local {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delLocal/{uuid}', uuid => $uuid ) );
}

sub toggle_local {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    return $self->client->post(
        $self->_path( 'toggleLocal/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled ),
    );
}

sub search_remote {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchRemote'), \%params );
}

sub get_remote {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getRemote/{uuid}', uuid => $uuid ) );
}

sub add_remote {
    my ( $self, $remote_data ) = @_;
    return $self->client->post( $self->_path('addRemote'), $remote_data );
}

sub set_remote {
    my ( $self, $uuid, $remote_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setRemote/{uuid}', uuid => $uuid ), $remote_data );
}

sub del_remote {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delRemote/{uuid}', uuid => $uuid ) );
}

sub toggle_remote {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    return $self->client->post(
        $self->_path( 'toggleRemote/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled ),
    );
}

sub search_child {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchChild'), \%params );
}

sub get_child {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getChild/{uuid}', uuid => $uuid ) );
}

sub add_child {
    my ( $self, $child_data ) = @_;
    return $self->client->post( $self->_path('addChild'), $child_data );
}

sub set_child {
    my ( $self, $uuid, $child_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setChild/{uuid}', uuid => $uuid ), $child_data );
}

sub del_child {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delChild/{uuid}', uuid => $uuid ) );
}

sub toggle_child {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    return $self->client->post(
        $self->_path( 'toggleChild/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled ),
    );
}

sub is_enabled {
    my ($self) = @_;
    return $self->client->get( $self->_path('isEnabled') );
}

sub swanctl {
    my ($self) = @_;
    return $self->client->get( $self->_path('swanctl') );
}

sub toggle {
    my ( $self, $enabled ) = @_;
    my $path = $self->_path( 'toggle{/enabled}', enabled => $enabled );
    return $self->client->post($path);
}

sub connection_exists {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'connectionExists/{uuid}', uuid => $uuid ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::Connections - IPsec connection, auth, and child SA controller

=head1 VERSION

version 0.001

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

=head1 NAME

WebService::OPNsense::IPsec::Connections - IPsec connection, auth, and child SA controller

=head1 METHODS

=head2 search_connection

    my $results = $conn->search_connection(%params);

Searches for IPsec connections.

=head2 get_connection

    my $connection = $conn->get_connection($uuid);

Returns a single connection by UUID.

=head2 add_connection

    my $result = $conn->add_connection($connection_data);

Creates a new IPsec connection.

=head2 set_connection

    my $result = $conn->set_connection($uuid, $connection_data);

Updates an existing connection.

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

Creates a new local authentication entry.

=head2 set_local

    my $result = $conn->set_local($uuid, $local_data);

Updates an existing local auth entry.

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

Creates a new remote authentication entry.

=head2 set_remote

    my $result = $conn->set_remote($uuid, $remote_data);

Updates an existing remote auth entry.

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

Creates a new child SA entry.

=head2 set_child

    my $result = $conn->set_child($uuid, $child_data);

Updates an existing child SA entry.

=head2 del_child

    my $result = $conn->del_child($uuid);

Deletes a child SA entry by UUID.

=head2 toggle_child

    my $result = $conn->toggle_child($uuid, $enabled);

Enables or disables a child SA entry.

=head2 get

    my $config = $conn->get;

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

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
