# Unblock::HTTP2

[![CPAN version](https://badge.fury.io/pl/Unblock-HTTP2.svg)](https://metacpan.org/dist/Unblock-HTTP2)
[![CPANTS Kwalitee](https://cpants.cpanauthors.org/dist/Unblock-HTTP2.svg)](https://cpants.cpanauthors.org/dist/Unblock-HTTP2)
[![CI](https://github.com/haxmeister/perl-Unblock-HTTP2/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/haxmeister/perl-Unblock-HTTP2/actions/workflows/test.yml)
[![Interop](https://github.com/haxmeister/perl-Unblock-HTTP2/actions/workflows/interop.yml/badge.svg?branch=main)](https://github.com/haxmeister/perl-Unblock-HTTP2/actions/workflows/interop.yml)
[![License](https://img.shields.io/cpan/l/Unblock-HTTP2.svg)](https://github.com/haxmeister/perl-Unblock-HTTP2/blob/main/LICENSE)
[![Perl](https://img.shields.io/badge/perl-5.16%2B-blue.svg)](https://www.perl.org/)
[![HTTP/2](https://img.shields.io/badge/HTTP%2F2-RFC%209113-blue.svg)](https://www.rfc-editor.org/rfc/rfc9113)

Unblock::HTTP2 is a non-blocking HTTP/2 protocol engine for Perl.

It handles HTTP/2 framing, HPACK, streams, SETTINGS, flow control, PING,
GOAWAY, trailers, CONNECT, and modern priority signaling.

It does not open sockets, perform TLS, select ALPN, or run an event loop.

```text
application or HTTP library
        |
  Uniform::HTTP messages
        |
   Unblock::HTTP2
        |
   byte transport
```

The transport can be Linux::Event, IO::Async, AnyEvent, Mojolicious, a blocking
socket, an in-memory test connection, or something else.

## Installation

From CPAN:

```text
cpanm Unblock::HTTP2
```

Unblock::HTTP2 0.10 requires Perl 5.16 or newer.

Version 0.10 intentionally breaks the earlier 0.04 API:
`Transaction->inform()` was replaced by `Transaction->send_informational()`.
There is no compatibility alias.

The distribution uses:

```text
Uniform::HTTP  0.06+
Alien::nghttp2 0.003+
```

Alien::nghttp2 supplies libnghttp2 and the build flags needed by the private XS
binding.

## Start here

The public API is built around three objects:

- `Unblock::HTTP2::Client` - one client HTTP/2 connection
- `Unblock::HTTP2::Server` - one server HTTP/2 connection
- `Unblock::HTTP2::Transaction` - one request/response transaction carried by an HTTP/2 stream

HTTP messages are normal `Uniform::HTTP::Request` and
`Uniform::HTTP::Response` objects.

The application-facing exchange object is a `Transaction`. Its main
application vocabulary is intentionally small and consistent:
`Client->new`, `Server->new`, `request()`, `respond()`, `write()`,
`end()`, and `send_informational()`. HTTP/2 protocol terms such as stream
ID, RST_STREAM, stream flow control, and MAX_CONCURRENT_STREAMS keep their RFC
names.

Canonical Uniform::HTTP 0.06 messages use its native C ABI directly. The XS
binding inspects outgoing canonical objects without a Perl FastPath view and
builds received canonical objects from validated native header spans. Uniform
subclasses and framework adapters continue to use the portable message API.

The basic transport contract is byte-in, byte-out:

```perl
$engine->input($bytes_from_transport);

while ($engine->want_write) {
    my $bytes = $engine->output;
    last unless length $bytes;
    $transport->write($bytes);
}
```

XS-backed transports can optionally use `Unblock::HTTP2::NativeABI`.
It accepts borrowed native input buffers directly and can drain generated
nghttp2 output through a native sink callback. The transport keeps ownership of
input storage, and outbound buffers are borrowed only for the duration of the
sink callback. Client and Server use the same ABI.

The normal `input()` and `output()` methods remain the portable path.
Native integrations can discover the installed ABI with `definition()`,
`native_include_dir()`, `header_path()`, and `c_header()`.

See `docs/INTEGRATION.md` for the native transport contract and ownership
rules.

Unblock::HTTP2 never waits for network activity itself.

## Client

```perl
use Uniform::HTTP::Request;
use Unblock::HTTP2::Client;

my $client = Unblock::HTTP2::Client->new;

my $transaction = $client->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/',
        scheme    => 'https',
        authority => 'example.com',
    ),

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

Many transactions can be active on one Client at the same time. Each is
carried by an HTTP/2 stream.

## Server

```perl
use Uniform::HTTP::Response;
use Unblock::HTTP2::Server;

my $server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($transaction, $request) = @_;

        $transaction->respond(
            Uniform::HTTP::Response->new(
                status => 200,
                body   => "hello\n",
            ),
        );
    },
);
```

Request body chunks arrive through `on_body`.
`on_request_end` runs when the complete request, including trailers, has
arrived.

## Streaming bodies

Buffered bodies can live directly on the Uniform message object.

For a streaming local body:

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

The same `write()` and `end()` API is used for a streaming server response.

`write()` always accepts the bytes. A false return means the transaction reached
its cooperative high-water mark. Pause production until `on_drain` runs.

Incoming body bytes are automatically credited back to the peer after the body
callback returns. A slow consumer can take manual flow-control ownership with:

```perl
$transaction->auto_consume(0);
$transaction->consume($bytes_processed);
```

## Trailers and informational responses

Request and response trailers are supported through the Uniform trailer fields.
Unblock sends them as HTTP/2 trailing HEADERS.

A server can send an informational response before the final response:

```perl
$transaction->send_informational(
    Uniform::HTTP::Response->new(
        status => 103,
    ),
);

$transaction->respond($final_response);
```

## CONNECT

Ordinary CONNECT and generic Extended CONNECT are supported.

An Extended CONNECT request uses the Uniform `protocol` field:

```perl
my $request = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    protocol  => 'websocket',
    scheme    => 'https',
    authority => 'example.com',
    target    => '/chat',
);
```

Unblock maps this to HTTP/2 `:protocol`. It does not implement the tunneled
protocol itself.

## Connection controls

The engine exposes HTTP/2 protocol controls without exposing the private
libnghttp2 session.

Examples:

```perl
$engine->ping("12345678");

$engine->update_settings(
    initial_window_size => 131_072,
);

$engine->drain;

$engine->goaway(
    error_code => Unblock::HTTP2::NO_ERROR(),
);
```

Received GOAWAY details are available through `peer_goaway()`.

A Transaction can be cancelled or reset explicitly:

```perl
$transaction->cancel;

$transaction->reset(
    Unblock::HTTP2::REFUSED_STREAM(),
);
```

Reset error codes and whether the reset came from the peer are preserved on the
Transaction.

RFC 9218 extensible priorities are supported. The old RFC 7540 dependency-tree
priority model is intentionally not part of the public API.

## What Unblock::HTTP2 owns

Unblock::HTTP2 owns:

- HTTP/2 client and server session state
- framing and HPACK through libnghttp2
- multiplexed streams
- request and response mapping
- trailers and informational responses
- SETTINGS, PING, GOAWAY, and RST_STREAM
- connection and stream flow control
- streaming body backpressure
- ordinary and Extended CONNECT
- RFC 9218 priority updates

## What it does not own

Unblock::HTTP2 does not own:

- sockets
- DNS
- TLS
- ALPN
- event loops
- connection pools
- redirects
- cookies
- authentication policy
- proxy policy
- retry policy
- HTTP/1 upgrade negotiation
- WebSocket, CONNECT-UDP, or other tunnel semantics

Those responsibilities belong to the transport, application, or a higher HTTP
client/server layer.

Server Push is intentionally not exposed. Clients advertise
`SETTINGS_ENABLE_PUSH = 0`.

## Testing

The normal suite runs complete client/server exchanges in memory.

CI covers:

- Perl 5.16 on Linux
- current Perl on Linux
- current Perl on macOS
- Strawberry Perl on Windows
- `distcheck` and `disttest` against the generated distribution
- a staged-install NativeABI smoke test that compiles an external C consumer
  against the installed public header

A separate interoperability workflow tests both directions against the stock
nghttp2 tools:

- Unblock client -> nghttpd server
- nghttp client -> Unblock server

The interoperability and performance harnesses live under `xt/` and are not
included in the CPAN distribution.

## More documentation

- `Unblock::HTTP2::Client` - client connection API
- `Unblock::HTTP2::Server` - server connection API
- `Unblock::HTTP2::Transaction` - per-transaction API
- `Unblock::HTTP2::NativeABI` - optional native transport ABI
- `docs/ARCHITECTURE.md` - ownership and data flow
- `docs/FEATURE-COMPLETENESS.md` - release scope and deliberate exclusions
- `docs/BACKEND-REQUIREMENTS.md` - private libnghttp2 binding contract
- `docs/INTEGRATION.md` - portable and native transport integration

## Status

Unblock::HTTP2 0.10 is feature-complete for its intended role as a reusable,
event-loop-neutral HTTP/2 engine.

Future work can focus on bug fixes, interoperability, performance, or optional
extensions without changing the transport boundary.

## License

MIT.
