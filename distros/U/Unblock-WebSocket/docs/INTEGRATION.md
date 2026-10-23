# Connecting Unblock::WebSocket to a transport

This guide is for someone writing an adapter between Unblock::WebSocket
and a socket, event framework, or streaming HTTP transaction.

If you only want to learn how to send and receive messages, start with
[the README](../README.md) and
[examples/handshake-memory.pl](../examples/handshake-memory.pl).

## The two parts of a connection

There are two objects with different jobs:

- **The WebSocket object** (`$ws`) understands WebSocket messages,
  frames, masking, Ping/Pong and Close.
- **The transport** (`$host`) owns the connection, reads and writes
  bytes, handles TLS, and decides when to stop the connection.

The WebSocket object does **not** create a socket or run an event loop.

The opening HTTP handshake happens before an ordinary WebSocket
Client or Server object is used. Once the handshake is accepted, the
transport delivers only WebSocket bytes to `$ws->input($bytes)`.

## Pick one output mode

There are two ways to get outgoing bytes from Unblock::WebSocket.

**Attached output** is convenient for framework adapters: the
WebSocket object calls methods on the host whenever output is ready.
This works for messages sent later from callbacks too.

**Manual output** is simpler for an application that already moves
byte buffers itself: the caller asks for output and writes it.

Do not use both modes for one WebSocket connection.

## Attached output

Create your WebSocket with `transport => $host`:

    use Unblock::WebSocket::Server;

    my $ws = Unblock::WebSocket::Server->new(
        transport => $host,
        on_message => sub {
            my ($ws, $message, $type) = @_;
            $ws->send_text("echo:$message");
        },
    );

Then, whenever the host receives data:

    $ws->input($bytes);

The host must provide **exactly these three transport operations**:

    unblock_send($bytes)
    unblock_finish()
    unblock_abort($reason)

The names are deliberately separate from ordinary framework method names
such as `write()` or `close()`. An adapter maps these three methods to
the framework's own operations.

### What each host method means

`unblock_send($bytes)` queues the complete byte string to be written
in order. The bytes are already framed as WebSocket traffic; do not frame
them again.

- Return true if you accepted every byte and can accept more now.
- Return undef if you accepted every byte and do not report congestion.
- Return a defined false value if you accepted every byte but your
  output queue is now full.
- Throw an exception if you could not accept the entire buffer.

**Even when it returns false, every byte must already be owned by the
host.** Do not return false to mean a partial write. If the underlying
socket only writes part of a buffer, the host must keep the rest.

If the host returns false, the WebSocket object holds back any further
output until the host calls:

    $ws->resume_output;

Call it after the host queue has room. This does not resend bytes the
host already accepted.

`unblock_finish()` says a normal WebSocket Close exchange has finished
and all protocol bytes have been handed to the host. The host must
flush its own pending writes before closing the network connection.

`unblock_abort($reason)` says the connection failed. Stop the
transport and dispose of its pending work as appropriate. It is not
a normal WebSocket Close frame.

### A small host example

For a runnable version, see
[examples/memory-attached.pl](../examples/memory-attached.pl).

The essential method contract looks like this:

    package Example::Host;

    sub unblock_send {
        my ($self, $bytes) = @_;
        push @{ $self->{pending_output} }, $bytes;
        return; # Every byte accepted; no congestion signal.
    }

    sub unblock_finish {
        my ($self) = @_;
        $self->{finish_when_queue_drains} = 1;
        return;
    }

    sub unblock_abort {
        my ($self, $reason) = @_;
        $self->{error} = $reason;
        return;
    }

The example deliberately omits real network code. Your framework must
actually write and drain `pending_output` and honor
`finish_when_queue_drains`. It must also keep the host alive because
Unblock::WebSocket holds only a weak reference to it.

### Receiving bytes, EOF and errors

When the host receives WebSocket bytes:

    $ws->input($bytes);

When the read side reaches EOF:

    $ws->input_eof;

When the socket, TLS connection or streaming transport fails:

    $ws->transport_error($reason);

Unexpected EOF before a WebSocket Close frame is an abnormal shutdown.
In attached mode this calls `unblock_abort()`. Do not confuse
transport EOF with a valid WebSocket Close handshake.

### Who handles backpressure?

There are **two different queues**:

1. The WebSocket engine may have output buffered.
2. Your host may have bytes waiting to be written to the network.

When the host returns false from `unblock_send()`, it must call
`resume_output()` once it can accept more.

Separately, `send_text()`, `send_binary()` and `ping()` can return
false even though the message was accepted. That is a signal to the
**application producer** to pause until `on_drain` fires.

    my $ws = Unblock::WebSocket::Server->new(
        transport => $host,
        on_drain => sub {
            my ($ws) = @_;
            # Application can produce more messages.
        },
    );

`on_drain` does not replace the host's socket-writable event.

Do not call `input()` or `resume_output()` recursively while the
engine is inside `unblock_send()`, and do not start more WebSocket sends
from that host method. Sending from `on_message` is supported.

### Closing

    $ws->close(code => 1000, reason => 'done');

This queues a WebSocket Close frame. The peer should answer with its own
Close frame. Only after that exchange and after the engine has passed
outgoing bytes to the host does it call `unblock_finish()`.

Your host must still drain its own write queue. A host may use its own
timeout if a peer never completes the Close handshake, and then abort.

## Manual output

If there is no `transport => $host`, use this API:

    use Unblock::WebSocket::Server;

    my $ws = Unblock::WebSocket::Server->new(
        on_message => sub {
            my ($ws, $message, $type) = @_;
            $ws->send_text("echo:$message");
        },
    );

    # Read bytes from your network transport.
    $ws->input($bytes);

    # Put every generated buffer on your transport write queue.
    while ($ws->want_write) {
        my $out = $ws->output;
        $host->write($out);
    }

Here `$host->write()` stands for whatever ordered write-queue API your
framework provides. The example is not tied to a specific framework.

Other useful manual-mode methods are `output_size()`,
`output($maximum)`, `want_read()` and `want_end()`.
`output()` cannot be called in attached mode.

See [examples/memory-manual.pl](../examples/memory-manual.pl)
for the complete memory-only example.

## How to switch from HTTP to WebSocket

WebSocket begins as an HTTP request. The transport must complete
the opening handshake before delivering WebSocket bytes to the engine.
Use `Unblock::WebSocket::Handshake` to create and validate the
`Uniform::HTTP` messages.

The HTTP version changes **which connection carries the WebSocket bytes**.

### HTTP/1.1: upgrade the whole connection

1. Client sends an HTTP GET request with Upgrade headers.
2. Server validates it with `Handshake->server_accept($request)`.
3. Server sends `$handshake->server_response` (HTTP 101).
4. After the HTTP implementation switches protocols, create
   `Unblock::WebSocket::Server` and feed it the remaining bytes.

When using Unblock::HTTP1, `on_switch` is called after the attached
HTTP host has accepted the 101 response. Call `take_remainder()` on
the HTTP engine and feed those exact bytes to the WebSocket object.
A client may send its first WebSocket frame in the same network
buffer as the HTTP request. Do not discard that remainder or
send it through HTTP again.

Keep the **same ordered host write queue** so the HTTP 101 response is
sent before any WebSocket frames. The socket now belongs to WebSocket,
not HTTP.

The full regression is `t/35-http1-handoff.t`.

### HTTP/2: use one streaming transaction

HTTP/2 keeps the whole network connection available for multiple
transactions. A WebSocket occupies **one** streaming transaction.

- Both sides must support HTTP/2 Extended CONNECT; the peer advertises
  `enable_connect_protocol`.
- The handshake creates CONNECT with `:protocol = websocket`.
- The successful response is HTTP 200, not 101.
- Use `stream_body => 1` on the request and response.
- Feed that transaction's incoming DATA chunks to `$ws->input($bytes)`.
- Write WebSocket output with that transaction's `write($bytes)` and
  finish its body with `end()` after the Close handshake.

The body adapter can supply the same three `unblock_*` methods.
When an HTTP/2 parser callback calls into WebSocket, queue outgoing
WebSocket bytes and flush them **after** the parser callback returns.
Do not call back into the HTTP/2 engine recursively from its own
callbacks.

Other transactions on the HTTP/2 connection continue normally.
The full regression is `t/36-http2-handoff.t`.

### HTTP/3: use one QUIC stream

HTTP/3 follows the same basic pattern as HTTP/2: Extended CONNECT,
a successful HTTP 200 response and a streaming transaction body.

- Enable and check HTTP/3 Extended CONNECT support.
- Feed that transaction's body chunks to `$ws->input($bytes)`.
- Send the WebSocket output to that HTTP/3 transaction, not to the
  whole QUIC connection.
- Finish the transaction body after a normal WebSocket Close exchange.

The QUIC driver still owns UDP, TLS 1.3, stream flow control and timers.
An HTTP/3 adapter must queue the **whole** buffer before claiming
acceptance, even if the QUIC stream is temporarily unable to write.
Use `resume_output()` after congestion clears.

The live QUIC/TLS regression is `xt/http3-handoff.t`.

## Optional dependencies

Unblock::WebSocket does **not** require Unblock::HTTP1, HTTP2, HTTP3 or
Net::QUIC to run. Those libraries are integration choices; the
corresponding tests use them when installed.

The native adapter ABI is separate from the Perl-level attached and
manual interfaces. XS adapters needing the lowest overhead can use
the private versioned C header instead of moving every byte through
Perl.

For API details, read `perldoc Unblock::WebSocket`,
`perldoc Unblock::WebSocket::Handshake`,
`perldoc Unblock::WebSocket::Client` and
`perldoc Unblock::WebSocket::Server`.
