package WebService::Mattermost::V4::Client;

use Encode 'encode';
use Mojo::IOLoop;
use Mojo::JSON qw(decode_json encode_json);
use Moo;
use MooX::HandlesVia;
use Types::Standard qw(ArrayRef Bool InstanceOf Int Maybe Str);

extends 'WebService::Mattermost';
with    qw(
    WebService::Mattermost::Role::UserAgent
    Role::EventEmitter
);

################################################################################

has _events       => (is => 'ro', isa => ArrayRef,                      lazy => 1, builder => 1);
has _ua           => (is => 'rw', isa => InstanceOf['Mojo::UserAgent'], lazy => 1, builder => 1);
has ioloop        => (is => 'rw', isa => InstanceOf['Mojo::IOLoop'],    lazy => 1, builder => 1);
has websocket_url => (is => 'ro', isa => Str,                           lazy => 1, builder => 1);

has ws => (is => 'rw', isa => Maybe[InstanceOf['Mojo::Base']]);

has debug                  => (is => 'ro', isa => Bool, default => 0);
has ignore_self            => (is => 'ro', isa => Bool, default => 1);
has ping_interval          => (is => 'ro', isa => Int,  default => 15);
has reconnection_wait_time => (is => 'ro', isa => Int,  default => 2);

has last_seq => (is => 'rw', isa => Int,  default => 1,
    handles_via => 'Number',
    handles     => {
        inc_last_seq => 'add',
    });

has loops => (is => 'rw', isa => ArrayRef[InstanceOf['Mojo::IOLoop']], default => sub { [] },
    handles_via => 'Array',
    handles     => {
        add_loop    => 'push',
        clear_loops => 'clear',
    });

################################################################################

sub BUILD {
    my $self = shift;

    $self->authenticate(1);
    $self->_try_authentication();

    # Set up expected subroutines for a child class to catch. The events can
    # also be caught raw in a script.
    foreach my $emission (@{$self->_events}) {
        # Values from events must be set up in child class
        if ($self->can($emission)) {
            $self->on($emission, sub { shift; $self->$emission(@_) });
        }
    }

    return 1;
}

sub start {
    my $self = shift;

    $self->_connect();
    $self->ioloop->start unless $self->ioloop->is_running();

    return;
}

sub message_has_content {
    my $self = shift;
    my $args = shift;

    return $args->{post_data} && $args->{post_data}->{message};
}

################################################################################

sub _connect {
    my $self = shift;

    $self->_ua->on(start => sub { $self->_on_start(@_) });

    $self->_ua->websocket($self->websocket_url => sub {
        my ($ua, $tx) = @_;

        $self->ws($tx);

        unless ($tx->is_websocket) {
            $self->logger->fatal('WebSocket handshake failed');
        }

        $self->emit(gw_ws_started => {});

        $self->logger->debug('Adding ping loop');
        $self->add_loop($self->ioloop->recurring(15 => sub { $self->_ping($tx) }));

        $tx->on(error   => sub { $self->_on_error(@_)   });
        $tx->on(finish  => sub { $self->_on_finish(@_)  });
        $tx->on(message => sub { $self->_on_message(@_) });
    });

    return 1;
}

sub _ping {
    my $self = shift;
    my $tx   = shift;

    if ($self->debug) {
        $self->logger->debugf('[Seq: %d] Sending ping', $self->last_seq);
    }

    return $tx->send(encode_json({
        seq    => $self->last_seq,
        action => 'ping',
    }));
}

sub _on_start {
    my $self = shift;
    my $ua   = shift;
    my $tx   = shift;

    if ($self->debug) {
        $self->logger->debugf('UserAgent connected to %s', $tx->req->url->to_string);
        $self->logger->debugf('Auth token: %s', $self->auth_token);
    }

    # The methods here are from the UserAgent role
    $tx->req->headers->header('Cookie'        => $self->mmauthtoken($self->auth_token));
    $tx->req->headers->header('Authorization' => $self->bearer($self->auth_token));
    $tx->req->headers->header('Keep-Alive'    => 1);

    return 1;
}

sub _on_finish {
    my $self   = shift;
    my $tx     = shift;
    my $code   = shift;
    my $reason = shift || 'Unknown';

    $self->logger->infof('WebSocket connection closed: [%d] %s', $code, $reason);
    $self->logger->infof('Reconnecting in %d seconds...', $self->reconnection_wait_time);

    $self->ws->finish;
    $self->emit(gw_ws_finished => { code => $code, reason => $reason });

    # Delay the reconnection a little
    Mojo::IOLoop->timer($self->reconnection_wait_time => sub {
        return $self->_reconnect();
    });
}

sub _on_message {
    my $self    = shift;
    my $tx      = shift;
    my $input   = shift;

    return unless $input;

    my $message = decode_json(encode('utf8', $input));

    if ($message->{seq}) {
        $self->logger->debugf('[Seq: %d]', $message->{seq}) if $self->debug;
        $self->last_seq($message->{seq});
    }

    return $self->_on_non_event($message) unless $message && $message->{event};

    my $message_args = { message => $message };

    if ($message->{data}->{post}) {
        my $post_data = decode_json(encode('utf8', $message->{data}->{post}));

        # Early return if the message is from the bot's own user ID (to halt
        # recursion)
        return if $self->ignore_self && $post_data->{user_id} eq $self->user_id;

        $message_args->{post_data} = $post_data;
    }

    $self->emit(gw_message => $message_args);

    if ($message->{event} eq 'hello') {
        if ($self->debug) {
            $self->logger->debug('Received "hello" event, sending authentication challenge');
        }

        $tx->send(encode_json({
            seq    => 1,
            action => 'authentication_challenge',
            data   => { token => $self->auth_token },
        }));
    }

    return 1;
}

sub _on_non_event {
    my $self    = shift;
    my $message = shift;

    if ($self->debug && $message->{data} && $message->{data}->{text}) {
        $self->logger->debugf('[Seq: %d] Received %s', $self->last_seq, $message->{data}->{text});
    }

    return $self->emit(gw_message_no_event => $message);
}

sub _on_error {
    my $self    = shift;
    my $ws      = shift;
    my $message = shift;

    $self->emit(gw_ws_error => { message => $message });

    return $ws->finish($message);
}

sub _reconnect {
    my $self = shift;

    # Reset things which have been altered during the course of the last
    # connection
    $self->last_seq(1);
    $self->_try_authentication();
    $self->_clean_up_loops();
    $self->ws(undef);
    $self->_ua($self->_build__ua);

    return $self->_connect();
}

sub _clean_up_loops {
    my $self = shift;

    foreach my $loop (@{$self->loops}) {
        $self->ioloop->remove($loop);
    }

    return $self->clear_loops();
}

################################################################################

sub _build__events {
    return [ qw(
        gw_ws_error
        gw_ws_finished
        gw_ws_started
        gw_message
        gw_message_no_event
    ) ];
}

sub _build__ua { Mojo::UserAgent->new }

sub _build_ioloop { Mojo::IOLoop->singleton }

sub _build_websocket_url {
    my $self = shift;

    # Convert the API URL to the WebSocket URL
    my $ws_url = $self->base_url;

    if ($ws_url !~ /\/$/) {
        $ws_url .= '/';
    }

    $ws_url .= 'websocket';
    $ws_url =~ s/^http(?:s)?/wss/s;

    return $ws_url;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::WS::v4 - WebSocket gateway to Mattermost

=head1 DESCRIPTION

This class connects to Mattermost via the WebSocket gateway and can either be
extended in a child class, or used in a script.

=head2 USAGE

=head3 FROM A SCRIPT

    use WebService::Mattermost::V4::Client;

    my $bot = WebService::Mattermost::V4::Client->new({
        username => 'usernamehere',
        password => 'password',
        base_url => 'https://mattermost.server.com/api/v4/',

        # Optional arguments
        debug       => 1, # Show extra connection information
        ignore_self => 0, # May cause recursion!
    });

    $bot->on(message => sub {
        my ($bot, $args) = @_;

        # $args contains the decoded message content
    });

    $bot->start(); # Add me last

=head3 EXTENSION

See C<WebService::Mattermost::V4::Example::Bot>.

=head2 EVENTS

Events are either available to be caught with C<on> in scripts, or have methods
which can be overridden in child classes.

=over 4

=item C<gw_ws_started>

The bot connected to the Mattermost gateway. Can be overridden as
C<gw_ws_started()>.

=item C<gw_ws_finished>

The bot disconnected from the Mattermost gateway. Can be overridden as
C<gw_ws_finished()>.

=item C<gw_message>

The bot received a message. Can be overridden as C<gw_message()>.

=item C<gw_ws_error>

The bot received an error. Can be overridden as C<gw_error()>.

=item C<gw_message_no_event>

The bot received a message without an event (which is usually a "ping" item).
Can be overridden as C<gw_message_no_event()>.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

