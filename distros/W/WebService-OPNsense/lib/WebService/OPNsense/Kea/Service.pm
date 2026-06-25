#!/bin/false
# ABSTRACT: Kea service controller
# PODNAME: WebService::OPNsense::Kea::Service
use strictures 2;

package WebService::OPNsense::Kea::Service;
$WebService::OPNsense::Kea::Service::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/kea/service';
}

with 'WebService::OPNsense::Role::Service';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Kea::Service - Kea service controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $service = $opn->kea_service;

    my $status = $service->status;
    $service->start;
    $service->stop;
    $service->restart;
    $service->reconfigure;

=head1 DESCRIPTION

Kea service lifecycle management.

=head1 NAME

WebService::OPNsense::Kea::Service - Kea service controller

=head1 METHODS

=head2 reconfigure

    my $result = $service->reconfigure;

Reconfigures the Kea service.

=head2 restart

    my $result = $service->restart;

Restarts the Kea service.

=head2 start

    my $result = $service->start;

Starts the Kea service.

=head2 status

    my $status = $service->status;

Returns the current status of the Kea service.

=head2 stop

    my $result = $service->stop;

Stops the Kea service.

=for Pod::Coverage _api_path _path client status start stop restart reconfigure

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
