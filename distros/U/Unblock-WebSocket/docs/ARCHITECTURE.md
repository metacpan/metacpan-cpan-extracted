# Unblock::WebSocket architecture

## Purpose

Unblock::WebSocket is the reusable WebSocket protocol engine.

    application
        |
        v
    Unblock::WebSocket
        |
        v
    ordered byte transport chosen by the caller

It must not require Linux, a particular event loop, a socket class, TLS,
file descriptors, or a framework object model.

## Protocol ownership

Unblock::WebSocket owns:

- RFC 6455 framing and masking;
- client/server masking direction;
- fragmentation and continuation rules;
- text UTF-8 validation;
- Ping and Pong semantics;
- Close parsing, validation, echo, and state;
- configurable message/resource limits;
- WebSocket-specific handshake semantics;
- subprotocol negotiation;
- WebSocket extensions.

The caller owns:

- sockets and ordered transport bytes;
- DNS;
- TLS;
- event-loop readiness;
- timers and close deadlines;
- listener/connection policy;
- HTTP transport and protocol selection;
- reconnection and retry policy.

## Public byte boundary

Established WebSocket traffic uses a transport-neutral byte interface:

    $ws->input($bytes);

    while ($ws->want_write) {
        my $bytes = $ws->output;
        $transport->write($bytes);
    }

Transport EOF is explicit:

    $ws->input_eof;

This is the manual public integration contract. Attached transports instead
implement unblock_send(), unblock_finish(), and unblock_abort() and receive
all output automatically. The engine holds their object weakly; a false
unblock_send() return means the entire buffer was accepted and the host is
congested until resume_output(). Calling output() in attached mode is an error.

Both contracts must remain usable with
Linux::Event, IO::Async, AnyEvent, Mojolicious, blocking sockets, in-memory
tests, HTTP/2 streams, HTTP/3 streams, and other ordered byte transports.

## Frames are private protocol machinery

WebSocket frames are not Uniform objects. FIN, RSV bits, opcodes, masking,
payload lengths, fragmentation, and control-frame restrictions are wire
protocol details owned here.

The application-facing message boundary is intentionally cheaper: payload plus
text/binary type. A separate Uniform message object should only be introduced
later if independent implementations need a shared domain object and the value
outweighs per-message allocation cost.

## Handshake boundary

WebSocket uses HTTP to establish the stream, but HTTP transport is not owned by
this distribution.

Unblock::WebSocket::Handshake uses Uniform::HTTP 0.05 request/response objects.

For exact canonical Uniform messages, handshake validation takes one read-only
FastPath ABI 1 view and reads method/status/protocol/header data from that
borrowed view. The view is never retained and the message is not mutated while
it is in use. Uniform subclasses and adapters remain supported through the
portable method contract.

WebSocket-generated handshake requests and responses continue to use the normal
validated Uniform constructors. This keeps the trust boundary small while
still allowing Unblock::HTTP1, Unblock::HTTP2, and Unblock::HTTP3 to use their
own Uniform FastPath serializers when sending those exact canonical objects.
The native established-WebSocket ABI remains independent of Uniform and HTTP.

The handshake supports three forms:

- HTTP/1.1 RFC 6455 Upgrade;
- HTTP/2 Extended CONNECT;
- HTTP/3 Extended CONNECT.

The caller sends those objects through its chosen HTTP implementation.
Unblock::WebSocket does not depend on Unblock::HTTP1, Unblock::HTTP2, or
Unblock::HTTP3 at runtime.

## Reference and native engines

The portable Perl frame engine establishes behavior, API semantics, regression
vectors, and an independent in-memory reference implementation.

The production native backend is derived from the already validated
bq_websocket work in Linux::Event::WebSocket and implements the same observable
protocol behavior behind the same public byte API. It is selected automatically
when available unless a portable-only option is requested.

The portable implementation remains executable as an independent differential
reference for native-engine tests.

## Native fast path requirement

Portability must not force every transport read through an intermediate Perl
scalar before native WebSocket parsing.

The native backend exposes a private, versioned, append-only adapter ABI.
Its requirements are:

- opaque WebSocket engine state;
- borrowed `(data, length)` input windows;
- explicit consumed-byte reporting;
- completed-message events rather than frame objects;
- native output-buffer access or submission callbacks;
- no Linux types, file descriptors, epoll, sockets, or event-loop assumptions;
- no ownership of TLS or HTTP transport;
- ABI version and structure size fields for safe extension;
- an append-only extension-aware suffix for negotiated message transforms such
  as permessage-deflate, without changing the original ABI-v1 prefix.

A Linux::Event adapter can then connect its native Stream consumer directly to
the Unblock native engine without routing raw transport bytes through Perl.

## Intended Linux::Event fast path

The target optimized path is:

    Linux::Event native Stream input
        -> thin Linux::Event WebSocket adapter
        -> Unblock::WebSocket native engine
        -> completed application message

and for output:

    Unblock native output
        -> thin Linux::Event adapter
        -> Linux::Event native Stream output

This should preserve the performance opportunity of the current
Linux::Event::WebSocket bq integration while moving protocol ownership into the
portable distribution.

## Random masking

RFC 6455 client masks require unpredictable random keys. The old Linux-only
engine uses getrandom(2). Unblock cannot make that system call part of its
portable contract.

The portable fallback uses Crypt::SysRandom. The native backend uses one
internal secure-random abstraction backed by the operating system: getrandom(2)
on Linux, BCryptGenRandom on Windows, and arc4random_buf on macOS/BSD systems.
Those platform details stay behind the Unblock boundary and never become part
of the public API.

## Extensions

Extension negotiation and frame transforms belong inside Unblock::WebSocket.

RSV2 and RSV3 remain reserved and are rejected. RSV1 is accepted only when an
extension that owns it has been negotiated, and permessage-deflate uses RSV1 on
the first frame of each compressed data message.

RFC 7692 permessage-deflate is implemented without exposing WebSocket frame
objects as the application API. Compression state is per connection and
directional; negotiated context-takeover and window limits remain protocol
state inside Unblock::WebSocket.

The correctness-first implementation uses Compress::Raw::Zlib with raw DEFLATE
streams and bounded decompression output. An 8-bit negotiated compressor window
uses Z_HUFFMAN_ONLY over a 9-bit zlib raw stream; with no LZ77 distance
references the emitted stream remains valid for the RFC 7692 8-bit limit.

The native bq bridge carries an internal compressed-message bit, accepts RSV1
only when permessage-deflate has been negotiated, preserves that bit through
fragment reassembly, and emits RSV1 on compressed outgoing data. Therefore XS
connections can keep native framing and masking while the same _Deflate object
performs the transform. The private ABI preserves its original version-1 prefix
and appends extension-aware configure/input/send slots for optimized adapters.

Incoming inflater windows are also configured directionally from the negotiated
peer compressor limit, so server_max_window_bits constrains client-side inflate
and client_max_window_bits constrains server-side inflate.

## Close deadlines

The protocol engine owns Close state and Close frames. It does not own elapsed
time.

An adapter may arm a timer when the engine enters closing state and call
C<abort()> if its policy deadline expires. This keeps timer implementation and
event-loop policy outside the protocol engine.

## Performance acceptance rule

Linux::Event::WebSocket must not switch to Unblock::WebSocket merely because
feature parity is reached.

Before replacement, comparable public-path benchmarks must show that the native
Unblock adapter recovers the performance of the existing Linux::Event native
bq implementation within measurement noise, or explains and explicitly accepts
any remaining regression.
