#!/bin/false
# ABSTRACT: Kea leases controller
# PODNAME: WebService::OPNsense::Kea::Leases
use strictures 2;

package WebService::OPNsense::Kea::Leases;
$WebService::OPNsense::Kea::Leases::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub del_lease {
    my ( $self, $ips ) = @_;
    my $path = '/api/kea/leases/delLease';
    $path .= "/$ips" if defined $ips;
    return $self->client->post($path);
}

sub search {
    my ( $self, %params ) = @_;
    return $self->client->get( '/api/kea/leases/search', \%params );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Kea::Leases - Kea leases controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $leases = $opn->kea_leases;

    my $results = $leases->search(current => 1, rowCount => 50);

    $leases->del_lease;
    $leases->del_lease('192.0.2.10');

=head1 DESCRIPTION

Manages Kea DHCP leases.

=head1 NAME

WebService::OPNsense::Kea::Leases - Kea leases controller

=head1 METHODS

=head2 del_lease

    my $result = $leases->del_lease;
    my $result = $leases->del_lease($ips);

Deletes one or more leases.  C<$ips> is an optional IP address or
comma-separated list of IPs.

=head2 search

    my $results = $leases->search(%params);

Searches for DHCP leases.  Returns the raw API response hashref.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
