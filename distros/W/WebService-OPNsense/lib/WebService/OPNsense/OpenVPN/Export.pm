#!/bin/false
# ABSTRACT: OpenVPN export controller
# PODNAME: WebService::OPNsense::OpenVPN::Export
use strictures 2;

package WebService::OPNsense::OpenVPN::Export;
$WebService::OPNsense::OpenVPN::Export::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/openvpn/export';
}

with 'WebService::OPNsense::Role::APIPath';

sub providers {
    my ($self) = @_;
    return $self->client->get( $self->_path('providers') );
}

sub templates {
    my ($self) = @_;
    return $self->client->get( $self->_path('templates') );
}

sub accounts {
    my ( $self, $vpnid ) = @_;
    return $self->client->get(
        $self->_path( 'accounts{/vpnid}', vpnid => $vpnid ),
    );
}

sub validate_presets {
    my ( $self, $presets_data ) = @_;
    return $self->client->post( $self->_path('validatePresets'), $presets_data );
}

sub store_presets {
    my ( $self, $presets_data ) = @_;
    return $self->client->post( $self->_path('storePresets'), $presets_data );
}

sub download {
    my ( $self, $download_data ) = @_;
    return $self->client->post( $self->_path('download'), $download_data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::OpenVPN::Export - OpenVPN export controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $export = $opn->openvpn_export;

    my $providers = $export->providers;
    my $templates = $export->templates;
    my $accounts  = $export->accounts($vpnid);

=head1 DESCRIPTION

Exports OpenVPN client configurations and manages
export presets.

=head1 NAME

WebService::OPNsense::OpenVPN::Export - OpenVPN export controller

=head1 METHODS

=head2 providers

    my $providers = $export->providers;

Returns a list of available providers for export.

=head2 templates

    my $templates = $export->templates;

Returns a list of available export templates.

=head2 accounts

    my $accounts = $export->accounts;
    my $accounts = $export->accounts($vpnid);

Returns accounts for export.  Optionally filter by VPN instance ID.

=head2 validate_presets

    my $result = $export->validate_presets($presets_data);

Validates export presets.

=head2 store_presets

    my $result = $export->store_presets($presets_data);

Stores export presets for later use.

=head2 download

    my $data = $export->download($download_data);

Downloads an OpenVPN client configuration package.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
