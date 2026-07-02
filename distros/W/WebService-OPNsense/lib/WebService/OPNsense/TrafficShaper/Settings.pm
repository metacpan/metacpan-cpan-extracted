#!/bin/false
# ABSTRACT: Traffic shaper settings controller
# PODNAME: WebService::OPNsense::TrafficShaper::Settings
use strictures 2;

package WebService::OPNsense::TrafficShaper::Settings;
$WebService::OPNsense::TrafficShaper::Settings::VERSION = '0.003';
use Moo;
use WebService::OPNsense::Normalize qw( validate_uuid );
use namespace::clean;

has client => ( is => 'ro', required => 1 );

sub _api_path {
    return '/api/trafficshaper/settings';
}

with 'WebService::OPNsense::Role::Settings';

sub add_pipe {
    my ( $self, $pipe_data ) = @_;
    my $uri = $self->_path('addPipe');

    return $self->client->post( $uri, $pipe_data );
}

sub add_queue {
    my ( $self, $queue_data ) = @_;
    my $uri = $self->_path('addQueue');

    return $self->client->post( $uri, $queue_data );
}

sub add_rule {
    my ( $self, $rule_data ) = @_;
    my $uri = $self->_path('addRule');

    return $self->client->post( $uri, $rule_data );
}

sub del_pipe {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'delPipe/{uuid}', uuid => $uuid );

    return $self->client->post($uri);
}

sub del_queue {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'delQueue/{uuid}', uuid => $uuid );

    return $self->client->post($uri);
}

sub del_rule {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'delRule/{uuid}', uuid => $uuid );

    return $self->client->post($uri);
}

sub download_pipes {
    my ($self) = @_;
    my $uri = $self->_path('downloadPipes');

    return $self->client->get($uri);
}

sub download_queues {
    my ($self) = @_;
    my $uri = $self->_path('downloadQueues');

    return $self->client->get($uri);
}

sub get_pipe {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'getPipe/{uuid}', uuid => $uuid );

    return $self->client->get($uri);
}

sub get_queue {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'getQueue/{uuid}', uuid => $uuid );

    return $self->client->get($uri);
}

sub get_rule {
    my ( $self, $uuid ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'getRule/{uuid}', uuid => $uuid );

    return $self->client->get($uri);
}

sub search_pipes {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('search_pipes');

    return $self->client->get( $uri, \%params );
}

sub search_queues {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('search_queues');

    return $self->client->get( $uri, \%params );
}

sub search_rules {
    my ( $self, %params ) = @_;
    my $uri = $self->_path('search_rules');

    return $self->client->get( $uri, \%params );
}

sub set_pipe {
    my ( $self, $uuid, $pipe_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'setPipe/{uuid}', uuid => $uuid );

    return $self->client->post(
        $uri, $pipe_data,
    );
}

sub set_queue {
    my ( $self, $uuid, $queue_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'setQueue/{uuid}', uuid => $uuid );

    return $self->client->post(
        $uri, $queue_data,
    );
}

sub set_rule {
    my ( $self, $uuid, $rule_data ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'setRule/{uuid}', uuid => $uuid );

    return $self->client->post(
        $uri, $rule_data,
    );
}

sub toggle_pipe {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'togglePipe/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled );

    return $self->client->post(
        $uri,
    );
}

sub toggle_queue {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'toggleQueue/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled );

    return $self->client->post(
        $uri,
    );
}

sub toggle_rule {
    my ( $self, $uuid, $enabled ) = @_;
    validate_uuid($uuid);
    my $uri = $self->_path( 'toggleRule/{uuid}{/enabled}', uuid => $uuid, enabled => $enabled );

    return $self->client->post(
        $uri,
    );
}

sub upload_pipes {
    my ( $self, $pipes_data ) = @_;
    my $uri = $self->_path('uploadPipes');

    return $self->client->post( $uri, $pipes_data );
}

sub upload_queues {
    my ( $self, $queues_data ) = @_;
    my $uri = $self->_path('uploadQueues');

    return $self->client->post( $uri, $queues_data );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::TrafficShaper::Settings - Traffic shaper settings controller

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $ts_settings = $opn->trafficshaper_settings;

    my $settings = $ts_settings->get_settings;

=head1 DESCRIPTION

Traffic shaper pipes, queues, and rules.

=head1 METHODS

=head2 add_pipe

    my $result = $ts_settings->add_pipe($pipe_data);

Creates pipe.

=head2 add_queue

    my $result = $ts_settings->add_queue($queue_data);

Creates queue.

=head2 add_rule

    my $result = $ts_settings->add_rule($rule_data);

Creates traffic shaper rule.

=head2 client

    my $http_client = $ts_settings->client;

Returns the underlying HTTP client object used for API requests.

=head2 del_pipe

    my $result = $ts_settings->del_pipe($uuid);

Deletes a pipe by UUID.

=head2 del_queue

    my $result = $ts_settings->del_queue($uuid);

Deletes a queue by UUID.

=head2 del_rule

    my $result = $ts_settings->del_rule($uuid);

Deletes a traffic shaper rule by UUID.

=head2 download_pipes

    my $pipes = $ts_settings->download_pipes;

Downloads all pipe configurations.

=head2 download_queues

    my $queues = $ts_settings->download_queues;

Downloads all queue configurations.

=head2 get_pipe

    my $pipe = $ts_settings->get_pipe($uuid);

Returns a single pipe by UUID.

=head2 get_queue

    my $queue = $ts_settings->get_queue($uuid);

Returns a single queue by UUID.

=head2 get_rule

    my $rule = $ts_settings->get_rule($uuid);

Returns a single traffic shaper rule by UUID.

=head2 get_settings

    my $settings = $ts_settings->get_settings;

Returns traffic shaper settings.

=head2 search_pipes

    my $pipes = $ts_settings->search_pipes(%params);

Searches for pipes.

=head2 search_queues

    my $queues = $ts_settings->search_queues(%params);

Searches for queues.

=head2 search_rules

    my $rules = $ts_settings->search_rules(%params);

Searches for traffic shaper rules.

=head2 set_pipe

    my $result = $ts_settings->set_pipe($uuid, $pipe_data);

Updates pipe.

=head2 set_queue

    my $result = $ts_settings->set_queue($uuid, $queue_data);

Updates queue.

=head2 set_rule

    my $result = $ts_settings->set_rule($uuid, $rule_data);

Updates traffic shaper rule.

=head2 set_settings

    my $result = $ts_settings->set_settings($settings_data);

Updates traffic shaper settings.

=head2 toggle_pipe

    my $result = $ts_settings->toggle_pipe($uuid, $enabled);

Enables or disables a pipe.

=head2 toggle_queue

    my $result = $ts_settings->toggle_queue($uuid, $enabled);

Enables or disables a queue.

=head2 toggle_rule

    my $result = $ts_settings->toggle_rule($uuid, $enabled);

Enables or disables a traffic shaper rule.

=head2 upload_pipes

    my $result = $ts_settings->upload_pipes($pipes_data);

Uploads pipe configurations.

=head2 upload_queues

    my $result = $ts_settings->upload_queues($queues_data);

Uploads queue configurations.

=head1 SEE ALSO

L<WebService::OPNsense::Role::Settings>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
