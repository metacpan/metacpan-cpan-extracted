# Unblock::HTTP1

[![Tests](https://github.com/haxmeister/perl-Unblock-HTTP1/actions/workflows/test.yml/badge.svg)](https://github.com/haxmeister/perl-Unblock-HTTP1/actions/workflows/test.yml)
[![CPAN](https://img.shields.io/cpan/v/Unblock-HTTP1.svg)](https://metacpan.org/release/Unblock-HTTP1)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Unblock::HTTP1 is a non-blocking HTTP/1.0 and HTTP/1.1 protocol engine for Perl.

It parses requests, serializes responses, handles HTTP message boundaries,
streaming bodies, keep-alive, trailers, Upgrade, and CONNECT.

It does not open sockets, do DNS or TLS, run an event loop, or manage
connection pools. It can be hosted by IO::Async, AnyEvent, Linux::Event,
Mojolicious, native transport code, or another event framework.

## Installation

    cpanm Unblock::HTTP1

Requires Perl 5.16 and Uniform::HTTP 0.06 or newer.
Linux::Event, IO::Async and AnyEvent are optional host frameworks.

## Start here

The three application classes are:

- Unblock::HTTP1::Client - one client-side connection
- Unblock::HTTP1::Server - one server-side connection
- Unblock::HTTP1::Transaction - one request and response exchange

A transaction uses the shared Unblock vocabulary: respond(), write(),
end(), send_informational(), state(), error(), is_complete(),
is_cancelled(), is_error(), and is_terminal().

The easiest server response:

    $tx->respond(
        status => 200,
        body   => "Hello World!\n",
    );

The easiest client request:

    $client->request(
        method    => 'GET',
        target    => '/',
        authority => 'example.test',
        on_response => sub {
            my ($tx, $response) = @_;
            print $response->status, "\n";
        },
    );

These calls still create and use canonical Uniform::HTTP::Request and
Uniform::HTTP::Response messages internally. Existing Uniform objects
continue to work directly:

    $client->request($request);
    $tx->respond($response);

## Connect to an event framework

Create one Client or Server per framework connection:

    $self->{http1} = Unblock::HTTP1::Server->new(
        transport  => $self,
        on_request => $on_request,
    );

The framework object implements only three host methods:

    unblock_send($bytes)      # accept complete output into framework queue
    unblock_finish()          # graceful close after queued output
    unblock_abort($reason)    # immediate failure close

The framework feeds incoming events to the engine:

    $http->input($bytes);
    $http->input_eof;
    $http->transport_error($reason);

The engine delivers output automatically. A delayed response from a timer
or database callback also triggers output without another framework read
event.

An integration that exposes congestion returns false from unblock_send()
AFTER accepting the whole buffer, and later calls $http->resume_output.
If the framework simply queues all output, it may return undef.

The engine holds a weak reference to the host. The framework owns its
sockets, output queue, and loop.

**Full working server and client examples:**

- examples/io-async-server.pl
- examples/io-async-client.pl
- examples/anyevent-server.pl
- examples/anyevent-client.pl
- examples/linux-event-server.pl

The examples separate adapter code from application code. The Linux::Event
server demonstrates the same host API using a Stream subclass and a
separate application subclass. Linux::Event is not a required dependency.

For complete instructions, read:

    perldoc Unblock::HTTP1::Integration

The repository also includes docs/INTEGRATION.md and docs/COOKBOOK.md.

## Receive bodies and transaction completion

By default, incoming body data is streamed through callbacks. To retain the
decoded body in the canonical Uniform::HTTP message, construct a Client or
Server with `receive_body => 'buffered'`. Buffered reception is limited by
`max_buffered_body_bytes` (64 MiB by default).

For per-transaction streaming, register `$tx->on_data(sub { ... })` in the
incoming-headers callback, or supply `on_data` to Client->request(). That
callback receives decoded body fragments without collecting the full body.
Do not combine `on_data` and `on_body` on one Transaction.

`$tx->on_finish(sub { ... })` runs exactly once after the Transaction reaches
complete, cancelled, or error state. On an attached server, successful
completion is not reported until the host has accepted the corresponding
outgoing bytes. See the Client, Server, and Transaction POD for the callback
ordering and receive modes.

## Connection and message behavior

A Client queues requests serially on one connection; it does not silently
enable HTTP/1 pipelining. A Server can receive pipelined request bytes and
process them in HTTP order.

A server's on_request runs after the request head has arrived.
on_body delivers decoded request body fragments. on_request_end runs when the
full request, including trailers, is complete.

For a streaming response:

    $tx->respond(status => 200, stream_body => 1);
    $tx->write($chunk);
    $tx->end($final_bytes);

write() and end() accept bytes even when they return false for backpressure.
Use on_drain to resume producing data.

A clean read EOF is not the same as fatal transport failure. After a
fully received request, the server can still send a delayed response, then
close gracefully.

A 101 Upgrade response or successful CONNECT switches away from HTTP.
take_remainder() returns already-received bytes belonging to the next
protocol. An attached server invokes on_switch after the full outgoing
HTTP handshake has been accepted into the framework's write queue.

## Graceful shutdown

After stopping a listener, call `$server->drain` on each active HTTP/1
server connection. The admitted request can finish, but another pipelined
request will not start. The host still flushes accepted output and enforces
any shutdown deadline. See `perldoc Unblock::HTTP1::Server`.

## Manual and native integration

For advanced consumers, the original low-level output interface remains:

    $http->input($bytes);
    while ($http->want_write) {
        $transport->write($http->output);
    }

This is for engines built WITHOUT an attached transport. Do not mix manual
output draining and automatic output ownership.

XS-backed transports can use Unblock::HTTP1::NativeABI v1 to pass borrowed
native input. The ABI is input-side and remains transport neutral. It
supports the same HTTP callbacks and can construct canonical Uniform
messages through Uniform::HTTP 0.06's native FastPath.

The installed C header is:

    Unblock/HTTP1/NativeABI/unblock_http1_native_abi.h

ABI discovery:

    Unblock::HTTP1::NativeABI::definition()
    Unblock::HTTP1::NativeABI::native_include_dir()
    Unblock::HTTP1::NativeABI::header_path()
    Unblock::HTTP1::NativeABI::c_header()

## Limits

Defaults:

    max_head_size              65536 bytes
    max_headers                100
    max_chunk_extension_size   16384 bytes
    high_water                 65536 bytes
    low_water                  32768 bytes

See docs/PROTOCOL_STATUS.md for the protocol feature checklist.

## License

MIT License.
