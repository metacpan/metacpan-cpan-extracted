# Unblock::HTTP3

[![CPAN version](https://badge.fury.io/pl/Unblock-HTTP3.svg)](https://metacpan.org/dist/Unblock-HTTP3)
[![CPANTS Kwalitee](https://cpants.cpanauthors.org/dist/Unblock-HTTP3.svg)](https://cpants.cpanauthors.org/dist/Unblock-HTTP3)
[![CI](https://github.com/haxmeister/perl-Unblock-HTTP3/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/haxmeister/perl-Unblock-HTTP3/actions/workflows/test.yml)
[![HTTP/3 interop](https://github.com/haxmeister/perl-Unblock-HTTP3/actions/workflows/interop.yml/badge.svg?branch=main)](https://github.com/haxmeister/perl-Unblock-HTTP3/actions/workflows/interop.yml)
[![License](https://img.shields.io/cpan/l/Unblock-HTTP3.svg)](https://github.com/haxmeister/perl-Unblock-HTTP3/blob/main/LICENSE)
[![Perl](https://img.shields.io/badge/perl-5.20%2B-blue.svg)](https://www.perl.org/)
[![nghttp3](https://img.shields.io/badge/nghttp3-1.18.0-blue.svg)](https://github.com/ngtcp2/nghttp3)
[![HTTP/3](https://img.shields.io/badge/HTTP%2F3-RFC%209114-blue.svg)](https://www.rfc-editor.org/rfc/rfc9114)

Unblock::HTTP3 is a non-blocking HTTP/3 protocol engine for Perl.

HTTP/3 is HTTP carried over QUIC. Unblock::HTTP3 handles the HTTP/3 layer while
Net::QUIC handles QUIC and TLS.

```text
application or HTTP library
        |
  Uniform::HTTP messages
        |
   Unblock::HTTP3
        |
      Net::QUIC
        |
        UDP
```

Unblock::HTTP3 does not own a UDP socket, timer, TLS configuration, or event
loop. Those stay below Net::QUIC, so the HTTP/3 engine can be used with
different operating systems and event loops.

Uniform::HTTP supplies the request and response objects. Alien::nghttp3
supplies libnghttp3 for HTTP/3 framing and QPACK.

## Installation

From CPAN:

```text
cpanm Unblock::HTTP3
```

Unblock::HTTP3 0.03 requires:

```text
Perl            5.20+
Alien::nghttp3  0.01+
Net::QUIC       0.04+
Uniform::HTTP   0.06+
```

## Start here

Most code works with three things:

- `Unblock::HTTP3::Connection` - one HTTP/3 connection
- `Unblock::HTTP3::Transaction` - one request and its response
- `Uniform::HTTP::Request` and `Uniform::HTTP::Response` - HTTP messages

Unblock::HTTP3 uses the canonical Uniform message classes directly. HTTP/3
priority, reset, and STOP_SENDING state live on the Transaction rather than on
the message object.

An HTTP/3 Connection wraps an existing `Net::QUIC::Connection`:

```perl
use Unblock::HTTP3::Connection;

my $h3 = Unblock::HTTP3::Connection->client(
    quic => $quic,
);

$h3->start;
```

Your event-loop adapter continues to drive Net::QUIC. Unblock::HTTP3 never
blocks waiting for network activity.

## Native consumers

XS event frameworks and HTTP libraries can use the optional
`Unblock::HTTP3::NativeABI` interface.

It provides a versioned C operations table for the common Connection and
Transaction path while keeping normal `Unblock::HTTP3::Connection`,
`Unblock::HTTP3::Transaction`, and canonical `Uniform::HTTP` objects.

The native consumer ABI does not expose libnghttp3 internals and does not
replace Net::QUIC's transport responsibilities.

See `docs/NATIVE-ABI.md`.

## Sending a request

A client can submit a normal `Uniform::HTTP::Request`:

```perl
use Uniform::HTTP::Request;

my $request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/',
    scheme    => 'https',
    authority => 'example.com',
);

my $tx = $h3->request($request);
```

When the final response headers arrive, the Transaction becomes available from
the Connection:

```perl
while (my $ready = $h3->next_transaction) {
    my $response = $ready->response;

    print $response->status, "\n";
    print $response->body if $response->has_buffered_body;
}
```

Many Transactions can be active at once. Each Transaction keeps its own request
and response paired even when responses arrive out of order.

## Receiving a request

A server receives new requests as Transactions:

```perl
while (my $tx = $h3->next_transaction) {
    my $request  = $tx->request;
    my $response = $tx->response;

    $response->status(200);
    $response->header('Content-Type', 'text/plain');
    $response->body("hello\n");

    $tx->send_response;
}
```

The server-side Response is mutable until it is sent.

## Bodies

Buffered bodies are the default.

A buffered request or response body lives on the Uniform message object:

```perl
my $body = $response->body;
```

For large or incremental bodies, use streaming instead.

A server can stream a response:

```perl
my $body = $tx->response_body(
    on_drain  => sub { ... },
    on_cancel => sub { ... },
);

$body->write($chunk);
$body->complete;
```

`write()` returns false when the bytes were accepted but the producer should
pause until `on_drain` runs.

A client can receive a response without buffering the complete body:

```perl
my $tx = $h3->request(
    $request,
    receive_body => {
        on_data => sub {
            my ($reader, $chunk) = @_;
            process($chunk);
        },
        on_end => sub {
            my ($reader) = @_;
            ...
        },
    },
);
```

Streaming receive credit is returned as the application consumes data.

## Trailers and informational responses

Request and response trailers are supported.

Uniform::HTTP keeps trailers separate from normal headers and preserves field
order and duplicates.

Servers can also send 1xx informational responses before the final response:

```perl
$tx->send_informational(
    Uniform::HTTP::Response->new(
        status => 103,
    ),
);
```

HTTP/3 does not use status 101.

## CONNECT

Basic CONNECT tunnels are supported.

Generic Extended CONNECT is also supported. A server enables it with:

```perl
my $h3 = Unblock::HTTP3::Connection->server(
    quic                    => $quic,
    enable_extended_connect => 1,
);
```

An Extended CONNECT request uses the Uniform `protocol` field.

Unblock::HTTP3 does not assign meaning to protocol names. Higher-level modules
decide what protocols such as WebTransport, WebSocket, or MASQUE mean.

Extended CONNECT Transactions can also use the generic RFC 9297 Capsule
Protocol through:

```perl
my $capsules = $tx->capsules;
```

## HTTP Datagrams

RFC 9297 HTTP Datagrams are supported over Net::QUIC's QUIC DATAGRAM support.

Enable them on the HTTP/3 connection:

```perl
my $h3 = Unblock::HTTP3::Connection->client(
    quic                  => $quic,
    enable_http_datagrams => 1,
);
```

A client marks a request as using HTTP Datagrams when it creates the
Transaction:

```perl
my $tx = $h3->request(
    $request,
    datagrams => 1,
);

$tx->send_datagram($bytes);
```

The Transaction also provides `next_datagram`, `on_datagram`, and
`max_datagram_payload_size`.

The higher-level protocol still decides what the Datagram payload means.

## ORIGIN

Servers can advertise the RFC 9412 Origin Set extension:

```perl
my $h3 = Unblock::HTTP3::Connection->server(
    quic => $quic,
    origins => [
        'https://example.com',
        'https://www.example.com',
    ],
);
```

A client can read the advertised entries with:

```perl
my $origins = $h3->peer_origins;
```

Before a complete ORIGIN frame arrives this returns `undef`. An explicit empty
ORIGIN frame returns an empty array reference. Invalid received origin entries
are ignored.

## Request priority

RFC 9218 priority can be supplied through the normal Uniform Priority header:

```perl
my $request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/',
    scheme    => 'https',
    authority => 'example.com',
    headers   => [
        [ Priority => 'u=1, i' ],
    ],
);
```

It can be inspected or changed on a live Transaction:

```perl
$tx->priority(
    urgency     => 0,
    incremental => 0,
);
```

Urgency is from 0 through 7, where 0 is most urgent.

## 0-RTT

Net::QUIC owns QUIC/TLS early-data state. Unblock::HTTP3 owns the remembered
HTTP/3 SETTINGS needed to decide what can safely be sent before the new server
SETTINGS frame arrives.

Save both values from the same successful session:

```perl
my $quic_state = $quic->early_data_state;
my $h3_state   = $h3->peer_settings_state;
```

On a resumed connection, give each value back to the layer that created it.

An HTTP/3 request sent before the handshake finishes must opt in explicitly:

```perl
my $tx = $h3->request(
    $request,
    early_data => 1,
);
```

0-RTT can be replayed. Unblock::HTTP3 does not automatically retry an early
request if QUIC rejects it.

On the server, early request bytes can be parsed before the handshake finishes,
but the Transaction is not exposed to application code until the QUIC
handshake completes and the early data has not been rejected. Early HTTP
Datagrams are bounded and held with the Transaction until that point. This is
the safe default required by the HTTP early-data replay rules.

See `Unblock::HTTP3::Connection` and `docs/ARCHITECTURE.md` for the complete
SETTINGS persistence rules.

## Correctness and limits

Unblock::HTTP3 validates HTTP/3 message rules before sending and while receiving.

This includes:

- pseudo-header and routing rules
- Host and `:authority`
- Content-Length
- trailers
- bodyless responses
- CONNECT rules
- peer field-section limits

It also provides configurable limits for buffered bodies, streaming receive
queues, field sections, QPACK, and HTTP Datagram queues.

Protocol errors are kept at the narrowest correct scope when possible. A bad
request stream does not automatically destroy unrelated multiplexed requests.

The normative coverage audit and native-library boundaries are documented in
`docs/RFC-COMPLIANCE.md`.

## Extensions

The engine provides generic extension hooks without assigning application
semantics to them:

- extension SETTINGS
- extension unidirectional streams
- RFC 9412 ORIGIN
- Extended CONNECT protocol names
- Capsules
- HTTP Datagrams

This is the intended foundation for higher-level HTTP/3 protocols.

## What Unblock::HTTP3 does not own

Unblock::HTTP3 does not own:

- UDP sockets
- TLS
- QUIC packet processing
- congestion control
- retransmission
- QUIC connection migration
- timers
- event-loop scheduling
- web-framework behavior

Those responsibilities stay in Net::QUIC, the event-loop adapter, or the
application.

HTTP/3 Server Push is not exposed because the libnghttp3 version used by this
release does not implement it.

## Testing

The normal test suite uses real kernel UDP sockets, TLS, QUIC, and HTTP/3.

CI tests released CPAN dependencies on Perl 5.20, 5.28, 5.36, and 5.44 and
also validates the built distribution.

Interoperability CI covers both directions: the Unblock::HTTP3 client talks to
independent public HTTP/3 servers, and a pinned quic-go client drives an
Unblock::HTTP3 server over real loopback UDP/TLS/QUIC/HTTP/3. These tests stay
outside normal CPAN installation tests.

## More documentation

- `Unblock::HTTP3::Connection` - connection setup and configuration
- `Unblock::HTTP3::Transaction` - one request/response stream
- `Unblock::HTTP3::Body::Stream` - outgoing streaming bodies
- `Unblock::HTTP3::Body::Reader` - incoming streaming bodies
- `Unblock::HTTP3::Capsule` - RFC 9297 Capsules
- `Unblock::HTTP3::Extension::Stream` - generic extension streams
- `Unblock::HTTP3::NativeABI` - optional native consumer ABI
- `docs/NATIVE-ABI.md` - C ABI discovery, ownership, and integration rules
- `docs/ARCHITECTURE.md` - protocol ownership and internal data flow
- `docs/RFC-COMPLIANCE.md` - standards coverage and native-library limits

## License

MIT.
