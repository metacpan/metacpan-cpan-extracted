#!/bin/false
# ABSTRACT: System API controller
# PODNAME: WebService::OPNsense::System
use strictures 2;

package WebService::OPNsense::System;
$WebService::OPNsense::System::VERSION = '0.003';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub changelog {
    my ( $self, $version ) = @_;
    return $self->client->post("/api/core/firmware/changelog/$version");
}

sub firmware_info {
    my ($self) = @_;
    return $self->client->get('/api/core/firmware/info');
}

sub firmware_status {
    my ($self) = @_;
    return $self->client->get('/api/core/firmware/status');
}

sub firmware_upgrade {
    my ($self) = @_;
    return $self->client->post('/api/core/firmware/upgrade');
}

sub halt {
    my ($self) = @_;
    return $self->client->post('/api/core/system/halt');
}

sub reboot {
    my ($self) = @_;
    return $self->client->post('/api/core/system/reboot');
}

sub status {
    my ($self) = @_;
    return $self->client->get('/api/core/system/status');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::System - System API controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $sys = $opn->system;

    my $status  = $sys->status;
    my $info    = $sys->firmware_info;
    my $upgrade = $sys->firmware_upgrade;

=head1 DESCRIPTION

System status, firmware information, and system operations.

=head1 METHODS

=head2 changelog

    my $changelog = $sys->changelog($version);

Returns the firmware changelog for the given version.

=head2 firmware_info

    my $info = $sys->firmware_info;

Returns firmware version and update information.

=head2 firmware_status

    my $status = $sys->firmware_status;

Returns current firmware status (e.g. if updates are available).

=head2 firmware_upgrade

    my $result = $sys->firmware_upgrade;

Starts a firmware upgrade process.  Returns the upgrade job result.

=head2 halt

    my $result = $sys->halt;

Halts (shuts down) the system immediately.

=head2 reboot

    my $result = $sys->reboot;

Reboots the system immediately.

=head2 status

    my $status = $sys->status;

Returns system status information.

=head2 client

    my $http_client = $sys->client;

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
