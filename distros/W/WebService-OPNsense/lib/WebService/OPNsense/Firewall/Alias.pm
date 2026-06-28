#!/bin/false
# ABSTRACT: Firewall alias controller
# PODNAME: WebService::OPNsense::Firewall::Alias
use strictures 2;

package WebService::OPNsense::Firewall::Alias;
$WebService::OPNsense::Firewall::Alias::VERSION = '0.002';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/firewall/alias';
}

with 'WebService::OPNsense::Role::ItemCrud';

sub reconfigure {
    my ($self) = @_;
    my $uri = $self->_path('reconfigure');

    return $self->client->post($uri);
}

sub get_alias_uuid {
    my ( $self, $name ) = @_;
    my $uri = $self->_path( 'getAliasUuid/{name}', name => $name );

    return $self->client->get($uri);
}

sub export {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'export/{uuid}', uuid => $uuid );

    return $self->client->get($uri);
}

sub import_alias {
    my ( $self, $import_data ) = @_;
    my $uri = $self->_path('import');

    return $self->client->post( $uri, $import_data );
}

sub get_table_size {
    my ($self) = @_;
    my $uri = $self->_path('getTableSize');

    return $self->client->get($uri);
}

sub list_categories {
    my ($self) = @_;
    my $uri = $self->_path('listCategories');

    return $self->client->get($uri);
}

sub list_countries {
    my ($self) = @_;
    my $uri = $self->_path('listCountries');

    return $self->client->get($uri);
}

sub list_network_aliases {
    my ($self) = @_;
    my $uri = $self->_path('listNetworkAliases');

    return $self->client->get($uri);
}

sub list_user_groups {
    my ($self) = @_;
    my $uri = $self->_path('listUserGroups');

    return $self->client->get($uri);
}

sub update {
    my ( $self, $action ) = @_;
    my $path = $self->_path( 'update{/action}', action => $action );
    return $self->client->post($path);
}

sub set_alias {
    my ( $self, $alias_data ) = @_;
    my $uri = $self->_path('set');

    return $self->client->post( $uri, $alias_data );
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

WebService::OPNsense::Firewall::Alias - Firewall alias controller

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use WebService::OPNsense::Constants qw( $ALIAS_HOST $OPN_ENABLED );

    my $alias = $opn->firewall_alias;

    # Search aliases
    my $results = $alias->search_item;

    # Create an alias
    $alias->add_item({
        alias => {
            name        => 'web-servers',
            type        => $ALIAS_HOST,
            content     => "192.0.2.10\n192.0.2.11",
            description => 'My web servers',
        },
    });

    # Toggle an alias
    $alias->toggle_item($uuid, $OPN_ENABLED);

=head1 DESCRIPTION

Manages firewall aliases.

=head1 METHODS

=head2 toggle_item

    my $result = $alias->toggle_item($uuid, $enabled);

=head2 reconfigure

    my $result = $alias->reconfigure;

Reconfigures aliases after changes.

=head2 get_alias_uuid

    my $uuid = $alias->get_alias_uuid($name);

Returns the UUID for an alias by name.

=head2 export

    my $data = $alias->export($uuid);

Exports an alias by UUID.

=head2 import_alias

    my $result = $alias->import_alias($import_data);

Imports an alias from data.

=head2 get_table_size

    my $size = $alias->get_table_size;

Returns alias table size.

=head2 list_categories

    my $categories = $alias->list_categories;

Returns a list of available alias categories.

=head2 list_countries

    my $countries = $alias->list_countries;

Returns a list of country codes for geo-based aliases.

=head2 list_network_aliases

    my $aliases = $alias->list_network_aliases;

Returns a list of network aliases available for nesting.

=head2 list_user_groups

    my $groups = $alias->list_user_groups;

Returns a list of user groups.

=head2 update

    my $result = $alias->update($action);

Updates aliases.  Optionally specify an action (e.g. C<'flush'>).

=head2 set_alias

    my $result = $alias->set_alias($alias_data);

Sets alias configuration (bulk operation).

=head2 get

    my $aliases = $alias->get;

Returns all alias configuration.

=head1 CONSTANTS

Alias type constants are available from
L<WebService::OPNsense::Constants>:

=over

=item C<$ALIAS_HOST>

=item C<$ALIAS_NETWORK>

=item C<$ALIAS_PORT>

=item C<$ALIAS_URL>

=item C<$ALIAS_URL_TABLE>

=item C<$ALIAS_ASN>

=item C<$ALIAS_GEOIP>

=item C<$ALIAS_MAC>

=item C<$ALIAS_INTERNAL>

=item C<$ALIAS_EXTERNAL>

=item C<$ALIAS_DYNIPV6HOST>

=item C<$ALIAS_AUTHGROUP>

=item C<$ALIAS_NETWORK_GROUP>

=item C<$ALIAS_URL_JSON>

=back

Use them when setting the C<type> field in an alias.

=head1 SEE ALSO

L<WebService::OPNsense::Role::ItemCrud>

=head1 PROVIDED METHODS

The following methods are inherited from consumed roles.

=head2 search_item

    my $results = $ctrl->search_item( %params );

Searches for aliases.

=head2 get_item

    my $alias = $ctrl->get_item( $uuid );

Returns a single alias by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 add_item

    my $result = $ctrl->add_item( $alias_data );

Creates alias.

=head2 set_item

    my $result = $ctrl->set_item( $uuid, $alias_data );

Updates alias.  Throws if C<$uuid> is not a valid UUID.

=head2 del_item

    my $result = $ctrl->del_item( $uuid );

Deletes an alias by UUID.  Throws if C<$uuid> is not a valid UUID.

=head2 client

    my $http_client = $ctrl->client;

Returns the underlying HTTP client object used for API requests.

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
