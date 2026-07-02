#!/bin/false
# ABSTRACT: IPsec lease controller
# PODNAME: WebService::OPNsense::IPsec::Leases
use strictures 2;

package WebService::OPNsense::IPsec::Leases;
$WebService::OPNsense::IPsec::Leases::VERSION = '0.003';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ipsec/leases';
}

with 'WebService::OPNsense::Role::APIPath';

sub pools {
    my ($self) = @_;
    my $uri = $self->_path('pools');
    return $self->client->get($uri);
}

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

WebService::OPNsense::IPsec::Leases - IPsec lease controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $leases = $opn->ipsec_leases;

    my $pools = $leases->pools;
    my $results = $leases->search;

=head1 DESCRIPTION

Queries IPsec leases.

=head1 METHODS

=head2 pools

    my $pools = $leases->pools;

Returns the list of available IPsec pools for lease assignment.

=head2 search

    my $results = $leases->search(%params);

Searches for IPsec leases.

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
