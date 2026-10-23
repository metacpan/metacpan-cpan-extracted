# Unblock::WebSocket

[![CPAN version](https://badge.fury.io/pl/Unblock-WebSocket.svg)](https://metacpan.org/dist/Unblock-WebSocket)
[![CPANTS Kwalitee](https://cpants.cpanauthors.org/dist/Unblock-WebSocket.svg)](https://cpants.cpanauthors.org/dist/Unblock-WebSocket)
[![CI](https://github.com/haxmeister/perl-Unblock-WebSocket/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/haxmeister/perl-Unblock-WebSocket/actions/workflows/test.yml)
[![Autobahn](https://github.com/haxmeister/perl-Unblock-WebSocket/actions/workflows/autobahn.yml/badge.svg?branch=main)](https://github.com/haxmeister/perl-Unblock-WebSocket/actions/workflows/autobahn.yml)
[![License](https://img.shields.io/cpan/l/Unblock-WebSocket.svg)](https://github.com/haxmeister/perl-Unblock-WebSocket/blob/main/LICENSE)
[![Perl](https://img.shields.io/badge/perl-5.16%2B-blue.svg)](https://www.perl.org/)

A WebSocket client and server protocol engine for Perl. It works with any
framework or event loop that can carry an ordered stream of bytes.

**Unblock::WebSocket handles the WebSocket protocol. Your application or HTTP
framework handles the network connection.**

The module can send and receive text, binary messages, Ping/Pong and Close
frames. It also supports fragmentation, message-size limits, and negotiated
permessage-deflate compression.

## Start here

Install it with:

    cpanm Unblock::WebSocket

It requires Perl 5.16 or newer. Building the distribution requires a C
compiler for its XS extension. A portable Perl framing backend is also
available at runtime.

The easiest way to understand the API is to run the three examples:

- [examples/handshake-memory.pl](examples/handshake-memory.pl) - opening
  handshake, one message and a clean Close;
- [examples/memory-attached.pl](examples/memory-attached.pl) - automatic output
  through a host transport;
- [examples/memory-manual.pl](examples/memory-manual.pl) - manual byte transfer.

From a built source checkout:

    perl Makefile.PL
    make
    perl -Mblib examples/handshake-memory.pl
    perl -Mblib examples/memory-attached.pl
    perl -Mblib examples/memory-manual.pl

These examples work in memory. They do not create a real network connection;
the first example simulates HTTP request/response delivery. This makes it
possible to learn the protocol API without first writing a framework adapter.

## How a WebSocket connection starts

There are **two phases**:

1. Your HTTP client or server establishes the connection using an HTTP
   WebSocket handshake.
2. After the handshake succeeds, you create
   `Unblock::WebSocket::Client` or `Unblock::WebSocket::Server` to handle
   WebSocket messages.

The handshake helper builds and checks HTTP messages. **It does not send them.**

Client side:

    use Unblock::WebSocket::Handshake;
    use Unblock::WebSocket::Client;

    my ($handshake, $request) =
        Unblock::WebSocket::Handshake->client_request(
            'wss://example.com/chat',
            http_version => '1.1',
        );

    # Send $request with your HTTP client and receive $response.
    $handshake->validate_client_response($response);

    my $ws = Unblock::WebSocket::Client->new(
        %{ $handshake->connection_options },
        on_message => sub {
            my ($ws, $message, $type) = @_;
            print "Received $type: $message\n";
        },
    );

Server side:

    use Unblock::WebSocket::Handshake;
    use Unblock::WebSocket::Server;

    my $handshake =
        Unblock::WebSocket::Handshake->server_accept($request);

    my $response = $handshake->server_response;

    # Send $response with your HTTP server, then switch the connection.
    my $ws = Unblock::WebSocket::Server->new(
        %{ $handshake->connection_options },
        on_message => sub {
            my ($ws, $message, $type) = @_;
            $ws->send_text("echo:$message");
        },
    );

Here `$request` and `$response` are `Uniform::HTTP` objects. Your chosen
HTTP implementation sends them. The examples above show the WebSocket parts,
not a complete HTTP server or client.

For HTTP/2 or HTTP/3, specify `http_version => '2'` or `'3'`. Those
connections use Extended CONNECT rather than HTTP/1.1 Upgrade. The HTTP
implementation must support Extended CONNECT and keep the transaction body
open for WebSocket traffic.

## Sending and receiving messages

Once the handshake finishes:

    $ws->send_text('hello');
    $ws->send_binary($bytes);
    $ws->ping('check');
    $ws->close(code => 1000, reason => 'done');

The `on_message` callback receives three arguments:

    on_message => sub {
        my ($ws, $message, $type) = @_;
        # $type is 'text' or 'binary'.
    }

Other callbacks are `on_ping`, `on_pong`, `on_close`, `on_error` and
`on_drain`. A received Ping is answered automatically.

The library also handles WebSocket Close frames. Calling `close()` starts a
Close handshake; it does not immediately shut down the socket.

## Getting bytes to and from your framework

Choose **one** of these modes for each WebSocket connection.

### Attached transport (recommended for a framework adapter)

    use Unblock::WebSocket::Server;

    my $ws = Unblock::WebSocket::Server->new(
        transport => $host,
        on_message => sub {
            my ($ws, $message, $type) = @_;
            $ws->send_text("echo:$message");
        },
    );

    # When your framework receives WebSocket bytes:
    $ws->input($bytes);

The host is an object supplied by your application or framework. It must
implement:

    unblock_send($bytes)       # Queue all outgoing bytes in order.
    unblock_finish()           # Finish after a successful Close handshake.
    unblock_abort($reason)     # Stop a broken connection.

Output is passed to the host automatically, even when a callback sends a
message later. The host remains responsible for its write queue, TLS and
socket. The WebSocket engine only holds a weak reference to it.

If `unblock_send()` returns false, it still means **all** supplied bytes
were accepted. It means the host cannot accept *more* yet. Call
`$ws->resume_output` when the host is ready again.

See [docs/INTEGRATION.md](docs/INTEGRATION.md) for the complete host
contract, including EOF, errors, backpressure and HTTP handoff.

### Manual output (simplest byte-level API)

Without `transport => $host`, you drain output yourself:

    use Unblock::WebSocket::Server;

    my $ws = Unblock::WebSocket::Server->new(
        on_message => sub {
            my ($ws, $message, $type) = @_;
            $ws->send_text("echo:$message");
        },
    );

    # Feed WebSocket bytes from the network:
    $ws->input($bytes);

    # Give generated WebSocket bytes to your ordered transport:
    while ($ws->want_write) {
        my $chunk = $ws->output;
        $host->write($chunk);
    }

`$host->write` above is illustrative: use the write or queue method supplied
by your transport. The host must preserve byte order and partial writes.

In attached mode you must **not** call `$ws->output`; the host already
owns the output.

## Backpressure, EOF and errors

A false result from `send_text()`, `send_binary()` or `ping()` means the
message was accepted, but your application should pause producing more
messages until `on_drain` fires. `on_drain` is not the same thing as the
transport's socket-writable event.

Call `$ws->input_eof` when the peer stops sending bytes. Call
`$ws->transport_error($reason)` for a broken network or TLS transport.

In attached mode a completed WebSocket Close handshake results in
`unblock_finish()`. An unexpected EOF or transport failure instead calls
`unblock_abort()`. The host must finish writing previously accepted bytes
before a graceful shutdown.

## Supported handshakes

- HTTP/1.1 Upgrade (successful status 101);
- HTTP/2 Extended CONNECT (successful status 200);
- HTTP/3 Extended CONNECT (successful status 200).

Subprotocols and permessage-deflate are negotiated by
`Unblock::WebSocket::Handshake`. Pass
`%{ $handshake->connection_options }` to the established Client or Server
so the negotiated compression settings are not lost.

The WebSocket distribution does not require Unblock::HTTP1, HTTP2, HTTP3 or
a particular event framework. They are optional integration choices.

## Where to read next

- [docs/INTEGRATION.md](docs/INTEGRATION.md) - write a transport adapter and
  hand off HTTP/1.1, HTTP/2 or HTTP/3 traffic.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - protocol design and native ABI.
- [docs/PERFORMANCE.md](docs/PERFORMANCE.md) - benchmarks and performance
  trade-offs.
- `perldoc Unblock::WebSocket`,
  `perldoc Unblock::WebSocket::Handshake`,
  `perldoc Unblock::WebSocket::Client` and
  `perldoc Unblock::WebSocket::Server` - API reference.

## Testing and performance

The repository runs Linux, macOS and Windows tests, HTTP integration tests
and a separate Autobahn conformance suite. Its full selected Autobahn suite
contains 517 cases each for client and server.

Native framing is used when available; choose `backend => 'perl'` when you
want the reference implementation for testing. The private native adapter ABI
is available for high-performance XS transport integrations without requiring
all wire bytes to pass through Perl scalar buffers.

An attached host is easier to integrate but has measurable dispatch overhead
compared with the shortest manual output loop. See the performance document
for actual same-run measurements. No specific event-loop implementation is
required.

## License

MIT License.
