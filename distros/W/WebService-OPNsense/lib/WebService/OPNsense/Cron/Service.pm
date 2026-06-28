#!/bin/false
# ABSTRACT: Cron service controller
# PODNAME: WebService::OPNsense::Cron::Service
use strictures 2;

package WebService::OPNsense::Cron::Service;
$WebService::OPNsense::Cron::Service::VERSION = '0.002';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/cron/service';
}

with 'WebService::OPNsense::Role::APIPath';

sub reconfigure {
    my ($self) = @_;
    my $uri = $self->_path('reconfigure');
    return $self->client->post($uri);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Cron::Service - Cron service controller

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $cron_service = $opn->cron_service;

    $cron_service->reconfigure;

=head1 DESCRIPTION

Controls the cron service.

=head1 METHODS

=head2 reconfigure

    my $result = $cron_service->reconfigure;

Reconfigures the cron service.

=head2 client

    my $http_client = $cron_service->client;

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
