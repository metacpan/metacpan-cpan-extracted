#!/bin/false
# ABSTRACT: Captive portal service controller
# PODNAME: WebService::OPNsense::CaptivePortal::Service
use strictures 2;

package WebService::OPNsense::CaptivePortal::Service;
$WebService::OPNsense::CaptivePortal::Service::VERSION = '0.001';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/captiveportal/service';
}

with 'WebService::OPNsense::Role::Service';

sub search_templates {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchTemplate'), \%params );
}

sub get_template {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getTemplate/{uuid}', uuid => $uuid ) );
}

sub save_template {
    my ( $self, $uuid, $template_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post(
        $self->_path( 'setTemplate/{uuid}', uuid => $uuid ), $template_data,
    );
}

sub del_template {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delTemplate/{uuid}', uuid => $uuid ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::CaptivePortal::Service - Captive portal service controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $cp_service = $opn->captiveportal_service;

    my $status = $cp_service->status;

=head1 DESCRIPTION

Controls the captive portal service and manages
templates.

=head1 NAME

WebService::OPNsense::CaptivePortal::Service - Captive portal service controller

=head1 METHODS

=head2 status

    my $status = $cp_service->status;

Returns the current service status.

=head2 start

    my $result = $cp_service->start;

Starts the captive portal service.

=head2 stop

    my $result = $cp_service->stop;

Stops the captive portal service.

=head2 restart

    my $result = $cp_service->restart;

Restarts the captive portal service.

=head2 reconfigure

    my $result = $cp_service->reconfigure;

Reconfigures the captive portal service.

=head2 search_templates

    my $templates = $cp_service->search_templates(%params);

Searches for captive portal templates.

=head2 get_template

    my $template = $cp_service->get_template($uuid);

Returns a single template by UUID.

=head2 save_template

    my $result = $cp_service->save_template($uuid, $template_data);

Updates a template.

=head2 del_template

    my $result = $cp_service->del_template($uuid);

Deletes a template by UUID.

=for Pod::Coverage _api_path _path client status start stop restart reconfigure

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
