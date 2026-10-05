# Unblock::HTTP1

[![Tests](https://github.com/haxmeister/perl-Unblock-HTTP1/actions/workflows/test.yml/badge.svg)](https://github.com/haxmeister/perl-Unblock-HTTP1/actions/workflows/test.yml)
[![CPAN](https://img.shields.io/cpan/v/Unblock-HTTP1.svg)](https://metacpan.org/release/Unblock-HTTP1)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Unblock::HTTP1 is a non-blocking HTTP/1 protocol engine for Perl.

It handles HTTP/1.0 and HTTP/1.1 parsing, serialization, framing, streaming
bodies, persistent connections, informational responses, trailers, Upgrade,
and CONNECT.

It does not open sockets, perform DNS or TLS, choose an event loop, or manage
connection pools.

```text
application or HTTP library
        |
  Uniform::HTTP messages
        |
   Unblock::HTTP1
        |
   byte transport
```

The transport can be Linux::Event, IO::Async, AnyEvent, Mojolicious, a blocking
socket, an in-memory test connection, or something else.

## Installation

From CPAN:

```text
cpanm Unblock::HTTP1
```

Unblock::HTTP1 0.10 requires Perl 5.16 or newer and Uniform::HTTP 0.06 or newer.

Version 0.10 intentionally joins the common Unblock HTTP API vocabulary while
the distributions are still young. No compatibility aliases are carried.

## Start here

The public API is built around three objects:

- `Unblock::HTTP1::Client` - one client HTTP/1 connection
- `Unblock::HTTP1::Server` - one server HTTP/1 connection
- `Unblock::HTTP1::Transaction` - one request/response exchange

HTTP messages are normal `Uniform::HTTP::Request` and
`Uniform::HTTP::Response` objects.

The application-facing vocabulary is intentionally shared with the other
Unblock HTTP engines:

```text
Client->new
Server->new
request()
respond()
write()
end()
send_informational()
```

Transactions use the common lifecycle vocabulary:

```text
state()
error()
is_complete()
is_cancelled()
is_error()
is_terminal()
```

The basic transport contract is byte-in, byte-out:

```perl
$engine->input($bytes_from_transport);

while ($engine->want_write) {
    my $bytes = $engine->output;
    last unless length $bytes;
    $transport->write($bytes);
}
```

Unblock::HTTP1 never waits for network activity itself.

## Client

```perl
use Uniform::HTTP::Request;
use Unblock::HTTP1::Client;

my $client = Unblock::HTTP1::Client->new;

my $transaction = $client->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/',
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

A Client serializes requests on one connection. It does not silently enable
HTTP/1 pipelining.

## Server

```perl
use Uniform::HTTP::Response;
use Unblock::HTTP1::Server;

my $server = Unblock::HTTP1::Server->new(
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

Request bodies arrive through `on_body`. `on_request_end` runs after the
complete request body and trailers have arrived.

## Streaming bodies

For a streaming client request:

```perl
my $transaction = $client->request(
    $request,
    stream_body => 1,
);

$transaction->write($chunk);
$transaction->end($last_chunk);
```

For a streaming server response:

```perl
$transaction->respond(
    $response,
    stream_body => 1,
);

$transaction->write($chunk);
$transaction->end($last_chunk);
```

HTTP/1.1 uses chunked framing when needed. HTTP/1.0 streaming requires an
explicit Content-Length.

`write()` returns false when the engine output queue reaches its high-water
mark. `on_drain` fires after the queue falls below its low-water mark.

## Informational responses

A server Transaction can send a 1xx response before its final response:

```perl
$transaction->send_informational($response);
$transaction->respond($final_response);
```

## Upgrade and CONNECT

A 101 response or successful CONNECT ends HTTP framing on the connection.

The engine then reports:

```perl
$engine->is_switched
```

Bytes already read after the HTTP boundary are preserved:

```perl
my $bytes = $engine->take_remainder;
```

The caller can pass those bytes to the next protocol implementation.

## Native integration

The normal `input()` method remains the portable path.

XS-backed transports can optionally use `Unblock::HTTP1::NativeABI` to feed
borrowed native input buffers directly. The transport keeps ownership of the
input storage and Unblock reports the permanently consumed prefix.

Canonical Uniform::HTTP 0.06 messages use the Uniform native construction path
on this route.

Native integrations can discover the installed ABI with:

```perl
my $definition = Unblock::HTTP1::NativeABI::definition();
my $include_dir = Unblock::HTTP1::NativeABI::native_include_dir();
my $header_path = Unblock::HTTP1::NativeABI::header_path();
my $header = Unblock::HTTP1::NativeABI::c_header();
```

The installed public header is:

```text
Unblock/HTTP1/NativeABI/unblock_http1_native_abi.h
```

HTTP/1 keeps its native ABI focused on borrowed input. It does not add
HTTP/2-specific native output operations merely for API symmetry.

See `docs/INTEGRATION.md` for the transport contract and ownership rules.

## Limits

Default limits are:

```text
maximum HTTP head:             65536 bytes
maximum header fields:         100
maximum chunk extension bytes: 16384 per message
output high water:             65536 bytes
output low water:              32768 bytes
```

The limits can be changed when constructing a Client or Server.

## Protocol status

The HTTP/1 protocol engine is complete for its declared scope and has
cross-platform CI coverage on Linux, macOS, and Windows, including Perl 5.16.

See `docs/PROTOCOL_STATUS.md` for the detailed protocol checklist.

## License

MIT License.
