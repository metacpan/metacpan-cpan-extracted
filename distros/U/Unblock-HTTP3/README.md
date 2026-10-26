# Unblock::HTTP3

[![CPAN version](https://badge.fury.io/pl/Unblock-HTTP3.svg)](https://metacpan.org/dist/Unblock-HTTP3)
[![CPANTS Kwalitee](https://cpants.cpanauthors.org/dist/Unblock-HTTP3.svg)](https://cpants.cpanauthors.org/dist/Unblock-HTTP3)
[![CI](https://github.com/haxmeister/perl-Unblock-HTTP3/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/haxmeister/perl-Unblock-HTTP3/actions/workflows/test.yml)
[![HTTP/3 interop](https://github.com/haxmeister/perl-Unblock-HTTP3/actions/workflows/interop.yml/badge.svg?branch=main)](https://github.com/haxmeister/perl-Unblock-HTTP3/actions/workflows/interop.yml)
[![License](https://img.shields.io/cpan/l/Unblock-HTTP3.svg)](https://github.com/haxmeister/perl-Unblock-HTTP3/blob/main/LICENSE)
[![Perl](https://img.shields.io/badge/perl-5.20%2B-blue.svg)](https://www.perl.org/)

Unblock::HTTP3 is a non-blocking HTTP/3 protocol engine for Perl.

It handles HTTP/3 framing, QPACK, request streams, trailers, informational
responses, Extended CONNECT, HTTP Datagrams, Capsules, priorities, graceful
shutdown, and replay-aware 0-RTT state.

It does not own UDP sockets, TLS, timers, or an event loop. Net::QUIC owns the
QUIC transport.

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

## Installation

From CPAN:

```text
cpanm Unblock::HTTP3
```

Unblock::HTTP3 requires:

```text
Perl            5.20+
Alien::nghttp3  0.01+
Net::QUIC       0.05+
Uniform::HTTP   0.06+
```

Version 0.14 fixes CONNECT transaction completion when the outgoing request
body finishes synchronously. Exactly-once terminal callbacks no longer
depend on a later network event. The API and native ABI are unchanged.
See [Changes](Changes) for earlier releases.

## Start here

The public API is built around three objects:

- `Unblock::HTTP3::Client` - one client HTTP/3 connection
- `Unblock::HTTP3::Server` - one server HTTP/3 connection
- `Unblock::HTTP3::Transaction` - one request and response exchange

The common application vocabulary intentionally matches the other Unblock HTTP
engines:

```text
Client->new
Server->new
request()
respond()
write()
end()
send_informational()
```

HTTP/3 protocol concepts keep their HTTP/3 names.

Exact canonical `Uniform::HTTP::Request` and `Uniform::HTTP::Response`
objects use the Uniform::HTTP native fast path. Uniform-compatible adapters and
subclasses use the portable Perl message contract.

## Client

```perl
use Unblock::HTTP3::Client;

my $client = Unblock::HTTP3::Client->new(
    quic => $quic,
);

$client->start;

my $transaction = $client->request(
    method    => 'GET',
    target    => '/',
    scheme    => 'https',
    authority => 'example.com',

    on_response => sub {
        my ($transaction, $response) = @_;
        print $response->status, "\n";
    },

    on_body => sub {
        my ($transaction, $response, $bytes) = @_;
        process_bytes($bytes);
    },

    on_complete => sub {
        my ($transaction) = @_;
        print "done\n";
    },
);
```

Many Transactions can be active on one Client at the same time.

The existing pull interface remains available through `next_transaction()`
and `next_informational()` for integrations that prefer polling. Pull-only
notifications retain a strong Transaction reference until retrieved.
When callbacks deliver a Transaction, its optional pull-queue notification
is weak: it remains accessible while the application or active engine holds
the Transaction, but it does not retain completed response bodies indefinitely.
Callback handlers should retain the Transaction themselves if they need it
after completion. The Server follows the same rule for `on_request`.

## Server

```perl
use Unblock::HTTP3::Server;

my $server = Unblock::HTTP3::Server->new(
    quic => $quic,

    on_request => sub {
        my ($transaction, $request) = @_;

        $transaction->respond(
            status => 200,
            body   => "hello\n",
        );
    },
);

$server->start;
```

`on_body` receives request body chunks. `on_request_end` runs after the
request body and trailers have completed.

## Event-loop integration

Use Net::QUIC::Driver to connect an event loop's UDP socket and timer to
QUIC. Unblock::HTTP3 attaches to each ready Net::QUIC::Connection; it does not
replace the Driver or accept raw TCP-style input bytes.

See [the installed integration guide](lib/Unblock/HTTP3/Integration.pm) and
[the application API guide](docs/APPLICATION-API.md). Complete Linux::Event
programs are in [server](examples/linux-event-server.pl) and
[client](examples/linux-event-client.pl). The transport examples require Linux::Event 0.117 or later and Perl 5.36
or later. Neither is a distribution dependency.

## Incoming body reception

Incoming request and response bodies are buffered by default, with a finite
64 MiB per-transaction limit. Configure `max_buffered_body_bytes` on the
Client or Server to reduce this limit. The complete body is installed on the
same Uniform message object before the body-completion callback; an empty
completed body is the empty string. Header callbacks run before body arrival.

Register `on_data` at request creation or during the incoming-header callback
to receive chunks without retaining a second full body. For example:

```perl
my $tx = $client->request(
    method    => 'GET',
    target    => '/',
    scheme    => 'https',
    authority => 'example.com',
    on_data   => sub {
        my ($tx, $bytes) = @_;
        process_bytes($bytes);
    },
    on_finish => sub {
        my ($tx) = @_;
        report_terminal_state($tx->state, $tx->error);
    },
);
```

On a Server, call `$tx->on_data(sub { ... })` inside `on_request` to select
streaming for that incoming request. Do not combine `on_data` with the legacy
`on_body` callback. Registration after body delivery has started is rejected.
`on_finish` runs once after the transaction reaches complete, cancelled, or
error state; it is not merely an incoming-body completion event. A receive
limit failure resets the affected HTTP/3 stream without failing unrelated
transactions. Consult the Client, Server and Transaction POD for details.

## Streaming bodies

Buffered bodies can live directly on the Uniform message object.

For a streaming client request:

```perl
my $transaction = $client->request(
    $request,
    stream_body => 1,
    on_drain => sub {
        my ($transaction) = @_;
        produce_more($transaction);
    },
);

$transaction->write($chunk);
$transaction->end($last_chunk);
```

A streaming server response uses the same Transaction API:

```perl
$transaction->respond(
    $response,
    stream_body => 1,
    on_drain => sub {
        my ($transaction) = @_;
        produce_more($transaction);
    },
);

$transaction->write($chunk);
$transaction->end;
```

For advanced HTTP/3 body control, `Body::Stream` and `Body::Reader` remain
available. They expose explicit receive credit, cancellation, and body-specific
callbacks without changing the common Transaction API.

## Informational responses

A server can send a 1xx response before the final response:

```perl
$transaction->send_informational(status => 103);

$transaction->respond($final_response);
```

HTTP/3 does not use status 101.

## Transaction state

The common lifecycle methods are:

```text
state
error
is_complete
is_cancelled
is_error
is_terminal
```

HTTP/3-specific reset and STOP_SENDING details remain available separately on
the Transaction.

## CONNECT, Capsules, and Datagrams

Ordinary CONNECT and generic Extended CONNECT are supported.

Extended CONNECT uses the Uniform `protocol` field. Higher-level modules
decide what a protocol such as WebSocket, WebTransport, or MASQUE means.

An Extended CONNECT Transaction can use the RFC 9297 Capsule Protocol through:

```perl
my $capsules = $transaction->capsules;
```

RFC 9297 HTTP Datagrams use Net::QUIC DATAGRAM support. Enable them on the
Client or Server with:

```perl
enable_http_datagrams => 1
```

A client marks a request as using Datagrams with:

```perl
my $transaction = $client->request(
    $request,
    datagrams => 1,
);
```

The Transaction provides `send_datagram()`, `next_datagram()`,
`on_datagram()`, and `max_datagram_payload_size()`.

## Priority and ORIGIN

RFC 9218 priority state is available through `Transaction->priority()`.

Servers can advertise RFC 9412 origins with the `origins` constructor option.
Clients read the received set with `peer_origins()`.

## 0-RTT

Net::QUIC owns QUIC/TLS early-data state. Unblock::HTTP3 owns the remembered
HTTP/3 SETTINGS needed to validate early requests.

Save the QUIC and HTTP/3 state from the same successful session:

```perl
my $quic_state = $quic->early_data_state;
my $h3_state   = $client->peer_settings_state;
```

An early client request must opt in explicitly:

```perl
my $transaction = $client->request(
    $request,
    early_data => 1,
);
```

0-RTT can be replayed. Unblock::HTTP3 does not automatically retry a rejected
early request.

## Native integrations

XS event frameworks and HTTP libraries can use
`Unblock::HTTP3::NativeABI`.

Native integrations can discover the installed ABI with:

```text
definition
native_include_dir
header_path
c_header
```

ABI version 1 accepts exact `Unblock::HTTP3::Client`,
`Unblock::HTTP3::Server`, and `Unblock::HTTP3::Transaction` objects.
Adapters and subclasses use the portable Perl API.

The native ABI does not expose libnghttp3 internals and does not take ownership
of the QUIC transport.

See `docs/NATIVE-ABI.md`.

## What Unblock::HTTP3 does not own

Unblock::HTTP3 does not own:

- UDP sockets
- DNS
- TLS
- QUIC packet processing
- congestion control
- retransmission
- connection migration
- timers
- event loops
- connection pools
- redirects
- cookies
- authentication policy
- retry policy
- WebSocket, WebTransport, or MASQUE semantics

Those belong to Net::QUIC, the event-loop adapter, the application, or a
higher-level protocol module.

## Testing

The normal suite uses real kernel UDP sockets, TLS, QUIC, and HTTP/3.

CI tests released dependencies on several Perl versions and validates the built
distribution. Separate interoperability tests cover both client and server
directions against independent HTTP/3 implementations.

## More documentation

- `Unblock::HTTP3::Client`
- `Unblock::HTTP3::Server`
- `Unblock::HTTP3::Transaction`
- `Unblock::HTTP3::Body::Stream`
- `Unblock::HTTP3::Body::Reader`
- `Unblock::HTTP3::NativeABI`
- `docs/ARCHITECTURE.md`
- `docs/NATIVE-ABI.md`
- `docs/RFC-COMPLIANCE.md`

## License

MIT.
