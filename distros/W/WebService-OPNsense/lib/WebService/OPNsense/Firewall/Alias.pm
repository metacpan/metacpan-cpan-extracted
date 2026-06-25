#!/bin/false
# ABSTRACT: Firewall alias controller
# PODNAME: WebService::OPNsense::Firewall::Alias
use strictures 2;

package WebService::OPNsense::Firewall::Alias;
$WebService::OPNsense::Firewall::Alias::VERSION = '0.001';
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
    return $self->client->post( $self->_path('reconfigure') );
}

sub get_alias_uuid {
    my ( $self, $name ) = @_;
    return $self->client->get( $self->_path( 'getAliasUuid/{name}', name => $name ) );
}

sub export {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'export/{uuid}', uuid => $uuid ) );
}

sub import_alias {
    my ( $self, $import_data ) = @_;
    return $self->client->post( $self->_path('import'), $import_data );
}

sub get_table_size {
    my ($self) = @_;
    return $self->client->get( $self->_path('getTableSize') );
}

sub list_categories {
    my ($self) = @_;
    return $self->client->get( $self->_path('listCategories') );
}

sub list_countries {
    my ($self) = @_;
    return $self->client->get( $self->_path('listCountries') );
}

sub list_network_aliases {
    my ($self) = @_;
    return $self->client->get( $self->_path('listNetworkAliases') );
}

sub list_user_groups {
    my ($self) = @_;
    return $self->client->get( $self->_path('listUserGroups') );
}

sub update {
    my ( $self, $action ) = @_;
    my $path = $self->_path( 'update{/action}', action => $action );
    return $self->client->post($path);
}

sub set_alias {
    my ( $self, $alias_data ) = @_;
    return $self->client->post( $self->_path('set'), $alias_data );
}

sub get {
    my ($self) = @_;
    return $self->client->get( $self->_path('get') );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Firewall::Alias - Firewall alias controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $alias = $opn->firewall_alias;

    # Search aliases
    my $results = $alias->search_item;

    # Create an alias
    $alias->add_item({
        alias => {
            name        => 'web-servers',
            type        => 'host',
            content     => "192.0.2.10\n192.0.2.11",
            description => 'My web servers',
        },
    });

=head1 DESCRIPTION

Manages firewall aliases.

=head1 NAME

WebService::OPNsense::Firewall::Alias - Firewall alias controller

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

Returns the current alias table size.

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

=for Pod::Coverage _api_path _path client search_item get_item add_item set_item del_item toggle_item

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
