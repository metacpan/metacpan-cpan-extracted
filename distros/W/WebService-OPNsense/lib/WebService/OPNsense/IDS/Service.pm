#!/bin/false
# ABSTRACT: IDS service controller
# PODNAME: WebService::OPNsense::IDS::Service
use strictures 2;

package WebService::OPNsense::IDS::Service;
$WebService::OPNsense::IDS::Service::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ids/service';
}

with 'WebService::OPNsense::Role::Service';

sub reload_rules {
    my ($self) = @_;
    return $self->client->post( $self->_path('reloadRules') );
}

sub update_rules {
    my ( $self, $wait ) = @_;
    return $self->client->post( $self->_path( 'updateRules{/wait}', wait => $wait ) );
}

sub query_alerts {
    my ( $self, %params ) = @_;
    return $self->client->post( $self->_path('queryAlerts'), \%params );
}

sub get_alert_logs {
    my ($self) = @_;
    return $self->client->get( $self->_path('getAlertLogs') );
}

sub get_alert_info {
    my ( $self, $alert_id ) = @_;
    return $self->client->get( $self->_path( 'getAlertInfo/{alert_id}', alert_id => $alert_id ) );
}

sub drop_alert_log {
    my ($self) = @_;
    return $self->client->post( $self->_path('dropAlertLog') );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IDS::Service - IDS service controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $ids_service = $opn->ids_service;

    my $status = $ids_service->status;

=head1 DESCRIPTION

Controls the IDS/IPS service, alerts, and rule
updates.

=head1 NAME

WebService::OPNsense::IDS::Service - IDS service controller

=head1 METHODS

=head2 status

    my $status = $ids_service->status;

Returns the current IDS service status.

=head2 start

    my $result = $ids_service->start;

Starts the IDS service.

=head2 stop

    my $result = $ids_service->stop;

Stops the IDS service.

=head2 restart

    my $result = $ids_service->restart;

Restarts the IDS service.

=head2 reconfigure

    my $result = $ids_service->reconfigure;

Reconfigures the IDS service.

=head2 reload_rules

    my $result = $ids_service->reload_rules;

Reloads IDS rules.

=head2 update_rules

    my $result = $ids_service->update_rules;
    my $result = $ids_service->update_rules($wait);

Updates IDS rules.  Optionally wait for completion.

=head2 query_alerts

    my $alerts = $ids_service->query_alerts(%params);

Queries IDS alerts.

=head2 get_alert_logs

    my $logs = $ids_service->get_alert_logs;

Returns alert logs.

=head2 get_alert_info

    my $info = $ids_service->get_alert_info($alert_id);

Returns information about a specific alert.

=head2 drop_alert_log

    my $result = $ids_service->drop_alert_log;

Drops (clears) the alert log.

=for Pod::Coverage _api_path _path client status start stop restart reconfigure

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
