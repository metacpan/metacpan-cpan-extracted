#!/bin/false
# ABSTRACT: High availability sync controller
# PODNAME: WebService::OPNsense::HASync
use strictures 2;

package WebService::OPNsense::HASync;
$WebService::OPNsense::HASync::VERSION = '0.003';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub get {
    my ($self) = @_;
    return $self->client->get('/api/core/hasync/get');
}

sub set_settings {
    my ( $self, $settings_data ) = @_;
    return $self->client->post( '/api/core/hasync/set', $settings_data );
}

sub reconfigure {
    my ($self) = @_;
    return $self->client->post('/api/core/hasync/reconfigure');
}

sub version {
    my ($self) = @_;
    return $self->client->get('/api/core/hasync_status/version');
}

sub services {
    my ($self) = @_;
    return $self->client->get('/api/core/hasync_status/services');
}

sub remote_service {
    my ( $self, $action, $service, $service_id ) = @_;
    return $self->client->get(
        "/api/core/hasync_status/remoteService/$action/$service/$service_id",
    );
}

sub start {
    my ($self) = @_;
    return $self->client->post('/api/core/hasync_status/start');
}

sub stop {
    my ($self) = @_;
    return $self->client->post('/api/core/hasync_status/stop');
}

sub restart {
    my ($self) = @_;
    return $self->client->post('/api/core/hasync_status/restart');
}

sub restart_all {
    my ($self) = @_;
    return $self->client->post('/api/core/hasync_status/restartAll');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::HASync - High availability sync controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $ha = $opn->hasync;

    my $settings = $ha->get;

=head1 DESCRIPTION

High availability synchronization.

=head1 METHODS

=head2 get

    my $settings = $ha->get;

Returns HA sync settings.

=head2 set_settings

    my $result = $ha->set_settings($data);

Updates HA sync settings.

=head2 reconfigure

    my $result = $ha->reconfigure;

Reconfigures HA sync.

=head2 version

    my $version = $ha->version;

Returns the HA sync version.

=head2 services

    my $services = $ha->services;

Lists HA sync services.

=head2 remote_service

    my $result = $ha->remote_service($action, $service, $service_id);

Performs an action on a remote HA service.

=head2 start

    my $result = $ha->start;

Starts HA sync.

=head2 stop

    my $result = $ha->stop;

Stops HA sync.

=head2 restart

    my $result = $ha->restart;

Restarts HA sync.

=head2 restart_all

    my $result = $ha->restart_all;

Restarts all HA sync services.

=head2 client

    my $http_client = $ha->client;

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
