#!/bin/false
# ABSTRACT: Dnsmasq service controller
# PODNAME: WebService::OPNsense::Dnsmasq::Service
use strictures 2;

package WebService::OPNsense::Dnsmasq::Service;
$WebService::OPNsense::Dnsmasq::Service::VERSION = '0.002';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/dnsmasq/service';
}

with 'WebService::OPNsense::Role::Service';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Dnsmasq::Service - Dnsmasq service controller

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $service = $opn->dnsmasq_service;

    $service->status;
    $service->restart;
    $service->reconfigure;

=head1 DESCRIPTION

Controls the Dnsmasq service.

=head1 METHODS

=head2 status

    my $status = $service->status;

Returns service status.

=head2 start

    my $result = $service->start;

Starts the Dnsmasq service.

=head2 stop

    my $result = $service->stop;

Stops the Dnsmasq service.

=head2 restart

    my $result = $service->restart;

Restarts the Dnsmasq service.

=head2 reconfigure

    my $result = $service->reconfigure;

Reconfigures the Dnsmasq service.

=head2 client

    my $http_client = $service->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::Role::Service>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
