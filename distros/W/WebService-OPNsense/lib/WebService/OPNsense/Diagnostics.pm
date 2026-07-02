#!/bin/false
# ABSTRACT: Diagnostics API controller
# PODNAME: WebService::OPNsense::Diagnostics
use strictures 2;

package WebService::OPNsense::Diagnostics;
$WebService::OPNsense::Diagnostics::VERSION = '0.003';
use Moo;
use WebService::OPNsense::Normalize qw( optional_segment );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub activity {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/activity/get_activity');
}

sub arp_table {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/interface/get_arp');
}

sub del_state {
    my ( $self, $stateid, $creatorid ) = @_;
    return $self->client->post(
        "/api/diagnostics/firewall/del_state/$stateid/$creatorid",
    );
}

sub dns_lookup {
    my ( $self, $host ) = @_;
    return $self->client->get(
        '/api/diagnostics/dns/reverseLookup',
        { address => $host },
    );
}

sub firewall_log {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/firewall/log');
}

sub firewall_log_filters {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/firewall/log_filters');
}

sub firewall_stats {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/firewall/stats');
}

sub flush_arp {
    my ($self) = @_;
    return $self->client->post('/api/diagnostics/interface/flush_arp');
}

sub flush_sources {
    my ($self) = @_;
    return $self->client->post('/api/diagnostics/firewall/flush_sources');
}

sub flush_states {
    my ($self) = @_;
    return $self->client->post('/api/diagnostics/firewall/flush_states');
}

sub interface_config {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/interface/get_interface_config');
}

sub interface_names {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/interface/get_interface_names');
}

sub interface_statistics {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/interface/get_interface_statistics');
}

sub kill_states {
    my ($self) = @_;
    return $self->client->post('/api/diagnostics/firewall/kill_states');
}

sub memory {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/system/memory');
}

sub ndp_table {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/interface/get_ndp');
}

sub pf_states {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/firewall/pf_states');
}

sub pf_statistics {
    my ( $self, $section ) = @_;
    my $path = '/api/diagnostics/firewall/pf_statistics' . optional_segment($section);
    return $self->client->get($path);
}

sub ping {
    my ( $self, $host ) = @_;
    return $self->client->post(
        '/api/diagnostics/ping/set',
        { ping => { hostname => $host, ipproto => 'ipv4' } },
    );
}

sub portprobe {
    my ( $self, $probe_data ) = @_;
    return $self->client->post( '/api/diagnostics/portprobe/set', $probe_data );
}

sub routes {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/interface/get_routes');
}

sub search_service {
    my ( $self, %params ) = @_;
    return $self->client->get( '/api/core/service/search', \%params );
}

sub system_disk {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/system/system_disk');
}

sub system_information {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/system/system_information');
}

sub system_time {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/system/system_time');
}

sub traceroute {
    my ( $self, $host ) = @_;
    return $self->client->post(
        '/api/diagnostics/traceroute/set',
        { traceroute => { hostname => $host, ipproto => 'ipv4' } },
    );
}

sub traffic {
    my ($self) = @_;
    return $self->client->get('/api/diagnostics/traffic/_interface');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Diagnostics - Diagnostics API controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $diag = $opn->diagnostics;

    my $result = $diag->ping('192.0.2.1');
    my $states = $diag->pf_states;
    my $info   = $diag->system_information;

=head1 DESCRIPTION

Network and system diagnostics.

=head1 METHODS

=head2 activity

    my $activity = $diag->activity;

Returns system activity information.

=head2 arp_table

    my $arp = $diag->arp_table;

Returns the ARP table.

=head2 del_state

    my $result = $diag->del_state($stateid, $creatorid);

Deletes a specific pf state entry.

=head2 dns_lookup

    my $result = $diag->dns_lookup($host);

Performs a reverse DNS lookup for an IP address using the
OPNsense diagnostic DNS endpoint.

=head2 firewall_log

    my $log = $diag->firewall_log;

Returns the firewall log.

=head2 firewall_log_filters

    my $filters = $diag->firewall_log_filters;

Returns available firewall log filter options.

=head2 firewall_stats

    my $stats = $diag->firewall_stats;

Returns firewall statistics summary.

=head2 flush_arp

    my $result = $diag->flush_arp;

Flushes the ARP cache.

=head2 flush_sources

    my $result = $diag->flush_sources;

Flushes all source tracking entries.

=head2 flush_states

    my $result = $diag->flush_states;

Flushes all pf state entries.

=head2 interface_config

    my $config = $diag->interface_config;

Returns network interface configuration.

=head2 interface_names

    my $names = $diag->interface_names;

Returns a list of network interface names.

=head2 interface_statistics

    my $stats = $diag->interface_statistics;

Returns network interface statistics.

=head2 kill_states

    my $result = $diag->kill_states;

Kills all pf state entries.

=head2 memory

    my $memory = $diag->memory;

Returns memory usage information.

=head2 ndp_table

    my $ndp = $diag->ndp_table;

Returns the NDP (IPv6 neighbor) table.

=head2 pf_states

    my $states = $diag->pf_states;

Returns current pf state table.

=head2 pf_statistics

    my $stats = $diag->pf_statistics;
    my $stats = $diag->pf_statistics($section);

Returns pf statistics.  Optionally specify a section.

=head2 ping

    my $result = $diag->ping($host);

Pings a host using the OPNsense diagnostic ping endpoint.
Returns ping statistics.

=head2 portprobe

    my $result = $diag->portprobe($probe_data);

Probes a port on a remote host.  C<$probe_data> should contain
C<host> and C<port> fields.

=head2 routes

    my $routes = $diag->routes;

Returns the system routing table.

=head2 search_service

    my $results = $diag->search_service(%params);

Searches for system services.

=head2 system_disk

    my $disk = $diag->system_disk;

Returns disk usage information.

=head2 system_information

    my $info = $diag->system_information;

Returns general system information.

=head2 system_time

    my $time = $diag->system_time;

Returns system time.

=head2 traceroute

    my $result = $diag->traceroute($host);

Traces the route to a host using the OPNsense diagnostic
traceroute endpoint.

=head2 traffic

    my $traffic = $diag->traffic;

Returns current traffic statistics per interface.

=head2 client

    my $http_client = $diag->client;

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
