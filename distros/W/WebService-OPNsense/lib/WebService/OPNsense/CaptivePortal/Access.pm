#!/bin/false
# ABSTRACT: Captive portal access controller
# PODNAME: WebService::OPNsense::CaptivePortal::Access
use strictures 2;

package WebService::OPNsense::CaptivePortal::Access;
$WebService::OPNsense::CaptivePortal::Access::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub api {
    my ($self) = @_;
    return $self->client->get('/api/captiveportal/access/api');
}

sub status {
    my ( $self, $zoneid ) = @_;
    my $path = '/api/captiveportal/access/status';
    $path .= "/$zoneid" if defined $zoneid;
    return $self->client->get($path);
}

sub logon {
    my ( $self, $zoneid ) = @_;
    my $path = '/api/captiveportal/access/logon';
    $path .= "/$zoneid" if defined $zoneid;
    return $self->client->post($path);
}

sub logoff {
    my ( $self, $zoneid ) = @_;
    my $path = '/api/captiveportal/access/logoff';
    $path .= "/$zoneid" if defined $zoneid;
    return $self->client->post($path);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::CaptivePortal::Access - Captive portal access controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $cp_access = $opn->captiveportal_access;

    my $status = $cp_access->status;

=head1 DESCRIPTION

Manages captive portal access control.

=head1 NAME

WebService::OPNsense::CaptivePortal::Access - Captive portal access controller

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

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
