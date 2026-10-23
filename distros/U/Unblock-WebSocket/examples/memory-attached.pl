use strict;
use warnings;
use Unblock::WebSocket::Client;
use Unblock::WebSocket::Server;

# ------------------------------------------------------------
# Transport integration. Real frameworks would send these bytes
# through their own ordered socket, stream, or HTTP body queue.
# ------------------------------------------------------------

package Example::Host;

sub new { bless { outgoing => [], finished => 0 }, shift }

sub unblock_send {
    my ($self, $bytes) = @_;
    push @{ $self->{outgoing} }, $bytes;
    return; # Entire buffer accepted. No congestion signal.
}

sub unblock_finish {
    ++$_[0]{finished};
    return;
}

sub unblock_abort {
    my ($self, $reason) = @_;
    die "transport aborted: $reason";
}

sub deliver_to {
    my ($self, $peer) = @_;
    my $count = 0;
    for my $bytes (splice @{ $self->{outgoing} }) {
        $peer->input($bytes);
        ++$count;
    }
    return $count;
}
package main;

# ------------------------------------------------------------
# Application usage. Imagine the HTTP opening handshake has
# already been validated by Unblock::WebSocket::Handshake.
# ------------------------------------------------------------

my $client_host = Example::Host->new;
my $server_host = Example::Host->new;

my $server = Unblock::WebSocket::Server->new(
    transport => $server_host,
    on_message => sub {
        my ($ws, $payload, $type) = @_;
        $ws->send_text("echo:$payload");
    },
);

my $client = Unblock::WebSocket::Client->new(
    transport => $client_host,
    on_message => sub {
        my ($ws, $payload, $type) = @_;
        print "received: $payload\n";
    },
);

$client->send_text('hello');

for (1 .. 10) {
    my $moved = $client_host->deliver_to($server);
    $moved += $server_host->deliver_to($client);
    last unless $moved;
}

$client->close;

for (1 .. 10) {
    my $moved = $client_host->deliver_to($server);
    $moved += $server_host->deliver_to($client);
    last unless $moved;
}

die "Close handshake failed\n"
    unless $client->close_complete
        && $server->close_complete
        && $client_host->{finished}
        && $server_host->{finished};
