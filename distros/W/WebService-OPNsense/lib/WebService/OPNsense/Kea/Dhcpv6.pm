#!/bin/false
# ABSTRACT: Kea DHCPv6 controller
# PODNAME: WebService::OPNsense::Kea::Dhcpv6
use strictures 2;

package WebService::OPNsense::Kea::Dhcpv6;
$WebService::OPNsense::Kea::Dhcpv6::VERSION = '0.001';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/kea/dhcpv6';
}

with 'WebService::OPNsense::Role::Settings';

sub add_option {
    my ( $self, $option_data ) = @_;
    return $self->client->post( $self->_path('addOption'), $option_data );
}

sub add_pd_pool {
    my ( $self, $pd_pool_data ) = @_;
    return $self->client->post( $self->_path('addPdPool'), $pd_pool_data );
}

sub add_peer {
    my ( $self, $peer_data ) = @_;
    return $self->client->post( $self->_path('addPeer'), $peer_data );
}

sub add_reservation {
    my ( $self, $reservation_data ) = @_;
    return $self->client->post( $self->_path('addReservation'), $reservation_data );
}

sub add_subnet {
    my ( $self, $subnet_data ) = @_;
    return $self->client->post( $self->_path('addSubnet'), $subnet_data );
}

sub del_option {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delOption/{uuid}', uuid => $uuid ) );
}

sub del_pd_pool {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delPdPool/{uuid}', uuid => $uuid ) );
}

sub del_peer {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delPeer/{uuid}', uuid => $uuid ) );
}

sub del_reservation {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delReservation/{uuid}', uuid => $uuid ) );
}

sub del_subnet {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delSubnet/{uuid}', uuid => $uuid ) );
}

sub get_option {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getOption/{uuid}', uuid => $uuid ) );
}

sub get_pd_pool {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getPdPool/{uuid}', uuid => $uuid ) );
}

sub get_peer {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getPeer/{uuid}', uuid => $uuid ) );
}

sub get_reservation {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getReservation/{uuid}', uuid => $uuid ) );
}

sub get_subnet {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getSubnet/{uuid}', uuid => $uuid ) );
}

sub search_option {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchOption'), \%params );
}

sub search_pd_pool {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchPdPool'), \%params );
}

sub search_peer {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchPeer'), \%params );
}

sub search_reservation {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchReservation'), \%params );
}

sub search_subnet {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchSubnet'), \%params );
}

sub set_option {
    my ( $self, $uuid, $option_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setOption/{uuid}', uuid => $uuid ), $option_data );
}

sub set_pd_pool {
    my ( $self, $uuid, $pd_pool_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setPdPool/{uuid}', uuid => $uuid ), $pd_pool_data );
}

sub set_peer {
    my ( $self, $uuid, $peer_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setPeer/{uuid}', uuid => $uuid ), $peer_data );
}

sub set_reservation {
    my ( $self, $uuid, $reservation_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setReservation/{uuid}', uuid => $uuid ), $reservation_data );
}

sub set_subnet {
    my ( $self, $uuid, $subnet_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setSubnet/{uuid}', uuid => $uuid ), $subnet_data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Kea::Dhcpv6 - Kea DHCPv6 controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $dhcpv6 = $opn->kea_dhcpv6;

    my $config = $dhcpv6->get;

    $dhcpv6->set({ ... });

    my $subnets = $dhcpv6->search_subnet(current => 1, rowCount => 50);

=head1 DESCRIPTION

Manages Kea DHCPv6 configuration.

=head1 NAME

WebService::OPNsense::Kea::Dhcpv6 - Kea DHCPv6 controller

=head1 METHODS

=head2 add_option

    my $result = $dhcpv6->add_option($option_data);

=head2 add_pd_pool

    my $result = $dhcpv6->add_pd_pool($pd_pool_data);

=head2 add_peer

    my $result = $dhcpv6->add_peer($peer_data);

=head2 add_reservation

    my $result = $dhcpv6->add_reservation($reservation_data);

=head2 add_subnet

    my $result = $dhcpv6->add_subnet($subnet_data);

=head2 del_option

    my $result = $dhcpv6->del_option($uuid);

=head2 del_pd_pool

    my $result = $dhcpv6->del_pd_pool($uuid);

=head2 del_peer

    my $result = $dhcpv6->del_peer($uuid);

=head2 del_reservation

    my $result = $dhcpv6->del_reservation($uuid);

=head2 del_subnet

    my $result = $dhcpv6->del_subnet($uuid);

=head2 get

    my $config = $dhcpv6->get;

Returns the full Kea DHCPv6 configuration.

=head2 get_option

    my $option = $dhcpv6->get_option($uuid);

=head2 get_pd_pool

    my $pd_pool = $dhcpv6->get_pd_pool($uuid);

=head2 get_peer

    my $peer = $dhcpv6->get_peer($uuid);

=head2 get_reservation

    my $reservation = $dhcpv6->get_reservation($uuid);

=head2 get_subnet

    my $subnet = $dhcpv6->get_subnet($uuid);

=head2 search_option

    my $results = $dhcpv6->search_option(%params);

=head2 search_pd_pool

    my $results = $dhcpv6->search_pd_pool(%params);

=head2 search_peer

    my $results = $dhcpv6->search_peer(%params);

=head2 search_reservation

    my $results = $dhcpv6->search_reservation(%params);

=head2 search_subnet

    my $results = $dhcpv6->search_subnet(%params);

=head2 set_settings

    my $result = $dhcpv6->set_settings($config_data);

Updates the Kea DHCPv6 configuration.

=head2 set_option

    my $result = $dhcpv6->set_option($uuid, $option_data);

=head2 set_pd_pool

    my $result = $dhcpv6->set_pd_pool($uuid, $pd_pool_data);

=head2 set_peer

    my $result = $dhcpv6->set_peer($uuid, $peer_data);

=head2 set_reservation

    my $result = $dhcpv6->set_reservation($uuid, $reservation_data);

=head2 set_subnet

    my $result = $dhcpv6->set_subnet($uuid, $subnet_data);

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
