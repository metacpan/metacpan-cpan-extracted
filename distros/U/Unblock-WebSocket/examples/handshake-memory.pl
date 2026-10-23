use strict;
use warnings;

use Unblock::WebSocket::Handshake;
use Unblock::WebSocket::Client;
use Unblock::WebSocket::Server;

# This program demonstrates the handshake and message flow in memory.
# A real HTTP implementation must carry the request and response over
# the network before WebSocket bytes can be exchanged.

# 1. Client prepares an HTTP WebSocket request.
my ($client_handshake, $request) =
    Unblock::WebSocket::Handshake->client_request(
        'ws://example.test/chat',
        http_version => '1.1',
        subprotocols => ['chat'],
    );

# 2. Server validates the request and builds the HTTP response.
my $server_handshake = Unblock::WebSocket::Handshake->server_accept(
    $request,
    subprotocols => ['chat'],
);
my $response = $server_handshake->server_response;

# 3. Client validates the response before accepting WebSocket traffic.
$client_handshake->validate_client_response($response);
die "HTTP handshake failed\n" unless $response->status == 101;

# 4. Both sides create their WebSocket engines. In a real application,
# each HTTP connection switches to its established WebSocket transport.
my $server = Unblock::WebSocket::Server->new(
    %{ $server_handshake->connection_options },
    on_message => sub {
        my ($ws, $message, $type) = @_;
        $ws->send_text("echo:$message");
    },
);

my $reply;
my $client = Unblock::WebSocket::Client->new(
    %{ $client_handshake->connection_options },
    on_message => sub {
        my ($ws, $message, $type) = @_;
        $reply = $message;
        print "received: $message\n";
    },
);

# Transport simulation only: move every complete outgoing wire buffer
# to the other endpoint. A real adapter reads and writes a socket or
# a streaming HTTP/2 or HTTP/3 transaction body instead.
sub transfer {
    my ($source, $destination) = @_;
    my $moved = 0;
    while ($source->want_write) {
        my $bytes = $source->output;
        $destination->input($bytes);
        ++$moved;
    }
    return $moved;
}

sub pump {
    my ($first, $second) = @_;
    for (1 .. 10) {
        my $moved = transfer($first, $second);
        $moved += transfer($second, $first);
        return unless $moved;
    }
    die "In-memory transfer did not settle\n";
}

$client->send_text('hello');
pump($client, $server);

die "Message was not delivered\n"
    unless defined($reply) && $reply eq 'echo:hello';

$client->close;
pump($client, $server);

die "Close handshake failed\n"
    unless $client->close_complete && $server->close_complete;
