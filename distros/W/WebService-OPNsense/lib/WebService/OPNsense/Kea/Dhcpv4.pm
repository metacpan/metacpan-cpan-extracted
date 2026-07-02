#!/bin/false
# ABSTRACT: Kea DHCPv4 controller
# PODNAME: WebService::OPNsense::Kea::Dhcpv4
use strictures 2;

package WebService::OPNsense::Kea::Dhcpv4;
$WebService::OPNsense::Kea::Dhcpv4::VERSION = '0.003';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/kea/dhcpv4';
}

with 'WebService::OPNsense::Role::Settings';
with 'WebService::OPNsense::Role::KeaItemCrud';

sub download_reservations {
    my ($self) = @_;
    my $uri = $self->_path('downloadReservations');

    return $self->client->get($uri);
}

sub upload_reservations {
    my ( $self, $reservations_data ) = @_;
    my $uri = $self->_path('uploadReservations');

    return $self->client->post( $uri, $reservations_data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Kea::Dhcpv4 - Kea DHCPv4 controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $dhcpv4 = $opn->kea_dhcpv4;

    my $config = $dhcpv4->get;

    $dhcpv4->set_settings({ ... });

    my $subnets = $dhcpv4->search_subnet(current => 1, rowCount => 50);

=head1 DESCRIPTION

Manages Kea DHCPv4 configuration.

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

    my $config = $dhcpv4->get_settings;

Returns the full Kea DHCPv4 configuration.

=head2 set_settings

    my $result = $dhcpv4->set_settings($config_data);

Updates the Kea DHCPv4 configuration.

=head2 download_reservations

    my $reservations = $dhcpv4->download_reservations;

=head2 upload_reservations

    my $result = $dhcpv4->upload_reservations($reservations_data);

=head2 client

    my $http_client = $dhcpv4->client;

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
