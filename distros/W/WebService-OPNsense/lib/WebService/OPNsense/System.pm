#!/bin/false
# ABSTRACT: System API controller
# PODNAME: WebService::OPNsense::System
use strictures 2;

package WebService::OPNsense::System;
$WebService::OPNsense::System::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub status {
    my ($self) = @_;
    return $self->client->get('/api/core/system/status');
}

sub firmware_info {
    my ($self) = @_;
    return $self->client->get('/api/core/firmware/info');
}

sub firmware_status {
    my ($self) = @_;
    return $self->client->get('/api/core/firmware/status');
}

sub hostname {
    my ($self) = @_;
    return $self->client->get('/api/core/system/hostname');
}

sub version {
    my ($self) = @_;
    return $self->client->get('/api/core/system/version');
}

sub logging {
    my ( $self, %params ) = @_;
    return $self->client->get( '/api/core/system/logging', \%params );
}

sub changelog {
    my ($self) = @_;
    return $self->client->get('/api/core/firmware/changelog');
}

sub reboot {
    my ($self) = @_;
    return $self->client->post('/api/core/system/reboot');
}

sub halt {
    my ($self) = @_;
    return $self->client->post('/api/core/system/halt');
}

sub menu {
    my ($self) = @_;
    return $self->client->get('/api/core/system/menu');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::System - System API controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $sys = $opn->system;

    my $status = $sys->status;
    my $info   = $sys->firmware_info;
    my $version = $sys->version;

=head1 DESCRIPTION

System status, firmware information, and system operations.

=head1 NAME

WebService::OPNsense::System - System API controller

=head1 METHODS

=head2 status

    my $status = $sys->status;

Returns system status information.

=head2 firmware_info

    my $info = $sys->firmware_info;

Returns firmware version and update information.

=head2 firmware_status

    my $status = $sys->firmware_status;

Returns current firmware status (e.g. if updates are available).

=head2 hostname

    my $hostname = $sys->hostname;

Returns the system hostname.

=head2 version

    my $version = $sys->version;

Returns the OPNsense version string.

=head2 logging

    my $logs = $sys->logging(%params);

Searches system logs.  Parameters: C<current>, C<rowCount>, C<searchPhrase>, C<facility>, C<severity>.

=head2 changelog

    my $changelog = $sys->changelog;

Returns the firmware changelog.

=head2 reboot

    my $result = $sys->reboot;

Reboots the system immediately.

=head2 halt

    my $result = $sys->halt;

Halts (shuts down) the system immediately.

=head2 menu

    my $menu = $sys->menu;

Returns the navigation menu structure.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
