#!/bin/false
# ABSTRACT: IPsec Security Policy Database (SPD) controller
# PODNAME: WebService::OPNsense::IPsec::Spd
use strictures 2;

package WebService::OPNsense::IPsec::Spd;
$WebService::OPNsense::IPsec::Spd::VERSION = '0.003';
use Carp qw( croak );
use Moo;
use namespace::clean;    # must be last

has client => ( is => 'ro', required => 1 );

sub _require_id {
    my ( $self, $id ) = @_;
    if ( !defined($id) || !length($id) ) {
        croak 'SPD entry ID is required';
    }
    return $id;
}

sub search {
    my ( $self, %params ) = @_;
    return $self->client->get( '/api/ipsec/spd/search', \%params );
}

sub delete_entry {
    my ( $self, $id ) = @_;
    $self->_require_id($id);
    return $self->client->post("/api/ipsec/spd/delete/$id");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::Spd - IPsec Security Policy Database (SPD) controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $spd = $opn->ipsec_spd;

    my $entries = $spd->search;
    $spd->delete_entry($id);

=head1 DESCRIPTION

Queries and manages the IPsec Security Policy Database
(SPD).

=head1 METHODS

=head2 search

    my $results = $spd->search(%params);

Searches for SPD entries.

=head2 delete_entry

    my $result = $spd->delete_entry($id);

Deletes an SPD entry by ID.

=head2 client

    my $http_client = $spd->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
