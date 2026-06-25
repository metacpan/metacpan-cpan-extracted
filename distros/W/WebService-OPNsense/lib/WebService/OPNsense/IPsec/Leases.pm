#!/bin/false
# ABSTRACT: IPsec lease controller
# PODNAME: WebService::OPNsense::IPsec::Leases
use strictures 2;

package WebService::OPNsense::IPsec::Leases;
$WebService::OPNsense::IPsec::Leases::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub pools {
    my ($self) = @_;
    return $self->client->get('/api/ipsec/leases/pools');
}

sub search {
    my ( $self, %params ) = @_;
    return $self->client->get( '/api/ipsec/leases/search', \%params );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::Leases - IPsec lease controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $leases = $opn->ipsec_leases;

    my $pools = $leases->pools;
    my $results = $leases->search;

=head1 DESCRIPTION

Queries IPsec leases.

=head1 NAME

WebService::OPNsense::IPsec::Leases - IPsec lease controller

=head1 METHODS

=head2 pools

    my $pools = $leases->pools;

Returns the list of available IPsec pools for lease assignment.

=head2 search

    my $results = $leases->search(%params);

Searches for IPsec leases.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
