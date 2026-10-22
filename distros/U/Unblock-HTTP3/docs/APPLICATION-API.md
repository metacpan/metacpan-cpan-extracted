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

## Incoming body lifecycle

Buffered incoming bodies are the standalone engine default. Each Client or
Server accepts `receive_body => 'buffered'` and a positive
`max_buffered_body_bytes` limit (64 MiB by default). When body reception
successfully completes, the same canonical Uniform message receives its final
body before it is frozen and before the body-completion callback. Empty bodies
remain empty strings, not undefined. A buffered-body overflow fails only its
HTTP/3 stream and discards that stream's retained bytes.

For streaming reception, register `on_data` while handling the incoming
headers, before any body bytes arrive:

```perl
my $server = Unblock::HTTP3::Server->new(
    quic => $quic,
    on_request => sub {
        my ($tx, $request) = @_;
        $tx->on_data(sub {
            my ($tx, $bytes) = @_;
            process_request_chunk($bytes);
        });
        $tx->on_finish(sub {
            my ($tx) = @_;
            record_terminal_state($tx->state, $tx->error);
        });
    },
);
```

The client can pass `on_data => sub { ... }` and `on_finish => sub { ... }`
directly in `request()`, or register them during `on_response`. `on_data`
receives decoded HTTP body payload octets; it does not decode content
encodings. It disables whole-body accumulation for that transaction. The old
`on_body` remains available, but must not be combined with `on_data`.
An `on_finish` callback fires once after complete, cancelled, or error
terminal state and after applicable completion/error callbacks. Terminal
notification is distinct from incoming body completion and does not alter
the native Transaction's identity.

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
