# Application API in Unblock::HTTP3

Unblock::HTTP3 follows the same Client, Server, and Transaction vocabulary as
Unblock::HTTP1 and Unblock::HTTP2. It runs over an existing Net::QUIC connection
rather than accepting TCP/TLS wire bytes from a framework stream.

## Server application

```perl
use Unblock::HTTP3::Server;

my $server = Unblock::HTTP3::Server->new(
    quic => $quic,
    on_request => sub {
        my ($tx, $request) = @_;
        $tx->respond(status => 200, body => "hello\n");
    },
);

$server->start;
```

## Client application

```perl
use Unblock::HTTP3::Client;

my $client = Unblock::HTTP3::Client->new(quic => $quic);
$client->start;

my $tx = $client->request(
    method    => 'GET',
    target    => '/',
    scheme    => 'https',
    authority => 'example.test',
    on_response => sub {
        my ($tx, $response) = @_;
        print $response->status, "\n";
    },
);
```

Request and response objects from Uniform::HTTP are still accepted, and the
engine returns those canonical objects to callbacks. The named forms avoid
manual construction for common applications.

## Transport integration

The host framework owns its UDP socket and timers. Net::QUIC handles QUIC and
TLS 1.3. Unblock::HTTP3 handles HTTP/3 and registers QUIC stream callbacks
when `start()` is called.

The TCP-oriented `transport => $stream`, `input($bytes)` and `unblock_send()`
contract used by Unblock::HTTP1 and Unblock::HTTP2 is *not* suitable for HTTP/3
QUIC datagrams. The framework must instead integrate Net::QUIC correctly.
Do not feed UDP packets directly to an HTTP/3 Client or Server.

For the complete UDP and timer contract, read `Unblock::HTTP3::Integration`.
Working Linux::Event examples are in `examples/linux-event-client.pl` and
`examples/linux-event-server.pl`.

`Body::Stream`, `Body::Reader`, priority, Datagram, Capsule, Extended CONNECT,
and 0-RTT options remain available to advanced callers.
