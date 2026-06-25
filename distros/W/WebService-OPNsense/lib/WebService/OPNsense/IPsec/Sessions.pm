#!/bin/false
# ABSTRACT: IPsec session controller
# PODNAME: WebService::OPNsense::IPsec::Sessions
use strictures 2;

package WebService::OPNsense::IPsec::Sessions;
$WebService::OPNsense::IPsec::Sessions::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub search_phase1 {
    my ( $self, %params ) = @_;
    return $self->client->get( '/api/ipsec/sessions/searchPhase1', \%params );
}

sub search_phase2 {
    my ( $self, %params ) = @_;
    return $self->client->get( '/api/ipsec/sessions/searchPhase2', \%params );
}

sub connect_session {
    my ( $self, $id ) = @_;
    return $self->client->post("/api/ipsec/sessions/connect/$id");
}

sub disconnect {
    my ( $self, $id ) = @_;
    return $self->client->post("/api/ipsec/sessions/disconnect/$id");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::Sessions - IPsec session controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $sessions = $opn->ipsec_sessions;

    my $phase1 = $sessions->search_phase1;
    $sessions->connect($id);

=head1 DESCRIPTION

Queries and manages IPsec sessions

=head1 NAME

WebService::OPNsense::IPsec::Sessions - IPsec session controller

=head1 METHODS

=head2 search_phase1

    my $results = $sessions->search_phase1(%params);

Searches for phase 1 sessions.

=head2 search_phase2

    my $results = $sessions->search_phase2(%params);

Searches for phase 2 sessions.

=head2 connect_session

    my $result = $sessions->connect_session($id);

Connects an IPsec session by ID.

=head2 disconnect

    my $result = $sessions->disconnect($id);

Disconnects an IPsec session by ID.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
