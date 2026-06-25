#!/bin/false
# ABSTRACT: Unbound diagnostics controller
# PODNAME: WebService::OPNsense::Unbound::Diagnostics
use strictures 2;

package WebService::OPNsense::Unbound::Diagnostics;
$WebService::OPNsense::Unbound::Diagnostics::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub stats {
    my ($self) = @_;
    return $self->client->get('/api/unbound/diagnostics/stats');
}

sub list_local_zones {
    my ($self) = @_;
    return $self->client->get('/api/unbound/diagnostics/listLocalZones');
}

sub list_local_data {
    my ($self) = @_;
    return $self->client->get('/api/unbound/diagnostics/listLocalData');
}

sub list_insecure {
    my ($self) = @_;
    return $self->client->get('/api/unbound/diagnostics/listInsecure');
}

sub dump_cache {
    my ($self) = @_;
    return $self->client->get('/api/unbound/diagnostics/dumpCache');
}

sub dump_infra {
    my ($self) = @_;
    return $self->client->get('/api/unbound/diagnostics/dumpInfra');
}

sub test_blocklist {
    my ( $self, $blocklist_data ) = @_;
    return $self->client->post( '/api/unbound/diagnostics/testBlocklist', $blocklist_data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Unbound::Diagnostics - Unbound diagnostics controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $unbound_diag = $opn->unbound_diagnostics;

    my $stats = $unbound_diag->stats;

=head1 DESCRIPTION

Provides diagnostic methods for Unbound DNS.

=head1 NAME

WebService::OPNsense::Unbound::Diagnostics - Unbound diagnostics controller

=head1 METHODS

=head2 stats

    my $stats = $unbound_diag->stats;

Returns Unbound statistics.

=head2 list_local_zones

    my $zones = $unbound_diag->list_local_zones;

Lists local zones.

=head2 list_local_data

    my $data = $unbound_diag->list_local_data;

Lists local data entries.

=head2 list_insecure

    my $zones = $unbound_diag->list_insecure;

Lists insecure zones.

=head2 dump_cache

    my $cache = $unbound_diag->dump_cache;

Dumps the Unbound cache.

=head2 dump_infra

    my $infra = $unbound_diag->dump_infra;

Dumps infrastructure data.

=head2 test_blocklist

    my $result = $unbound_diag->test_blocklist($data);

Tests a domain against the blocklist.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
