package WebService::Site24x7;

use Moo;
use WebService::Site24x7::Client;
use WebService::Site24x7::Reports;
use WebService::Site24x7::Monitors;
use WebService::Site24x7::LocationProfiles;

our $VERSION = "0.06";

has auth_token        => (is => 'rw', required => 1);
has user_agent_header => (is => 'rw');
has client            => (is => 'lazy', handles => [qw/get/]);

sub _build_client {
    my $self = shift;
    my $client = WebService::Site24x7::Client->new(
        auth_token => $self->auth_token,
        version    => $VERSION,
    );

    $client->user_agent_header($self->user_agent_header)
        if $self->user_agent_header;

    return $client;
}

has reports           => (is => 'lazy');
has monitors          => (is => 'lazy');
has location_profiles => (is => 'lazy');

sub _build_reports           { WebService::Site24x7::Reports->new(client => shift) }
sub _build_monitors          { WebService::Site24x7::Monitors->new(client => shift) }
sub _build_location_profiles { WebService::Site24x7::LocationProfiles->new(client => shift) }

sub location_template {
    my ($self, %args) = @_;
    return $self->get("/location_template")->data;
}

sub current_status {
    my ($self, %args) = @_;
    my $path = "/current_status";
    $path .= "/$args{monitor_id}"     if $args{monitor_id};
    $path .= "/group/$args{group_id}" if $args{group_id};
    $path .= "/type/$args{type}"      if $args{type};
    return $self->get($path)->data;
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Site24x7 - An api client for https://site24x7.com

=head1 SYNOPSIS

    use WebService::Site24x7;

    my $site24x7 = WebService::Site24x7->new(
        auth_token        => '...'
        user_agent_header => 'mybot v1.0',
    );

    # All methods return a $response hashref which contains the jason response

    $site24x7->current_status;
    $site24x7->current_status(monitor_id => $monitor_id);
    $site24x7->current_status(group_id => $group_id);
    $site24x7->current_status(type => $type);

    $site24x7->monitors->list;

    $site24x7->location_profiles->list;
    $site24x7->location_template;  # get a list all locations

    $site24x7->reports->log_reports($monitor_id, date => $date);
    $site24x7->reports->performance($monitor_id,
        location_id => $location_id,
        granularity => $granularity,
        period      => $period,
    );

=head1 DESCRIPTION

WebService::Site24x7 is an api client for L<https://site24x7.com>.  It
currently implements a really limited subset of all the endpoints though.

=head1 SEE ALSO

L<https://www.site24x7.com/help/api/index.html>

=head1 LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

=cut

