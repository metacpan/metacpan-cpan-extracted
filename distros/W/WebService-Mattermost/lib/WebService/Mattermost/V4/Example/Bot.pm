package WebService::Mattermost::V4::Example::Bot;

use Moo; # or Moose

extends 'WebService::Mattermost::V4::Client';

################################################################################

sub gw_ws_started {
    my $self = shift;
    my $args = shift;

    if ($self->debug) {
        $self->logger->debug('Pingbot is alive');
    }

    return 1;
}

sub gw_ws_finished {
    my $self = shift;
    my $args = shift;

    if ($self->debug) {
        $self->logger->debugf('Pingbot disconnected: [%d] %s', $args->{code}, $args->{reason});
    }

    return 1;
}

sub gw_message {
    my $self = shift;
    my $args = shift;

    # message_has_data() checks whether we have the "message" item in post_data
    if ($self->message_has_content($args) && $args->{post_data}->{message} =~ /ping/i) {
        # Use the "posts" resource from the API integration to send a message
        # back to the channel
        $self->api->posts->create({
            channel_id => $args->{post_data}->{channel_id},
            message    => 'Pong',
        });
    }

    return 1;
}

sub gw_ws_error {
    my $self = shift;
    my $args = shift;

    if ($self->debug) {
        $self->logger->debugf('Oh no!: %s', $args->{message});
    }

    return 1;
}

sub gw_message_no_event {
    my $self = shift;
    my $args = shift;

    if ($self->debug) {
        $self->logger->debug('Received a message without an event. Probably a ping.');
    }

    return 1;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::Example::Bot

=head1 DESCRIPTION

An example Mattermost WebSocket bot using C<WebService::Mattermost>. The bot connects
to the network, and responds to "Ping" messages with "Pong".

=head2 USAGE

    #!/usr/bin/env perl

    use strict;
    use warnings;

    use WebService::Mattermost::V4::Example::Bot;

    my $bot = WebService::Mattermost::V4::Example::Bot->new({
        username => 'usernamehere',
        password => 'passwordhere',
        base_url => 'https://my.mattermost.server.com/api/v4/'
        debug    => 1, # optional
    })->start();

The C<gw_> methods in this class are events emitted by
C<WebService::Mattermost::V4::Client>. Each one has one argument passed which is a HashRef
of decoded data from the Mattermost server.

=head2 METHODS

=over 4

=item C<gw_ws_started()>

Triggered when the bot connects to the Mattermost gateway.

=item C<gw_ws_finished()>

Triggered when the connection to the gateway closes.

=item C<gw_message()>

Triggered when a message with an event is received from the gateway.

=item C<gw_ws_error()>

Triggered when an error is received from the gateway.

=item C<gw_message_no_event()>

Triggered when a message without an event is received from the gateway.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

