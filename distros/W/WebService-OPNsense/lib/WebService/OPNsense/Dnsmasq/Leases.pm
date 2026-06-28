#!/bin/false
# ABSTRACT: Dnsmasq leases controller
# PODNAME: WebService::OPNsense::Dnsmasq::Leases
use strictures 2;

package WebService::OPNsense::Dnsmasq::Leases;
$WebService::OPNsense::Dnsmasq::Leases::VERSION = '0.002';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/dnsmasq/leases';
}

with 'WebService::OPNsense::Role::APIPath';

sub search {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('search');
    return $self->client->get( $uri, \%params );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Dnsmasq::Leases - Dnsmasq leases controller

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $leases = $opn->dnsmasq_leases;

    my $results = $leases->search(current => 1, rowCount => 50);

=head1 DESCRIPTION

Queries Dnsmasq DHCP leases.

=head1 METHODS

=head2 search

    my $results = $leases->search(%params);

Searches for DHCP leases.  Parameters: C<current>, C<rowCount>, C<searchPhrase>.

=head2 client

    my $http_client = $leases->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::Role::APIPath>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
