#!/bin/false
# ABSTRACT: Dnsmasq settings controller
# PODNAME: WebService::OPNsense::Dnsmasq::Settings
use strictures 2;

package WebService::OPNsense::Dnsmasq::Settings;
$WebService::OPNsense::Dnsmasq::Settings::VERSION = '0.001';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/dnsmasq/settings';
}

with 'WebService::OPNsense::Role::Settings';

sub search_host {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchHost'), \%params );
}

sub get_host {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getHost/{uuid}', uuid => $uuid ) );
}

sub add_host {
    my ( $self, $host_data ) = @_;
    return $self->client->post( $self->_path('addHost'), $host_data );
}

sub set_host {
    my ( $self, $uuid, $host_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setHost/{uuid}', uuid => $uuid ), $host_data );
}

sub del_host {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delHost/{uuid}', uuid => $uuid ) );
}

sub search_domain {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchDomain'), \%params );
}

sub get_domain {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getDomain/{uuid}', uuid => $uuid ) );
}

sub add_domain {
    my ( $self, $domain_data ) = @_;
    return $self->client->post( $self->_path('addDomain'), $domain_data );
}

sub set_domain {
    my ( $self, $uuid, $domain_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setDomain/{uuid}', uuid => $uuid ), $domain_data );
}

sub del_domain {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delDomain/{uuid}', uuid => $uuid ) );
}

sub search_option {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchOption'), \%params );
}

sub get_option {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getOption/{uuid}', uuid => $uuid ) );
}

sub add_option {
    my ( $self, $option_data ) = @_;
    return $self->client->post( $self->_path('addOption'), $option_data );
}

sub set_option {
    my ( $self, $uuid, $option_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setOption/{uuid}', uuid => $uuid ), $option_data );
}

sub del_option {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delOption/{uuid}', uuid => $uuid ) );
}

sub search_range {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchRange'), \%params );
}

sub get_range {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getRange/{uuid}', uuid => $uuid ) );
}

sub add_range {
    my ( $self, $range_data ) = @_;
    return $self->client->post( $self->_path('addRange'), $range_data );
}

sub set_range {
    my ( $self, $uuid, $range_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setRange/{uuid}', uuid => $uuid ), $range_data );
}

sub del_range {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delRange/{uuid}', uuid => $uuid ) );
}

sub search_tag {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchTag'), \%params );
}

sub get_tag {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getTag/{uuid}', uuid => $uuid ) );
}

sub add_tag {
    my ( $self, $tag_data ) = @_;
    return $self->client->post( $self->_path('addTag'), $tag_data );
}

sub set_tag {
    my ( $self, $uuid, $tag_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setTag/{uuid}', uuid => $uuid ), $tag_data );
}

sub del_tag {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delTag/{uuid}', uuid => $uuid ) );
}

sub search_boot {
    my ( $self, %params ) = @_;
    return $self->client->get( $self->_path('searchBoot'), \%params );
}

sub get_boot {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->get( $self->_path( 'getBoot/{uuid}', uuid => $uuid ) );
}

sub add_boot {
    my ( $self, $boot_data ) = @_;
    return $self->client->post( $self->_path('addBoot'), $boot_data );
}

sub set_boot {
    my ( $self, $uuid, $boot_data ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'setBoot/{uuid}', uuid => $uuid ), $boot_data );
}

sub del_boot {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    return $self->client->post( $self->_path( 'delBoot/{uuid}', uuid => $uuid ) );
}

sub download_hosts {
    my ($self) = @_;
    return $self->client->get( $self->_path('downloadHosts') );
}

sub upload_hosts {
    my ( $self, $hosts_data ) = @_;
    return $self->client->post( $self->_path('uploadHosts'), $hosts_data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Dnsmasq::Settings - Dnsmasq settings controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $settings = $opn->dnsmasq_settings;

    # Get current settings
    my $config = $settings->get;

    # Update settings
    $settings->set({ dnsmasq => { enabled => 1 } });

    # Search hosts
    my $hosts = $settings->search_host(current => 1, rowCount => 50);

    # Add a host override
    $settings->add_host({
        host => {
            host => 'myserver',
            domain => 'example.com',
            ip => '192.0.2.10',
        },
    });

=head1 DESCRIPTION

Dnsmasq settings, including host overrides, domain overrides, DHCP options,
ranges, tags, and boot settings.

=head1 NAME

WebService::OPNsense::Dnsmasq::Settings - Dnsmasq settings controller

=head1 METHODS

=head2 get

    my $config = $settings->get;

Returns the current Dnsmasq configuration.

=head2 set_settings

    my $result = $settings->set_settings($settings_data);

Updates Dnsmasq configuration.

=head2 search_host

    my $results = $settings->search_host(%params);

Searches for host overrides.

=head2 get_host

    my $host = $settings->get_host($uuid);

Returns a single host override by UUID.

=head2 add_host

    my $result = $settings->add_host($host_data);

Creates a new host override.

=head2 set_host

    my $result = $settings->set_host($uuid, $host_data);

Updates an existing host override.

=head2 del_host

    my $result = $settings->del_host($uuid);

Deletes a host override by UUID.

=head2 search_domain

    my $results = $settings->search_domain(%params);

Searches for domain overrides.

=head2 get_domain

    my $domain = $settings->get_domain($uuid);

Returns a single domain override by UUID.

=head2 add_domain

    my $result = $settings->add_domain($domain_data);

Creates a new domain override.

=head2 set_domain

    my $result = $settings->set_domain($uuid, $domain_data);

Updates an existing domain override.

=head2 del_domain

    my $result = $settings->del_domain($uuid);

Deletes a domain override by UUID.

=head2 search_option

    my $results = $settings->search_option(%params);

Searches for DHCP options.

=head2 get_option

    my $option = $settings->get_option($uuid);

Returns a single DHCP option by UUID.

=head2 add_option

    my $result = $settings->add_option($option_data);

Creates a new DHCP option.

=head2 set_option

    my $result = $settings->set_option($uuid, $option_data);

Updates an existing DHCP option.

=head2 del_option

    my $result = $settings->del_option($uuid);

Deletes a DHCP option by UUID.

=head2 search_range

    my $results = $settings->search_range(%params);

Searches for DHCP ranges.

=head2 get_range

    my $range = $settings->get_range($uuid);

Returns a single DHCP range by UUID.

=head2 add_range

    my $result = $settings->add_range($range_data);

Creates a new DHCP range.

=head2 set_range

    my $result = $settings->set_range($uuid, $range_data);

Updates an existing DHCP range.

=head2 del_range

    my $result = $settings->del_range($uuid);

Deletes a DHCP range by UUID.

=head2 search_tag

    my $results = $settings->search_tag(%params);

Searches for tags.

=head2 get_tag

    my $tag = $settings->get_tag($uuid);

Returns a single tag by UUID.

=head2 add_tag

    my $result = $settings->add_tag($tag_data);

Creates a new tag.

=head2 set_tag

    my $result = $settings->set_tag($uuid, $tag_data);

Updates an existing tag.

=head2 del_tag

    my $result = $settings->del_tag($uuid);

Deletes a tag by UUID.

=head2 search_boot

    my $results = $settings->search_boot(%params);

Searches for boot settings.

=head2 get_boot

    my $boot = $settings->get_boot($uuid);

Returns a single boot setting by UUID.

=head2 add_boot

    my $result = $settings->add_boot($boot_data);

Creates a new boot setting.

=head2 set_boot

    my $result = $settings->set_boot($uuid, $boot_data);

Updates an existing boot setting.

=head2 del_boot

    my $result = $settings->del_boot($uuid);

Deletes a boot setting by UUID.

=head2 download_hosts

    my $data = $settings->download_hosts;

Downloads host overrides as a data structure.

=head2 upload_hosts

    my $result = $settings->upload_hosts($hosts_data);

Uploads host overrides from a data structure.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
