package ZeroMQ::PubSub::Client;

use Moose;
extends 'ZeroMQ::PubSub';

use ZMQ::LibZMQ2;
use ZMQ::Constants ':all';
use JSON qw/encode_json decode_json/;
use Carp qw/croak/;
use List::Util qw/shuffle/;

# should only be used internally
has 'subscription_socket_connected' => ( is => 'rw', isa => 'Bool' );
has 'publish_socket_connected' => ( is => 'rw', isa => 'Bool' );

=head1 NAME

ZeroMQ::PubSub::Client - Connect to a PubSub server to send and receive events

=head1 SYNOPSIS

    use ZeroMQ::PubSub::Client;
    use Time::HiRes;

    my $client = ZeroMQ::PubSub::Client->new(
        publish_address   => 'tcp://127.0.0.1:4000',
        subscribe_address => 'tcp://127.0.0.1:5000',
        debug             => 1,
    );

    my $ping_start_time;

    # called when we receive our ping back
    $client->subscribe(ping => sub {
        # print round-trip latency
        my ($self, $params) = @_;
        print "Ping: " . (Time::HiRes::time() - $ping_start_time) . "s.\n";
    });

    # publish ping event
    $ping_start_time = Time::HiRes::time();
    $client->publish( ping => { 'time' => $ping_time } );

    # wait to receive our ping
    $client->poll_once;

=cut

# connect to subscription socket and prepare to receive events
sub _build_subscribe_sock {
    my ($self) = @_;

    my $sub_sock = zmq_socket($self->context, ZMQ_SUB);
    zmq_setsockopt($sub_sock, ZMQ_SUBSCRIBE, '');
    return $sub_sock;
}

# create a socket that can be used to publish events
sub _build_publish_sock {
    my ($self) = @_;

    my $pub_sock = zmq_socket($self->context, ZMQ_PUB);
    return $pub_sock;
}

=head1 ATTRIBUTES

=head2 publish_address

Address of event publishing socket. Must be in the form of
C<transport://addr>. See L<https://metacpan.org/module/ZeroMQ::Socket#bind>

=cut

has 'publish_address' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);


=head2 subscribe_address

Address of socket to receive events from. See above.

=cut

has 'subscribe_address' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

=head1 METHODS

=head2 connect_subscribe_sock

Connects to the subscription socket on the server. Automatically
called by C<subscribe()> and C<poll_once()>.

=cut

sub connect_subscribe_sock {
    my ($self) = @_;

    return if $self->subscription_socket_connected;

    my $addr = $self->subscribe_address or croak 'subscribe_address must be defined if you want to subscribe to events';

    $self->print_debug("Connecting to subscription socket $addr");
    zmq_connect($self->subscribe_sock, $addr);
    $self->subscription_socket_connected(1);
}


=head2 connect_publish_sock

Connects to the subscription socket on the server. Automatically
called by C<subscribe()> and C<poll_once()>.

=cut

sub connect_publish_sock {
    my ($self) = @_;

    return if $self->publish_socket_connected;

    my $addr = $self->publish_address or croak 'publish_address must be defined if you want to publish events';

    $self->print_debug("Connecting to event publishing socket $addr");
    zmq_connect($self->publish_sock, $addr);
    $self->publish_socket_connected(1);
}


=head2 poll_once

Blocks and waits for an event. Dispatches to event callbacks.

=cut

sub poll_once {
    my ($self) = @_;

    # make sure we're connected
    $self->connect_subscribe_sock;

    # receive and parse one message
    my $msg_raw = zmq_recv($self->subscribe_sock);
    my $msg_str = zmq_msg_data($msg_raw);
    my $msg = decode_json($msg_str);
    $self->dispatch_event($msg);
}

after 'subscribe' => sub {
    my ($self, $evt, $cb) = @_;

    $self->print_debug("Got subscriber for $evt");
    
    # make sure we are connected and listening for events
    $self->connect_subscribe_sock;
};


=head2 publish($event, $params)

Publishes $event to all subscribers on the server. This will block
while attempting to connect.

=cut

sub publish {
    my ($self, $evt, $params) = @_;

    $params ||= {};
    my $msg = {
        type   => $evt,
        params => $params,
    };

    # make sure we're connected
    $self->connect_publish_sock;

    my $json_str = encode_json($msg);
    my $res = zmq_send($self->publish_sock, $json_str);
    $self->print_debug("Published $evt, res=$res");

    return $res;
}

=head1 SEE ALSO

L<ZeroMQ::PubSub::Server>, L<ZeroMQ::PubSub>

=cut

__PACKAGE__->meta->make_immutable;

