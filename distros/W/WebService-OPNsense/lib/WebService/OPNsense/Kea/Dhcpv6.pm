#!/bin/false
# ABSTRACT: Kea DHCPv6 controller
# PODNAME: WebService::OPNsense::Kea::Dhcpv6
use strictures 2;

package WebService::OPNsense::Kea::Dhcpv6;
$WebService::OPNsense::Kea::Dhcpv6::VERSION = '0.003';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/kea/dhcpv6';
}

with 'WebService::OPNsense::Role::Settings';
with 'WebService::OPNsense::Role::KeaItemCrud';

sub add_pd_pool {
    my ( $self, $pd_pool_data ) = @_;
    return $self->_kea_add_item( 'pd_pool', $pd_pool_data );
}

sub del_pd_pool {
    my ( $self, $uuid ) = @_;
    return $self->_kea_del_item( 'pd_pool', $uuid );
}

sub get_pd_pool {
    my ( $self, $uuid ) = @_;
    return $self->_kea_get_item( 'pd_pool', $uuid );
}

sub search_pd_pool {
    my ( $self, %params ) = @_;
    return $self->_kea_search_item( 'pd_pool', %params );
}

sub set_pd_pool {
    my ( $self, $uuid, $pd_pool_data ) = @_;
    return $self->_kea_set_item( 'pd_pool', $uuid, $pd_pool_data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Kea::Dhcpv6 - Kea DHCPv6 controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $dhcpv6 = $opn->kea_dhcpv6;

    my $config = $dhcpv6->get;

    $dhcpv6->set_settings({ ... });

    my $subnets = $dhcpv6->search_subnet(current => 1, rowCount => 50);

=head1 DESCRIPTION

Manages Kea DHCPv6 configuration.

=head1 METHODS

Provides all methods from L<WebService::OPNsense::Role::KeaItemCrud> for
managing option, peer, reservation, and subnet items:

    add_option  del_option  get_option  search_option  set_option
    add_peer    del_peer    get_peer    search_peer     set_peer
    add_reservation  del_reservation  get_reservation
    search_reservation  set_reservation
    add_subnet  del_subnet  get_subnet  search_subnet   set_subnet

Provides methods from L<WebService::OPNsense::Role::Settings>:

=head2 get_settings

    my $config = $dhcpv6->get_settings;

Returns the full Kea DHCPv6 configuration.

=head2 set_settings

    my $result = $dhcpv6->set_settings($config_data);

Updates the Kea DHCPv6 configuration.

=head2 add_pd_pool

    my $result = $dhcpv6->add_pd_pool($pd_pool_data);

=head2 del_pd_pool

    my $result = $dhcpv6->del_pd_pool($uuid);

=head2 get_pd_pool

    my $pd_pool = $dhcpv6->get_pd_pool($uuid);

=head2 search_pd_pool

    my $results = $dhcpv6->search_pd_pool(%params);

=head2 set_pd_pool

    my $result = $dhcpv6->set_pd_pool($uuid, $pd_pool_data);

=head2 client

    my $http_client = $dhcpv6->client;

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
