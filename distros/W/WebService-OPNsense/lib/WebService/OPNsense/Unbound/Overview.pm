#!/bin/false
# ABSTRACT: Unbound overview controller
# PODNAME: WebService::OPNsense::Unbound::Overview
use strictures 2;

package WebService::OPNsense::Unbound::Overview;
$WebService::OPNsense::Unbound::Overview::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub is_enabled {
    my ($self) = @_;
    return $self->client->get('/api/unbound/overview/isEnabled');
}

sub is_block_list_enabled {
    my ($self) = @_;
    return $self->client->get('/api/unbound/overview/isBlockListEnabled');
}

sub get_policies {
    my ($self) = @_;
    return $self->client->get('/api/unbound/overview/getPolicies');
}

sub totals {
    my ( $self, $maximum ) = @_;
    my $path = '/api/unbound/overview/totals';
    $path .= "/$maximum" if defined $maximum;
    return $self->client->get($path);
}

sub search_queries {
    my ( $self, %params ) = @_;
    return $self->client->get( '/api/unbound/overview/searchQueries', \%params );
}

sub rolling {
    my ( $self, $timeperiod, $clients ) = @_;
    my $path = '/api/unbound/overview/rolling';
    $path .= "/$timeperiod" if defined $timeperiod;
    $path .= "/$clients"    if defined $clients;
    return $self->client->get($path);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Unbound::Overview - Unbound overview controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $unbound_overview = $opn->unbound_overview;

    my $enabled = $unbound_overview->is_enabled;

=head1 DESCRIPTION

Unbound overview and statistics.

=head1 NAME

WebService::OPNsense::Unbound::Overview - Unbound overview controller

=head1 METHODS

=head2 is_enabled

    my $enabled = $unbound_overview->is_enabled;

Returns whether Unbound is enabled.

=head2 is_block_list_enabled

    my $enabled = $unbound_overview->is_block_list_enabled;

Returns whether the DNSBL block list is enabled.

=head2 get_policies

    my $policies = $unbound_overview->get_policies;

Returns Unbound policies.

=head2 totals

    my $totals = $unbound_overview->totals;
    my $totals = $unbound_overview->totals($maximum);

Returns query totals, optionally capped at a maximum.

=head2 search_queries

    my $queries = $unbound_overview->search_queries(%params);

Searches DNS query logs.

=head2 rolling

    my $data = $unbound_overview->rolling($timeperiod, $clients);

Returns rolling statistics for a given time period and client count.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
