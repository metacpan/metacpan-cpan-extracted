#!/bin/false
# ABSTRACT: IPsec session controller
# PODNAME: WebService::OPNsense::IPsec::Sessions
use strictures 2;

package WebService::OPNsense::IPsec::Sessions;
$WebService::OPNsense::IPsec::Sessions::VERSION = '0.003';
use Carp qw( croak );
use Moo;
use namespace::clean;    # must be last

has client => ( is => 'ro', required => 1 );

sub _require_id {
    my ( $self, $id ) = @_;
    if ( !defined($id) || !length($id) ) {
        croak 'Session ID is required';
    }
    return $id;
}

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
    my $uri = "/api/ipsec/sessions/connect/$id";
    $self->_require_id($id);
    return $self->client->post($uri);
}

sub disconnect {
    my ( $self, $id ) = @_;
    my $uri = "/api/ipsec/sessions/disconnect/$id";
    $self->_require_id($id);
    return $self->client->post($uri);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::Sessions - IPsec session controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $sessions = $opn->ipsec_sessions;

    my $phase1 = $sessions->search_phase1;
    $sessions->connect_session($id);

=head1 DESCRIPTION

Queries and manages IPsec sessions

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

=head2 client

    my $http_client = $sessions->client;

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
