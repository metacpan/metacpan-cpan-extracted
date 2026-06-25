#!/bin/false
# ABSTRACT: OpenVPN service controller
# PODNAME: WebService::OPNsense::OpenVPN::Service
use strictures 2;

package WebService::OPNsense::OpenVPN::Service;
$WebService::OPNsense::OpenVPN::Service::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub search_sessions {
    my ( $self, %params ) = @_;
    return $self->client->get( '/api/openvpn/service/searchSessions', \%params );
}

sub search_routes {
    my ( $self, %params ) = @_;
    return $self->client->get( '/api/openvpn/service/searchRoutes', \%params );
}

sub kill_session {
    my ( $self, $session_data ) = @_;
    return $self->client->post( '/api/openvpn/service/killSession', $session_data );
}

sub reconfigure {
    my ($self) = @_;
    return $self->client->post('/api/openvpn/service/reconfigure');
}

sub start_service {
    my ($self) = @_;
    return $self->client->post('/api/openvpn/service/start');
}

sub stop_service {
    my ($self) = @_;
    return $self->client->post('/api/openvpn/service/stop');
}

sub restart_service {
    my ($self) = @_;
    return $self->client->post('/api/openvpn/service/restart');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::OpenVPN::Service - OpenVPN service controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $service = $opn->openvpn_service;

    # Query sessions
    my $sessions = $service->search_sessions(current => 1);

    # Manage service
    $service->restart_service;
    $service->reconfigure;

=head1 DESCRIPTION

Manages the OpenVPN service and queries active sessions
and routes.

=head1 NAME

WebService::OPNsense::OpenVPN::Service - OpenVPN service controller

=head1 METHODS

=head2 search_sessions

    my $results = $service->search_sessions(%params);

Searches for active OpenVPN sessions.

=head2 search_routes

    my $results = $service->search_routes(%params);

Searches for OpenVPN routing table entries.

=head2 kill_session

    my $result = $service->kill_session($session_data);

Kills an active VPN session.

=head2 reconfigure

    my $result = $service->reconfigure;

Reconfigures the OpenVPN service.

=head2 start_service

    my $result = $service->start_service;

Starts the OpenVPN service.

=head2 stop_service

    my $result = $service->stop_service;

Stops the OpenVPN service.

=head2 restart_service

    my $result = $service->restart_service;

Restarts the OpenVPN service.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
