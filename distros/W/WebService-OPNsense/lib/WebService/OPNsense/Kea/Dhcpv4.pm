#!/bin/false
# ABSTRACT: Kea DHCPv4 controller
# PODNAME: WebService::OPNsense::Kea::Dhcpv4
use strictures 2;

package WebService::OPNsense::Kea::Dhcpv4;
$WebService::OPNsense::Kea::Dhcpv4::VERSION = '0.001';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/kea/dhcpv4';
}

with 'WebService::OPNsense::Role::Settings';

sub add_option {
    my ( $self, $option_data ) = @_;
    return $self->client->post( $self->_path('addOption'), $option_data );
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

sub download_reservations {
    my ($self) = @_;
    return $self->client->get( $self->_path('downloadReservations') );
}

sub get_option {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getOption/{uuid}', uuid => $uuid ) );
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

sub upload_reservations {
    my ( $self, $reservations_data ) = @_;
    return $self->client->post( $self->_path('uploadReservations'), $reservations_data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Kea::Dhcpv4 - Kea DHCPv4 controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $dhcpv4 = $opn->kea_dhcpv4;

    my $config = $dhcpv4->get;

    $dhcpv4->set({ ... });

    my $subnets = $dhcpv4->search_subnet(current => 1, rowCount => 50);

=head1 DESCRIPTION

Manages Kea DHCPv4 configuration.

=head1 NAME

WebService::OPNsense::Kea::Dhcpv4 - Kea DHCPv4 controller

=head1 METHODS

=head2 add_option

    my $result = $dhcpv4->add_option($option_data);

=head2 add_peer

    my $result = $dhcpv4->add_peer($peer_data);

=head2 add_reservation

    my $result = $dhcpv4->add_reservation($reservation_data);

=head2 add_subnet

    my $result = $dhcpv4->add_subnet($subnet_data);

=head2 del_option

    my $result = $dhcpv4->del_option($uuid);

=head2 del_peer

    my $result = $dhcpv4->del_peer($uuid);

=head2 del_reservation

    my $result = $dhcpv4->del_reservation($uuid);

=head2 del_subnet

    my $result = $dhcpv4->del_subnet($uuid);

=head2 download_reservations

    my $reservations = $dhcpv4->download_reservations;

=head2 get

    my $config = $dhcpv4->get;

Returns the full Kea DHCPv4 configuration.

=head2 get_option

    my $option = $dhcpv4->get_option($uuid);

=head2 get_peer

    my $peer = $dhcpv4->get_peer($uuid);

=head2 get_reservation

    my $reservation = $dhcpv4->get_reservation($uuid);

=head2 get_subnet

    my $subnet = $dhcpv4->get_subnet($uuid);

=head2 search_option

    my $results = $dhcpv4->search_option(%params);

=head2 search_peer

    my $results = $dhcpv4->search_peer(%params);

=head2 search_reservation

    my $results = $dhcpv4->search_reservation(%params);

=head2 search_subnet

    my $results = $dhcpv4->search_subnet(%params);

=head2 set_settings

    my $result = $dhcpv4->set_settings($config_data);

Updates the Kea DHCPv4 configuration.

=head2 set_option

    my $result = $dhcpv4->set_option($uuid, $option_data);

=head2 set_peer

    my $result = $dhcpv4->set_peer($uuid, $peer_data);

=head2 set_reservation

    my $result = $dhcpv4->set_reservation($uuid, $reservation_data);

=head2 set_subnet

    my $result = $dhcpv4->set_subnet($uuid, $subnet_data);

=head2 upload_reservations

    my $result = $dhcpv4->upload_reservations($reservations_data);

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
