#!/bin/false
# ABSTRACT: Shared CRUD methods for Kea DHCP item types
# PODNAME: WebService::OPNsense::Role::KeaItemCrud
use strictures 2;

package WebService::OPNsense::Role::KeaItemCrud;
$WebService::OPNsense::Role::KeaItemCrud::VERSION = '0.003';
use Carp qw( croak );
use Moo::Role;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;    # must be last

with 'WebService::OPNsense::Role::APIPath';

requires 'client';

my %_KEA_UC = (
    option      => 'Option',
    peer        => 'Peer',
    reservation => 'Reservation',
    subnet      => 'Subnet',
    pd_pool     => 'PdPool',
);

sub _kea_add_item {
    my ( $self, $item, $item_data ) = @_;
    my $item_type = $self->_kea_item_type($item);
    my $uri       = $self->_path( 'add' . $item_type );
    return $self->client->post( $uri, $item_data );
}

sub _kea_del_item {
    my ( $self, $item, $uuid ) = @_;
    validate_uuid($uuid);
    my $item_type = $self->_kea_item_type($item);
    my $uri       = $self->_path( 'del' . $item_type . '/{uuid}', uuid => $uuid );
    return $self->client->post($uri);
}

sub _kea_get_item {
    my ( $self, $item, $uuid ) = @_;
    validate_uuid($uuid);
    my $item_type = $self->_kea_item_type($item);
    my $uri       = $self->_path( 'get' . $item_type . '/{uuid}', uuid => $uuid );
    return $self->client->get($uri);
}

sub _kea_search_item {
    my ( $self, $item, %params ) = @_;
    my $item_type = $self->_kea_item_type($item);
    my $uri       = $self->_path( 'search' . $item_type );
    return $self->client->get( $uri, \%params );
}

sub _kea_set_item {
    my ( $self, $item, $uuid, $item_data ) = @_;
    validate_uuid($uuid);
    my $item_type = $self->_kea_item_type($item);
    my $uri       = $self->_path( 'set' . $item_type . '/{uuid}', uuid => $uuid );
    return $self->client->post( $uri, $item_data );
}

sub add_option {
    my ( $self, @args ) = @_;
    return $self->_kea_add_item( 'option', @args );
}

sub add_peer {
    my ( $self, @args ) = @_;
    return $self->_kea_add_item( 'peer', @args );
}

sub add_reservation {
    my ( $self, @args ) = @_;
    return $self->_kea_add_item( 'reservation', @args );
}

sub add_subnet {
    my ( $self, @args ) = @_;
    return $self->_kea_add_item( 'subnet', @args );
}

sub del_option {
    my ( $self, @args ) = @_;
    return $self->_kea_del_item( 'option', @args );
}

sub del_peer {
    my ( $self, @args ) = @_;
    return $self->_kea_del_item( 'peer', @args );
}

sub del_reservation {
    my ( $self, @args ) = @_;
    return $self->_kea_del_item( 'reservation', @args );
}

sub del_subnet {
    my ( $self, @args ) = @_;
    return $self->_kea_del_item( 'subnet', @args );
}

sub get_option {
    my ( $self, @args ) = @_;
    return $self->_kea_get_item( 'option', @args );
}

sub get_peer {
    my ( $self, @args ) = @_;
    return $self->_kea_get_item( 'peer', @args );
}

sub get_reservation {
    my ( $self, @args ) = @_;
    return $self->_kea_get_item( 'reservation', @args );
}

sub get_subnet {
    my ( $self, @args ) = @_;
    return $self->_kea_get_item( 'subnet', @args );
}

sub search_option {
    my ( $self, @args ) = @_;
    return $self->_kea_search_item( 'option', @args );
}

sub search_peer {
    my ( $self, @args ) = @_;
    return $self->_kea_search_item( 'peer', @args );
}

sub search_reservation {
    my ( $self, @args ) = @_;
    return $self->_kea_search_item( 'reservation', @args );
}

sub search_subnet {
    my ( $self, @args ) = @_;
    return $self->_kea_search_item( 'subnet', @args );
}

sub set_option {
    my ( $self, @args ) = @_;
    return $self->_kea_set_item( 'option', @args );
}

sub set_peer {
    my ( $self, @args ) = @_;
    return $self->_kea_set_item( 'peer', @args );
}

sub set_reservation {
    my ( $self, @args ) = @_;
    return $self->_kea_set_item( 'reservation', @args );
}

sub set_subnet {
    my ( $self, @args ) = @_;
    return $self->_kea_set_item( 'subnet', @args );
}

sub _kea_item_type {
    my ( $self, $item ) = @_;
    exists $_KEA_UC{$item}
        or croak "Unknown Kea item type '$item'";
    return $_KEA_UC{$item};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Role::KeaItemCrud - Shared CRUD methods for Kea DHCP item types

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Provides shared CRUD methods for Kea DHCP item types (option, peer,
reservation, subnet).  Consuming classes may also use the C<_kea_*_item>
helpers to define additional item types (e.g. C<pd_pool> in DHCPv6).

This role is consumed by L<WebService::OPNsense::Kea::Dhcpv4> and
L<WebService::OPNsense::Kea::Dhcpv6>.

=head1 PROVIDED METHODS

=head2 add_option / add_peer / add_reservation / add_subnet

    my $result = $ctrl->add_option($option_data);

=head2 del_option / del_peer / del_reservation / del_subnet

    my $result = $ctrl->del_option($uuid);

=head2 get_option / get_peer / get_reservation / get_subnet

    my $result = $ctrl->get_option($uuid);

=head2 search_option / search_peer / search_reservation / search_subnet

    my $results = $ctrl->search_option(%params);

=head2 set_option / set_peer / set_reservation / set_subnet

    my $result = $ctrl->set_option($uuid, $option_data);

=head1 HELPERS

These methods are available to consuming classes for defining additional item
types:

=head2 _kea_add_item

    $self->_kea_add_item('pd_pool', $data);

=head2 _kea_del_item

    $self->_kea_del_item('pd_pool', $uuid);

=head2 _kea_get_item

    $self->_kea_get_item('pd_pool', $uuid);

=head2 _kea_search_item

    $self->_kea_search_item('pd_pool', %params);

=head2 _kea_set_item

    $self->_kea_set_item('pd_pool', $uuid, $data);

=head2 client

    my $http_client = $ctrl->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::Kea::Dhcpv4>,
L<WebService::OPNsense::Kea::Dhcpv6>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
