#!/bin/false
# ABSTRACT: Cron service controller
# PODNAME: WebService::OPNsense::Cron::Service
use strictures 2;

package WebService::OPNsense::Cron::Service;
$WebService::OPNsense::Cron::Service::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub reconfigure {
    my ($self) = @_;
    return $self->client->post('/api/cron/service/reconfigure');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Cron::Service - Cron service controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $cron_service = $opn->cron_service;

    $cron_service->reconfigure;

=head1 DESCRIPTION

Controls the cron service.

=head1 NAME

WebService::OPNsense::Cron::Service - Cron service controller

=head1 METHODS

=head2 reconfigure

    my $result = $cron_service->reconfigure;

Reconfigures the cron service.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
