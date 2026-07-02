#!/bin/false
# ABSTRACT: Captive portal access controller
# PODNAME: WebService::OPNsense::CaptivePortal::Access
use strictures 2;

package WebService::OPNsense::CaptivePortal::Access;
$WebService::OPNsense::CaptivePortal::Access::VERSION = '0.003';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/captiveportal/access';
}

with 'WebService::OPNsense::Role::APIPath';

sub api {
    my ($self) = @_;
    my $uri = $self->_path('api');
    return $self->client->get($uri);
}

sub status {
    my ( $self, $zoneid ) = @_;
    my $uri = $self->_path( 'status{/zoneid}', zoneid => $zoneid );
    return $self->client->get($uri);
}

sub logon {
    my ( $self, $zoneid ) = @_;
    my $uri = $self->_path( 'logon{/zoneid}', zoneid => $zoneid );
    return $self->client->post($uri);
}

sub logoff {
    my ( $self, $zoneid ) = @_;
    my $uri = $self->_path( 'logoff{/zoneid}', zoneid => $zoneid );
    return $self->client->post($uri);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::CaptivePortal::Access - Captive portal access controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $cp_access = $opn->captiveportal_access;

    my $status = $cp_access->status;

=head1 DESCRIPTION

Manages captive portal access control.

=head1 METHODS

=head2 api

    my $api_info = $cp_access->api;

Returns API information for the captive portal access endpoint.

=head2 status

    my $status = $cp_access->status;
    my $status = $cp_access->status($zoneid);

Returns captive portal status, optionally filtered by zone ID.

=head2 logon

    my $result = $cp_access->logon;
    my $result = $cp_access->logon($zoneid);

Logs on a captive portal session.  Optionally specify a zone ID.

=head2 logoff

    my $result = $cp_access->logoff;
    my $result = $cp_access->logoff($zoneid);

Logs off a captive portal session.  Optionally specify a zone ID.

=head2 client

    my $http_client = $cp_access->client;

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
