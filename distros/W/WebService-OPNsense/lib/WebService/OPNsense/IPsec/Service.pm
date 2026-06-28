#!/bin/false
# ABSTRACT: IPsec service controller
# PODNAME: WebService::OPNsense::IPsec::Service
use strictures 2;

package WebService::OPNsense::IPsec::Service;
$WebService::OPNsense::IPsec::Service::VERSION = '0.002';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/ipsec/service';
}

with 'WebService::OPNsense::Role::Service';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::IPsec::Service - IPsec service controller

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $svc = $opn->ipsec_service;

    my $status = $svc->status;
    $svc->restart;

=head1 DESCRIPTION

Controls the IPsec service.

=head1 METHODS

=head2 status

    my $status = $svc->status;

Returns IPsec service status.

=head2 start

    my $result = $svc->start;

Starts the IPsec service.

=head2 stop

    my $result = $svc->stop;

Stops the IPsec service.

=head2 restart

    my $result = $svc->restart;

Restarts the IPsec service.

=head2 reconfigure

    my $result = $svc->reconfigure;

Reconfigures the IPsec service.

=head2 client

    my $http_client = $svc->client;

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
