#!/bin/false
# ABSTRACT: Unbound settings controller
# PODNAME: WebService::OPNsense::Unbound::Settings
use strictures 2;

package WebService::OPNsense::Unbound::Settings;
$WebService::OPNsense::Unbound::Settings::VERSION = '0.002';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/unbound/settings';
}

with 'WebService::OPNsense::Role::Settings';

sub search_host_override {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('searchHostOverride');

    return $self->client->get(
        $uri, \%params,
    );
}

sub get_host_override {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'getHostOverride/{uuid}', uuid => $uuid );

    return $self->client->get(
        $uri,
    );
}

sub add_host_override {
    my ( $self, $host_data ) = @_;
    my $uri = $self->_path('addHostOverride');

    return $self->client->post(
        $uri, $host_data,
    );
}

sub set_host_override {
    my ( $self, $uuid, $host_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'setHostOverride/{uuid}', uuid => $uuid );

    return $self->client->post(
        $uri, $host_data,
    );
}

sub del_host_override {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'delHostOverride/{uuid}', uuid => $uuid );

    return $self->client->post(
        $uri,
    );
}

sub toggle_host_override {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'toggleHostOverride/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled );

    return $self->client->post(
        $uri,
    );
}

sub search_host_alias {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('searchHostAlias');

    return $self->client->get(
        $uri, \%params,
    );
}

sub get_host_alias {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'getHostAlias/{uuid}', uuid => $uuid );

    return $self->client->get(
        $uri,
    );
}

sub add_host_alias {
    my ( $self, $alias_data ) = @_;
    my $uri = $self->_path('addHostAlias');

    return $self->client->post(
        $uri, $alias_data,
    );
}

sub set_host_alias {
    my ( $self, $uuid, $alias_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'setHostAlias/{uuid}', uuid => $uuid );

    return $self->client->post(
        $uri, $alias_data,
    );
}

sub del_host_alias {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'delHostAlias/{uuid}', uuid => $uuid );

    return $self->client->post(
        $uri,
    );
}

sub toggle_host_alias {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'toggleHostAlias/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled );

    return $self->client->post(
        $uri,
    );
}

sub search_forward {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('searchForward');

    return $self->client->get( $uri, \%params );
}

sub get_forward {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'getForward/{uuid}', uuid => $uuid );

    return $self->client->get($uri);
}

sub add_forward {
    my ( $self, $forward_data ) = @_;
    my $uri = $self->_path('addForward');

    return $self->client->post( $uri, $forward_data );
}

sub set_forward {
    my ( $self, $uuid, $forward_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'setForward/{uuid}', uuid => $uuid );

    return $self->client->post(
        $uri, $forward_data,
    );
}

sub del_forward {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'delForward/{uuid}', uuid => $uuid );

    return $self->client->post($uri);
}

sub toggle_forward {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'toggleForward/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled );

    return $self->client->post(
        $uri,
    );
}

sub search_acl {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('searchACL');

    return $self->client->get( $uri, \%params );
}

sub get_acl {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'getACL/{uuid}', uuid => $uuid );

    return $self->client->get($uri);
}

sub add_acl {
    my ( $self, $acl_data ) = @_;
    my $uri = $self->_path('addACL');

    return $self->client->post( $uri, $acl_data );
}

sub set_acl {
    my ( $self, $uuid, $acl_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'setACL/{uuid}', uuid => $uuid );

    return $self->client->post(
        $uri, $acl_data,
    );
}

sub del_acl {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'delACL/{uuid}', uuid => $uuid );

    return $self->client->post($uri);
}

sub toggle_acl {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'toggleACL/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled );

    return $self->client->post(
        $uri,
    );
}

sub search_dnsbl {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('searchDnsbl');

    return $self->client->get( $uri, \%params );
}

sub get_dnsbl {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'getDnsbl/{uuid}', uuid => $uuid );

    return $self->client->get($uri);
}

sub add_dnsbl {
    my ( $self, $dnsbl_data ) = @_;
    my $uri = $self->_path('addDnsbl');

    return $self->client->post( $uri, $dnsbl_data );
}

sub set_dnsbl {
    my ( $self, $uuid, $dnsbl_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'setDnsbl/{uuid}', uuid => $uuid );

    return $self->client->post(
        $uri, $dnsbl_data,
    );
}

sub del_dnsbl {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'delDnsbl/{uuid}', uuid => $uuid );

    return $self->client->post($uri);
}

sub toggle_dnsbl {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'toggleDnsbl/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled );

    return $self->client->post(
        $uri,
    );
}

sub update_blocklist {
    my ($self) = @_;
    my $uri = $self->_path('updateBlocklist');

    return $self->client->post($uri);
}

sub get_nameservers {
    my ($self) = @_;
    my $uri = $self->_path('getNameservers');

    return $self->client->get($uri);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Unbound::Settings - Unbound settings controller

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $unbound_settings = $opn->unbound_settings;

    my $settings = $unbound_settings->get;

=head1 DESCRIPTION

Manages Unbound DNS settings including host overrides,
aliases, forwards, ACLs, and DNSBL.

=head1 METHODS

=head2 get_settings

    my $settings = $unbound_settings->get_settings;

Returns Unbound settings.

=head2 set_settings

    my $result = $unbound_settings->set_settings($data);

Updates Unbound settings.

=head2 search_host_override

    my $overrides = $unbound_settings->search_host_override(%params);

Searches for host overrides.

=head2 get_host_override

    my $override = $unbound_settings->get_host_override($uuid);

Returns a single host override by UUID.

=head2 add_host_override

    my $result = $unbound_settings->add_host_override($data);

Creates host override.

=head2 set_host_override

    my $result = $unbound_settings->set_host_override($uuid, $data);

Updates host override.

=head2 del_host_override

    my $result = $unbound_settings->del_host_override($uuid);

Deletes a host override by UUID.

=head2 toggle_host_override

    my $result = $unbound_settings->toggle_host_override($uuid, $enabled);

Enables or disables a host override.

=head2 search_host_alias

    my $aliases = $unbound_settings->search_host_alias(%params);

Searches for host aliases.

=head2 get_host_alias

    my $alias = $unbound_settings->get_host_alias($uuid);

Returns a single host alias by UUID.

=head2 add_host_alias

    my $result = $unbound_settings->add_host_alias($data);

Creates host alias.

=head2 set_host_alias

    my $result = $unbound_settings->set_host_alias($uuid, $data);

Updates host alias.

=head2 del_host_alias

    my $result = $unbound_settings->del_host_alias($uuid);

Deletes a host alias by UUID.

=head2 toggle_host_alias

    my $result = $unbound_settings->toggle_host_alias($uuid, $enabled);

Enables or disables a host alias.

=head2 search_forward

    my $forwards = $unbound_settings->search_forward(%params);

Searches for forwarding entries.

=head2 get_forward

    my $forward = $unbound_settings->get_forward($uuid);

Returns a single forward entry by UUID.

=head2 add_forward

    my $result = $unbound_settings->add_forward($data);

Creates forward entry.

=head2 set_forward

    my $result = $unbound_settings->set_forward($uuid, $data);

Updates forward entry.

=head2 del_forward

    my $result = $unbound_settings->del_forward($uuid);

Deletes a forward entry by UUID.

=head2 toggle_forward

    my $result = $unbound_settings->toggle_forward($uuid, $enabled);

Enables or disables a forward entry.

=head2 search_acl

    my $acls = $unbound_settings->search_acl(%params);

Searches for ACL entries.

=head2 get_acl

    my $acl = $unbound_settings->get_acl($uuid);

Returns a single ACL entry by UUID.

=head2 add_acl

    my $result = $unbound_settings->add_acl($data);

Creates ACL entry.

=head2 set_acl

    my $result = $unbound_settings->set_acl($uuid, $data);

Updates ACL entry.

=head2 del_acl

    my $result = $unbound_settings->del_acl($uuid);

Deletes an ACL entry by UUID.

=head2 toggle_acl

    my $result = $unbound_settings->toggle_acl($uuid, $enabled);

Enables or disables an ACL entry.

=head2 search_dnsbl

    my $dnsbl_entries = $unbound_settings->search_dnsbl(%params);

Searches for DNSBL entries.

=head2 get_dnsbl

    my $dnsbl = $unbound_settings->get_dnsbl($uuid);

Returns a single DNSBL entry by UUID.

=head2 add_dnsbl

    my $result = $unbound_settings->add_dnsbl($data);

Creates DNSBL entry.

=head2 set_dnsbl

    my $result = $unbound_settings->set_dnsbl($uuid, $data);

Updates DNSBL entry.

=head2 del_dnsbl

    my $result = $unbound_settings->del_dnsbl($uuid);

Deletes a DNSBL entry by UUID.

=head2 toggle_dnsbl

    my $result = $unbound_settings->toggle_dnsbl($uuid, $enabled);

Enables or disables a DNSBL entry.

=head2 update_blocklist

    my $result = $unbound_settings->update_blocklist;

Updates the DNSBL blocklist.

=head2 get_nameservers

    my $nameservers = $unbound_settings->get_nameservers;

Returns the configured nameservers.

=head2 client

    my $http_client = $unbound_settings->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::Role::Settings>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
