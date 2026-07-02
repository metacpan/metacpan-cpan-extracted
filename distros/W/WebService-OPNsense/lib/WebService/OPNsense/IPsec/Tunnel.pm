#!/bin/false
# ABSTRACT: IPsec tunnel status controller
# PODNAME: WebService::OPNsense::IPsec::Tunnel
use strictures 2;

package WebService::OPNsense::IPsec::Tunnel;
$WebService::OPNsense::IPsec::Tunnel::VERSION = '0.003';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ipsec/tunnel';
}

with 'WebService::OPNsense::Role::APIPath';

sub search_phase1 {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('searchPhase1');

    return $self->client->get( $uri, \%params );
}

sub search_phase2 {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('searchPhase2');

    return $self->client->get( $uri, \%params );
}

sub toggle {
    my ( $self, $enabled ) = @_;
    my $path = $self->_path( 'toggle{/enabled}', enabled => $enabled );
    return $self->client->post($path);
}

sub toggle_phase1 {
    my ( $self, $ikeid ) = @_;
    my $uri = $self->_path( 'togglePhase1/{ikeid}', ikeid => $ikeid );

    return $self->client->post($uri);
}

sub toggle_phase2 {
    my ( $self, $seqid ) = @_;
    my $uri = $self->_path( 'togglePhase2/{seqid}', seqid => $seqid );

    return $self->client->post($uri);
}

sub del_phase1 {
    my ( $self, $ikeid ) = @_;
    my $uri = $self->_path( 'delPhase1/{ikeid}', ikeid => $ikeid );

    return $self->client->post($uri);
}

sub del_phase2 {
    my ( $self, $seqid ) = @_;
    my $uri = $self->_path( 'delPhase2/{seqid}', seqid => $seqid );

    return $self->client->post($uri);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::Tunnel - IPsec tunnel status controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $tunnel = $opn->ipsec_tunnel;

    my $phase1 = $tunnel->search_phase1;
    $tunnel->toggle_phase1($ikeid);
    $tunnel->del_phase2($seqid);

=head1 DESCRIPTION

Queries and manages IPsec tunnel status

=head1 METHODS

=head2 search_phase1

    my $results = $tunnel->search_phase1(%params);

Searches for phase 1 tunnels.

=head2 search_phase2

    my $results = $tunnel->search_phase2(%params);

Searches for phase 2 tunnels.

=head2 toggle

    my $result = $tunnel->toggle($enabled);

Globally enables or disables IPsec tunnels.

=head2 toggle_phase1

    my $result = $tunnel->toggle_phase1($ikeid);

Toggles a phase 1 tunnel by IKE ID.

=head2 toggle_phase2

    my $result = $tunnel->toggle_phase2($seqid);

Toggles a phase 2 tunnel by sequence ID.

=head2 del_phase1

    my $result = $tunnel->del_phase1($ikeid);

Deletes a phase 1 tunnel by IKE ID.

=head2 del_phase2

    my $result = $tunnel->del_phase2($seqid);

Deletes a phase 2 tunnel by sequence ID.

=head2 client

    my $http_client = $tunnel->client;

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
