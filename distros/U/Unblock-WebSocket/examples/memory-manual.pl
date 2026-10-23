use strict;
use warnings;
use Unblock::WebSocket::Client;
use Unblock::WebSocket::Server;

# Application: WebSocket handlers. No transport object is attached.
my $server = Unblock::WebSocket::Server->new(
    on_message => sub {
        my ($ws, $bytes, $type) = @_;
        $ws->send_text("echo:$bytes");
    },
);

my $client = Unblock::WebSocket::Client->new(
    on_message => sub {
        my ($ws, $bytes, $type) = @_;
        print "received: $bytes\n";
    },
);

# Transport integration: a real framework would write each output
# buffer to its own socket and feed bytes read from the peer.
sub transfer {
    my ($from, $to) = @_;
    my $moved = 0;

    while ($from->want_write) {
        my $wire = $from->output;
        last unless length $wire;
        $to->input($wire);
        ++$moved;
    }
    return $moved;
}

$client->send_text('hello');
for (1 .. 10) {
    my $moved = transfer($client, $server);
    $moved += transfer($server, $client);
    last unless $moved;
}

$client->close;
for (1 .. 10) {
    my $moved = transfer($client, $server);
    $moved += transfer($server, $client);
    last unless $moved;
}

die "Close handshake failed\n"
    unless $client->close_complete && $server->close_complete;
