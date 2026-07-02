#!/bin/false
# ABSTRACT: Captive portal settings controller
# PODNAME: WebService::OPNsense::CaptivePortal::Settings
use strictures 2;

package WebService::OPNsense::CaptivePortal::Settings;
$WebService::OPNsense::CaptivePortal::Settings::VERSION = '0.003';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/captiveportal/settings';
}

with 'WebService::OPNsense::Role::Settings';

sub add_zone {
    my ( $self, $zone_data ) = @_;
    my $uri = $self->_path('addZone');

    return $self->client->post( $uri, $zone_data );
}

sub del_zone {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'delZone/{uuid}', uuid => $uuid );

    return $self->client->post($uri);
}

sub get_zone {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'getZone/{uuid}', uuid => $uuid );

    return $self->client->get($uri);
}

sub search_zones {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('search_zones');

    return $self->client->get( $uri, \%params );
}

sub set_zone {
    my ( $self, $uuid, $zone_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'setZone/{uuid}', uuid => $uuid );

    return $self->client->post( $uri, $zone_data );
}

sub toggle_zone {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'toggleZone/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled );

    return $self->client->post(
        $uri,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::CaptivePortal::Settings - Captive portal settings controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $cp_settings = $opn->captive_portal_settings;

    my $settings = $cp_settings->get_settings;

=head1 DESCRIPTION

Manages captive portal settings and zones.

=head1 METHODS

=head2 add_zone

    my $result = $cp_settings->add_zone($zone_data);

Creates captive portal zone.

=head2 client

    my $http_client = $cp_settings->client;

Returns the underlying HTTP client object used for API requests.

=head2 del_zone

    my $result = $cp_settings->del_zone($uuid);

Deletes a zone by UUID.

=head2 get_settings

    my $settings = $cp_settings->get_settings;

Returns captive portal settings.

=head2 get_zone

    my $zone = $cp_settings->get_zone($uuid);

Returns a single zone by UUID.

=head2 search_zones

    my $zones = $cp_settings->search_zones(%params);

Searches for captive portal zones.

=head2 set_settings

    my $result = $cp_settings->set_settings($settings_data);

Updates captive portal settings.

=head2 set_zone

    my $result = $cp_settings->set_zone($uuid, $zone_data);

Updates zone.

=head2 toggle_zone

    my $result = $cp_settings->toggle_zone($uuid, $enabled);

Enables or disables a zone.

=head1 SEE ALSO

L<WebService::OPNsense::Role::Settings>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
