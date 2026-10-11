# Unblock::HTTP2 architecture

## Purpose

Unblock::HTTP2 is a reusable HTTP/2 protocol engine.

It sits between HTTP message objects and an arbitrary byte transport.

```text
application or HTTP policy
        |
  Uniform::HTTP messages
        |
   Unblock::HTTP2
        |
   byte transport
```

The transport may be an event-loop stream, TLS stream, blocking socket,
in-memory connection, or another byte carrier.

Unblock::HTTP2 does not know how the transport is scheduled.

## Byte boundary

Incoming bytes are passed to:

```perl
$engine->input($bytes);
```

The recommended Perl integration attaches a framework stream to the Client
or Server. The stream implements three host methods:

```text
unblock_send($bytes)
unblock_finish()
unblock_abort($reason)
```

Unblock automatically delivers outgoing bytes through `unblock_send()`,
including data generated from delayed response callbacks. The framework owns
the output queue and must accept each complete buffer before returning.

Without an attached host, a low-level adapter can drain bytes manually:

```perl
while ($engine->want_write) {
    my $bytes = $engine->output;
    last unless length $bytes;
    $framework->write($bytes);
}
```

Do not mix the two modes. See `Unblock::HTTP2::Integration` for complete
ownership, backpressure, shutdown, and EOF rules.

`want_read()` reports whether the HTTP/2 session still expects protocol input.
It does not register a watcher or read from a socket.

TLS, ALPN, connection setup, and HTTP/1 upgrade negotiation stay outside this
boundary.

## Messages

HTTP messages are:

```text
Uniform::HTTP::Request
Uniform::HTTP::Response
```

HTTP/2 pseudo-headers map to Uniform fields:

```text
:method     -> method
:path       -> target
:scheme     -> scheme
:authority  -> authority
:protocol   -> protocol
:status     -> status
```

Ordinary headers and trailers remain separate Uniform field lists.

Received initial metadata is frozen after validation. The message remains
incomplete while body data or trailers can still arrive. END_STREAM completes
and freezes the message.

Outgoing application messages remain application-owned. Unblock does not
rewrite them merely to stamp an HTTP version onto the object.

## Transactions and streams

One `Unblock::HTTP2::Transaction` represents one HTTP request/response exchange
carried by one HTTP/2 stream.
The Transaction exposes that protocol identifier as `stream_id()`. Internal
nghttp2 state and RFC-defined controls continue to use stream terminology.

A Transaction tracks:

- stream ID
- request
- response when available
- local body production
- received body credit
- reset information
- terminal state and error

The common lifecycle vocabulary is `state()`, `error()`, `is_complete()`,
`is_cancelled()`, `is_error()`, and `is_terminal()`.

Many Transactions can be active on one Client or Server connection.

HTTP/2 half-close is preserved. One direction may finish while the other
direction remains open.

## Bodies and backpressure

Buffered bodies can live on the Uniform message.

Streaming local bodies use `write()` and `end()`.

The default cooperative body queue thresholds are:

```text
high water  65536 bytes
low water   32768 bytes
```

`write()` accepts the bytes even when it returns false. A false return tells
the producer to pause until `on_drain` runs. An attached host can also report
congestion from `unblock_send()` after accepting a complete wire buffer; it
then calls `resume_output()` when ready. This host-level signal also pauses
streaming body producers.

Incoming body bytes are automatically consumed after the body callback returns.

A Transaction can disable that behavior with:

```perl
$transaction->auto_consume(0);
```

The application then returns stream-level flow-control credit with
`consume($bytes)`.

Connection-level credit is kept moving separately so one slow stream does not
needlessly block unrelated streams.

## Trailers and informational responses

Uniform trailer fields are sent as trailing HEADERS.

For a streaming local body, trailer fields are snapshotted when `end()` is
called.

Servers can send one or more informational responses with
`send_informational()` before the final `respond()`.

## CONNECT

Ordinary CONNECT uses the authority-form target.

Extended CONNECT maps the Uniform `protocol` field to `:protocol`.

The server advertises `SETTINGS_ENABLE_CONNECT_PROTOCOL` by default. The
client will not send Extended CONNECT until the peer has enabled it.

The tunneled protocol remains outside Unblock::HTTP2.

## Connection controls

SETTINGS, PING, GOAWAY, and modern priority signaling are public protocol
operations.

SETTINGS can be supplied at construction and changed later with
`update_settings()`. The engine exposes both local and effective peer values.

Supported public setting names are:

```text
header_table_size
enable_push
max_concurrent_streams
initial_window_size
max_frame_size
max_header_list_size
enable_connect_protocol
no_rfc7540_priorities
```

PING carries exactly eight opaque bytes.

`drain()` sends a graceful `NO_ERROR` GOAWAY. `goaway()` allows an explicit
error code, debug data, and last-stream boundary.

Received GOAWAY facts are preserved for the higher layer. Unblock does not
decide whether a request should be retried.

RFC 9218 extensible priority signaling is supported. The deprecated RFC 7540
dependency-tree priority model is not exposed.

## Resets and errors

`cancel()` sends the standard CANCEL reset.

`reset($error_code)` sends an explicit RST_STREAM reason.

Received reset codes are preserved on the Transaction together with whether the
reset came from the peer.

Fatal libnghttp2 input or output failures close the engine and preserve
`close_reason()` before the exception is rethrown.

Recoverable protocol errors remain under libnghttp2 control. Invalid-frame
observation is available without replacing libnghttp2's required protocol
response.

Unknown extension frame types are ignored as required by HTTP/2.

## Server Push

Server Push is intentionally not exposed.

Clients advertise:

```text
SETTINGS_ENABLE_PUSH = 0
```

This keeps the public API focused on the modern HTTP/2 features that remain
useful to new applications.

## Private nghttp2 binding

libnghttp2 owns the low-level HTTP/2 machinery:

- frame encoding and decoding
- HPACK
- protocol state validation
- SETTINGS mechanics
- connection and stream flow control

Unblock::HTTP2 uses a small private XS binding named
`Unblock::HTTP2::_nghttp2`.

That binding is not public API. It does not own Uniform::HTTP objects or know
about event loops.

For exact canonical Uniform::HTTP messages, the binding uses the
Uniform::HTTP 0.06 native C ABI. Outgoing objects are inspected in XS without
building a Perl FastPath view. Received initial header blocks stay native until
HTTP/2 validation is complete, then XS constructs the final canonical Uniform
object directly. Adapters and subclasses continue through the portable Perl
message path.

The Perl layer still owns the public API, portable message mapping, transaction
objects, and transport policy.

The optional `Unblock::HTTP2::NativeABI` exposes the same engine to XS-backed
transports without requiring a Perl byte scalar at the transport boundary.
Borrowed input is passed directly to libnghttp2. Outbound libnghttp2 buffers can
be copied directly into a native transport queue through a short-lived sink
callback. The ABI does not expose the private nghttp2 session or move HTTP/2
state into the transport.

## Integration

An adapter around Unblock::HTTP2 normally owns:

- socket or stream objects
- TLS
- ALPN
- readiness
- output queuing
- connection pooling
- HTTP/1 fallback
- retry and redirect policy

The adapter should not reimplement HTTP/2 framing, HPACK, stream state,
SETTINGS, flow control, trailers, or GOAWAY handling.
