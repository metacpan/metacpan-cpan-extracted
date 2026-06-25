#!/bin/false
# ABSTRACT: Captive portal settings controller
# PODNAME: WebService::OPNsense::CaptivePortal::Settings
use strictures 2;

package WebService::OPNsense::CaptivePortal::Settings;
$WebService::OPNsense::CaptivePortal::Settings::VERSION = '0.001';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/captiveportal/settings';
}

with 'WebService::OPNsense::Role::Settings';

sub search_zones {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchZone'), \%params );
}

sub get_zone {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getZone/{uuid}', uuid => $uuid ) );
}

sub add_zone {
    my ( $self, $zone_data ) = @_;
    return $self->client->post( $self->_path('addZone'), $zone_data );
}

sub set_zone {
    my ( $self, $uuid, $zone_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setZone/{uuid}', uuid => $uuid ), $zone_data );
}

sub del_zone {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delZone/{uuid}', uuid => $uuid ) );
}

sub toggle_zone {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    return $self->client->post(
        $self->_path( 'toggleZone/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled ),
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::CaptivePortal::Settings - Captive portal settings controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $cp_settings = $opn->captiveportal_settings;

    my $settings = $cp_settings->get;

=head1 DESCRIPTION

Manages captive portal settings and zones.

=head1 NAME

WebService::OPNsense::CaptivePortal::Settings - Captive portal settings controller

=head1 METHODS

=head2 get

    my $settings = $cp_settings->get;

Returns the current captive portal settings.

=head2 set_settings

    my $result = $cp_settings->set_settings($settings_data);

Updates captive portal settings.

=head2 search_zones

    my $zones = $cp_settings->search_zones(%params);

Searches for captive portal zones.

=head2 get_zone

    my $zone = $cp_settings->get_zone($uuid);

Returns a single zone by UUID.

=head2 add_zone

    my $result = $cp_settings->add_zone($zone_data);

Creates a new captive portal zone.

=head2 set_zone

    my $result = $cp_settings->set_zone($uuid, $zone_data);

Updates an existing zone.

=head2 del_zone

    my $result = $cp_settings->del_zone($uuid);

Deletes a zone by UUID.

=head2 toggle_zone

    my $result = $cp_settings->toggle_zone($uuid, $enabled);

Enables or disables a zone.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
