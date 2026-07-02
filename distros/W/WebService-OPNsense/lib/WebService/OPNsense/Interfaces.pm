#!/bin/false
# ABSTRACT: Interfaces API controller
# PODNAME: WebService::OPNsense::Interfaces
use strictures 2;

package WebService::OPNsense::Interfaces;
$WebService::OPNsense::Interfaces::VERSION = '0.003';
use Moo;
use WebService::OPNsense::Normalize qw( optional_segment );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub overview {
    my ($self) = @_;
    return $self->client->get('/api/interfaces/overview/interfacesInfo');
}

sub get_interface {
    my ( $self, $if ) = @_;
    return $self->client->get("/api/interfaces/overview/getInterface/$if");
}

sub export {
    my ($self) = @_;
    return $self->client->get('/api/interfaces/overview/export');
}

sub reload_interface {
    my ( $self, $identifier ) = @_;
    my $path = '/api/interfaces/overview/reloadInterface' . optional_segment($identifier);
    return $self->client->post($path);
}

sub settings_get {
    my ($self) = @_;
    return $self->client->get('/api/interfaces/settings/get');
}

sub settings_set {
    my ( $self, $settings_data ) = @_;
    return $self->client->post( '/api/interfaces/settings/set', $settings_data );
}

sub settings_reconfigure {
    my ($self) = @_;
    return $self->client->post('/api/interfaces/settings/reconfigure');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Interfaces - Interfaces API controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use WebService::OPNsense::Constants qw( $INTERFACE_LAN );

    my $if = $opn->interfaces;

    my $info = $if->overview;
    my $eth0 = $if->get_interface($INTERFACE_LAN);

=head1 DESCRIPTION

Network interface management.

=head1 METHODS

=head2 overview

    my $info = $if->overview;

Returns overview information for all network interfaces.

=head2 get_interface

    my $interface = $if->get_interface($if);

Returns detailed information for a specific interface by name or ID.

=head2 export

    my $data = $if->export;

Exports interface configuration.

=head2 reload_interface

    my $result = $if->reload_interface;
    my $result = $if->reload_interface($identifier);

Reloads a network interface.  Optionally specify the interface identifier.

=head2 settings_get

    my $settings = $if->settings_get;

Returns interface settings.

=head2 settings_set

    my $result = $if->settings_set($settings_data);

Updates interface settings.

=head2 settings_reconfigure

    my $result = $if->settings_reconfigure;

Applies pending interface settings changes.

=head1 CONSTANTS

Interface name constants are available from
L<WebService::OPNsense::Constants>:

=over

=item C<$INTERFACE_LAN>

=item C<$INTERFACE_WAN>

=item C<$INTERFACE_DMZ>

=item C<$INTERFACE_GUEST>

=item C<$INTERFACE_LOOPBACK>

=item C<$INTERFACE_OPT1> through C<$INTERFACE_OPT9>

=back

Use them when calling C<get_interface> or C<reload_interface>.

=head2 client

    my $http_client = $interfaces->client;

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
