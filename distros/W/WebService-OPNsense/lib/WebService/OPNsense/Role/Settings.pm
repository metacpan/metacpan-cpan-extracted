#!/bin/false
# ABSTRACT: Role for settings get/set methods
# PODNAME: WebService::OPNsense::Role::Settings
use strictures 2;

package WebService::OPNsense::Role::Settings;
$WebService::OPNsense::Role::Settings::VERSION = '0.002';
use Moo::Role;
use namespace::clean;

with 'WebService::OPNsense::Role::APIPath';

sub get_settings {
    my ($self) = @_;
    my $uri = $self->_path('get');

    return $self->client->get($uri);
}

sub set_settings {
    my ( $self, $settings_data ) = @_;
    my $uri = $self->_path('set');

    return $self->client->post( $uri, $settings_data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Role::Settings - Role for settings get/set methods

=head1 VERSION

version 0.002

=head1 DESCRIPTION

Provides shared get/set methods for controller settings.  All methods in
this section are called on the consuming object, not on the role directly.

This role is consumed by L<WebService::OPNsense::CaptivePortal::Settings>,
L<WebService::OPNsense::Cron::Settings>,
L<WebService::OPNsense::Dnsmasq::Settings>,
L<WebService::OPNsense::IDS::Settings>,
L<WebService::OPNsense::IPsec::Connections>,
L<WebService::OPNsense::IPsec::KeyPairs>,
L<WebService::OPNsense::IPsec::PreSharedKeys>,
L<WebService::OPNsense::IPsec::Settings>,
L<WebService::OPNsense::Kea::CtrlAgent>,
L<WebService::OPNsense::Kea::Ddns>,
L<WebService::OPNsense::Kea::Dhcpv4>,
L<WebService::OPNsense::Kea::Dhcpv6>,
L<WebService::OPNsense::TrafficShaper::Settings>, and
L<WebService::OPNsense::Unbound::Settings>.

=head1 PROVIDED METHODS

=head2 get_settings

    my $config = $ctrl->get_settings;

Returns settings.

=head2 set_settings

    my $result = $ctrl->set_settings( $settings_data );

Updates the settings.

=head2 client

    my $http_client = $ctrl->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::CaptivePortal::Settings>,
L<WebService::OPNsense::Cron::Settings>,
L<WebService::OPNsense::Dnsmasq::Settings>,
L<WebService::OPNsense::IDS::Settings>,
L<WebService::OPNsense::IPsec::Connections>,
L<WebService::OPNsense::IPsec::KeyPairs>,
L<WebService::OPNsense::IPsec::PreSharedKeys>,
L<WebService::OPNsense::IPsec::Settings>,
L<WebService::OPNsense::Kea::CtrlAgent>,
L<WebService::OPNsense::Kea::Ddns>,
L<WebService::OPNsense::Kea::Dhcpv4>,
L<WebService::OPNsense::Kea::Dhcpv6>,
L<WebService::OPNsense::TrafficShaper::Settings>,
L<WebService::OPNsense::Unbound::Settings>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
