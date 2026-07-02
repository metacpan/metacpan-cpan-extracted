#!/bin/false
# ABSTRACT: Cron settings controller
# PODNAME: WebService::OPNsense::Cron::Settings
use strictures 2;

package WebService::OPNsense::Cron::Settings;
$WebService::OPNsense::Cron::Settings::VERSION = '0.003';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/cron/settings';
}

with 'WebService::OPNsense::Role::Settings';

sub add_job {
    my ( $self, $job_data ) = @_;
    my $uri = $self->_path('add_job');

    return $self->client->post( $uri, $job_data );
}

sub del_job {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'del_job/{uuid}', uuid => $uuid );

    return $self->client->post($uri);
}

sub get_job {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'get_job/{uuid}', uuid => $uuid );

    return $self->client->get($uri);
}

sub search_jobs {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('search_jobs');

    return $self->client->get( $uri, \%params );
}

sub set_job {
    my ( $self, $uuid, $job_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'set_job/{uuid}', uuid => $uuid );

    return $self->client->post( $uri, $job_data );
}

sub toggle_job {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'toggle_job/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled );

    return $self->client->post(
        $uri,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Cron::Settings - Cron settings controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $cron_settings = $opn->cron_settings;

    my $settings = $cron_settings->get;

=head1 DESCRIPTION

Manages cron jobs.

=head1 METHODS

=head2 get_settings

    my $settings = $cron_settings->get_settings;

Returns cron settings.

=head2 set_settings

    my $result = $cron_settings->set_settings($settings_data);

Updates cron settings.

=head2 add_job

    my $result = $cron_settings->add_job($job_data);

Creates cron job.

=head2 del_job

    my $result = $cron_settings->del_job($uuid);

Deletes a cron job by UUID.

=head2 get_job

    my $job = $cron_settings->get_job($uuid);

Returns a single cron job by UUID.

=head2 search_jobs

    my $jobs = $cron_settings->search_jobs(%params);

Searches for cron jobs.

=head2 set_job

    my $result = $cron_settings->set_job($uuid, $job_data);

Updates cron job.

=head2 toggle_job

    my $result = $cron_settings->toggle_job($uuid, $enabled);

Enables or disables a cron job.

=head2 client

    my $http_client = $cron_settings->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense::Role::Settings>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
