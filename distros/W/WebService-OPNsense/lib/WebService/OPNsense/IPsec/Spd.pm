#!/bin/false
# ABSTRACT: IPsec Security Policy Database (SPD) controller
# PODNAME: WebService::OPNsense::IPsec::Spd
use strictures 2;

package WebService::OPNsense::IPsec::Spd;
$WebService::OPNsense::IPsec::Spd::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub search {
    my ( $self, %params ) = @_;
    return $self->client->get( '/api/ipsec/spd/search', \%params );
}

sub delete_entry {
    my ( $self, $id ) = @_;
    return $self->client->post("/api/ipsec/spd/delete/$id");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::Spd - IPsec Security Policy Database (SPD) controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $spd = $opn->ipsec_spd;

    my $entries = $spd->search;
    $spd->delete($id);

=head1 DESCRIPTION

Queries and manages the IPsec Security Policy Database
(SPD).

=head1 NAME

WebService::OPNsense::IPsec::Spd - IPsec Security Policy Database (SPD) controller

=head1 METHODS

=head2 search

    my $results = $spd->search(%params);

Searches for SPD entries.

=head2 delete_entry

    my $result = $spd->delete_entry($id);

Deletes an SPD entry by ID.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
