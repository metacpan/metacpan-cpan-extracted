#!/bin/false
# ABSTRACT: Traffic shaper service controller
# PODNAME: WebService::OPNsense::TrafficShaper::Service
use strictures 2;

package WebService::OPNsense::TrafficShaper::Service;
$WebService::OPNsense::TrafficShaper::Service::VERSION = '0.002';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/trafficshaper/service';
}

with 'WebService::OPNsense::Role::APIPath';

sub reconfigure {
    my ($self) = @_;
    my $uri = $self->_path('reconfigure');
    return $self->client->post($uri);
}

sub flush_reload {
    my ($self) = @_;
    my $uri = $self->_path('flushReload');
    return $self->client->post($uri);
}

sub statistics {
    my ($self) = @_;
    my $uri = $self->_path('statistics');
    return $self->client->get($uri);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::TrafficShaper::Service - Traffic shaper service controller

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $ts_service = $opn->trafficshaper_service;

    $ts_service->reconfigure;

=head1 DESCRIPTION

Controls the traffic shaper service

=head1 METHODS

=head2 reconfigure

    my $result = $ts_service->reconfigure;

Reconfigures the traffic shaper.

=head2 flush_reload

    my $result = $ts_service->flush_reload;

Flushes and reloads the traffic shaper configuration.

=head2 statistics

    my $stats = $ts_service->statistics;

Returns traffic shaper statistics.

=head2 client

    my $http_client = $ts_service->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::Role::APIPath>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
