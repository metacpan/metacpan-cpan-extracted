# Unblock::HTTP3 architecture

## Purpose

Unblock::HTTP3 is an HTTP/3 protocol engine.

It owns:

- HTTP/3 connection state
- HTTP/3 control streams
- QPACK through libnghttp3
- request and response header translation
- informational responses
- HTTP/3 DATA handling
- trailers
- request stream multiplexing
- basic and Extended CONNECT tunnels
- generic HTTP/3 extension SETTINGS
- generic RFC 9297 Capsule Protocol streams
- RFC 9297 HTTP Datagrams over QUIC DATAGRAM
- generic HTTP/3 extension unidirectional streams
- RFC 9218 request priority
- HTTP message validation
- HTTP/3 stream lifecycle and errors
- HTTP/3 resource limits
- graceful HTTP/3 shutdown
- remembered HTTP/3 SETTINGS and 0-RTT compatibility validation

It does not own:

- UDP sockets
- TLS
- QUIC packet processing
- retransmission or congestion control
- timers
- an event loop
- a web framework

## Layering

The stack is:

    application or HTTP library
            |
        Unblock::HTTP3
            |
        Net::QUIC
            |
            UDP

libnghttp3 is an implementation detail of Unblock::HTTP3.

ngtcp2 and TLS remain below Net::QUIC.

## HTTP message objects

Uniform::HTTP 0.04 is the runtime HTTP message layer.

`Unblock::HTTP3::Request` is a thin subclass of `Uniform::HTTP::Request`.
`Unblock::HTTP3::Response` is a thin subclass of
`Uniform::HTTP::Response`. They inherit the common message implementation
instead of copying it.

A client may also submit a plain `Uniform::HTTP::Request` directly.
Unblock::HTTP3 validates the request for HTTP/3 when it is sent. This keeps
Uniform neutral: it can represent temporarily incomplete or cross-field-invalid
message combinations while the selected protocol engine remains responsible
for deciding what is legal on its wire.

An application-created Uniform request may leave `version` undefined. If a
message carries an explicit version, Unblock::HTTP3 requires it to be `3`
before sending so incompatible metadata is not silently placed on an HTTP/3
connection.

Uniform owns:

- method, target, scheme, authority, and Extended CONNECT protocol metadata
- status and reason metadata
- ordered headers and trailers
- complete buffered bodies
- header and trailer fidelity
- section mutability and whole-message completeness

Unblock::HTTP3 adds only protocol-engine concerns. Its Request convenience
subclass adds RFC 9218 priority helpers and stream-abort diagnostics. Its
Response convenience subclass adds stream-abort diagnostics.

## Transactions

One Unblock::HTTP3::Transaction represents one client-initiated bidirectional
HTTP/3 request stream.

The Transaction keeps the Request and final Response paired even when many
streams are active and responses arrive out of order.

It also owns:

- request and response streaming-body state
- buffered receive accumulation until a complete Uniform body is available
- informational responses
- HTTP Datagram send and receive state
- live RFC 9218 request priority
- cancellation state
- completion state

Applications do not need to match responses with raw QUIC stream IDs.

## QUIC boundary

Unblock::HTTP3 uses the public protocol-engine API in Net::QUIC 0.04.

Receive data follows this path:

    Net::QUIC::Stream->next_data_chunk
        -> nghttp3_conn_read_stream2
        -> HTTP message or Body::Reader
        -> Net::QUIC::Stream->consume

For buffered input, receive credit is returned immediately after DATA is
copied into Transaction-owned accumulation state. Partial bytes are not exposed
through `Uniform::HTTP::Message::body`. When the message ends, the complete
buffer is installed in the Uniform message in one operation.

For streaming input, DATA stays outside the Uniform message and receive credit
is held until the application consumes the chunk through Body::Reader.

Send data follows this path:

    HTTP body producer
        -> libnghttp3 data reader
        -> nghttp3_conn_writev_stream
        -> Net::QUIC::Stream->send_some
        -> nghttp3_conn_add_write_offset

Acknowledgements follow this path:

    Net::QUIC::Stream->acked_offset
        -> nghttp3_conn_update_ack_offset
        -> nghttp3 acked_stream_data callback
        -> release retained body memory

Stream activity is coalesced through:

    Net::QUIC::Connection->on_stream_activity
    Net::QUIC::Connection->next_active_stream_id

HTTP Datagrams use the separate Net::QUIC 0.04 RFC 9221 boundary:

    Transaction->send_datagram
        -> Quarter Stream ID + payload
        -> Net::QUIC::Connection->send_datagram

    Net::QUIC::Connection->on_datagram
        -> decode Quarter Stream ID
        -> Transaction callback or bounded receive queue

Net::QUIC owns QUIC DATAGRAM negotiation, path capacity, unreliable delivery,
and transmit backpressure. Unblock::HTTP3 owns SETTINGS_H3_DATAGRAM, HTTP request
association, and H3_DATAGRAM_ERROR.

Unblock::HTTP3 does not reach into Net::QUIC native structures.

## 0-RTT and SETTINGS persistence

QUIC/TLS early-data state remains owned by Net::QUIC. HTTP/3 SETTINGS state is
kept separately because a client using 0-RTT must begin with the server
settings remembered from the resumed session.

The client saves:

    Net::QUIC::Connection->early_data_state
    Unblock::HTTP3::Connection->peer_settings_state

and restores them to the matching layers on the returning connection.

The server can export its advertised HTTP/3 state with
`local_settings_state`. A server that permits early data supplies the matching
opaque value as `remembered_local_settings` before it begins parsing 0-RTT
request streams.

Unblock::HTTP3 validates the new server SETTINGS after accepted early data.
HTTP/3 limits cannot become less permissive in a way that could invalidate the
early request. Previously non-default understood settings cannot silently
disappear. SETTINGS_H3_DATAGRAM follows RFC 9297. A remembered nonzero
SETTINGS_QPACK_MAX_TABLE_CAPACITY follows RFC 9204 and must be repeated exactly;
a mismatch uses QPACK_DECODER_STREAM_ERROR.

0-RTT request transmission is explicit with `early_data => 1`. This is a
replay-safety boundary: Unblock::HTTP3 never resends an early request
automatically.

If QUIC rejects early data, the early Transaction is marked as an error. The
early request, control, and QPACK streams are discarded, a fresh libnghttp3
connection is created, new 1-RTT control and QPACK streams are bound, and the
Connection remains usable for an application-selected retry.

## Bodies

Buffered request and response bodies are supported.

Incremental outgoing request and response bodies are supported through
Unblock::HTTP3::Body::Stream.

The producer follows the same basic backpressure convention as
Linux::Event::HTTP:

    my $can_continue = $body->write($bytes);

A false return means the bytes were accepted but production should pause until
`on_drain` runs.

Incremental incoming bodies are supported through Unblock::HTTP3::Body::Reader.

A reader can be used with callbacks or pulled with `next_chunk`. DATA is not
duplicated into the Request or Response body in streaming receive mode.

## Request routing fields

Unblock::HTTP3 validates routing information before sending requests and before
creating server Transactions.

For normal http/https requests:

- Host and :authority must agree when both are present
- authority must not contain userinfo
- :path must start with /
- OPTIONS may use *
- URI fragments are not allowed in :path

For basic CONNECT:

- :authority is required
- :scheme and :path are omitted
- authority must contain an explicit host and port
- the port must be from 1 through 65535
- bracketed IPv6 authorities such as [::1]:443 are accepted

For Extended CONNECT:

- the server advertises SETTINGS_ENABLE_CONNECT_PROTOCOL
- :protocol identifies the higher-level protocol
- :scheme, :authority, and :path use ordinary request semantics
- the Transaction exposes the protocol identifier
- Unblock::HTTP3 does not assign application semantics to the identifier

A malformed received request is rejected as a stream error using
H3_MESSAGE_ERROR. The HTTP/3 connection and unrelated multiplexed requests
remain alive.

## Content-Length

libnghttp3 validates received Content-Length values and checks them against the
sum of received DATA frame lengths.

Unblock::HTTP3 validates the outgoing side before bytes are submitted:

- malformed Content-Length values are rejected
- duplicate Content-Length fields are rejected
- buffered body length must match
- incremental bodies cannot exceed the declared length
- incremental bodies cannot finish before the declared length

HEAD and 304 responses may carry representation length without carrying DATA.

204 responses and successful CONNECT responses do not allow Content-Length.
A 205 response can only use Content-Length 0.

## Informational responses

HTTP 1xx responses are kept separate from the final Response.

The server can send informational responses before the final response, and the
client can retrieve them from the Transaction. HTTP/3 does not use status 101.

## Bodyless responses

Unblock::HTTP3 prevents applications from sending response content where HTTP
semantics prohibit it.

This covers:

- responses to HEAD
- 204 responses
- 205 responses
- 304 responses

Buffered bodies, incremental bodies, and trailers are rejected for these
responses.

## CONNECT

Basic CONNECT is supported.

A basic client CONNECT request sends:

    :method = CONNECT
    :authority = host:port

It omits :scheme and :path.

Extended CONNECT is also supported. A server opts in to
SETTINGS_ENABLE_CONNECT_PROTOCOL. An Extended CONNECT request additionally
carries :protocol and uses :scheme, :authority, and :path.

A successful 2xx response changes either kind of CONNECT request stream into
a bidirectional tunnel. DATA after that point is tunnel data rather than
ordinary HTTP content.

The tunnel supports:

- data in both directions
- streaming backpressure
- half-close behavior
- cancellation and abnormal closure
- rejected non-2xx CONNECT responses
- normal stream cleanup

The Extended CONNECT protocol identifier is intentionally opaque to
Unblock::HTTP3. Higher-level protocol behavior belongs above this module.

## Extension streams

HTTP/3 extensions can register unidirectional stream types before a Connection
starts.

Unblock::HTTP3 reads the stream-type varint first. Core HTTP/3 and QPACK stream
types continue into libnghttp3. Registered extension types are handed to
L<Unblock::HTTP3::Extension::Stream>. Unknown stream types are discarded, as
required by HTTP/3, without becoming connection errors.

The extension stream wrapper preserves QUIC receive credit: polling reads only
what the extension asks for, while callback mode returns credit after the
callback handles the bytes.

Unblock::HTTP3 does not expose a generic raw extension-frame writer on request or
control streams. Those streams remain owned by libnghttp3.

## Request priority

Unblock::HTTP3 uses libnghttp3's RFC 9218 priority machinery.

libnghttp3 also needs the cumulative number of client bidirectional streams
permitted by QUIC so it can validate PRIORITY_UPDATE element IDs. Net::QUIC
0.04 defaults that transport value to 100 and replenishes MAX_STREAMS as
peer-created streams close.

Unblock::HTTP3 mirrors that default into libnghttp3 and advances the native
cumulative value when peer request streams fully close. If a server changes
Net::QUIC's transport max_bidi_streams setting, it must pass the same initial
value as quic_max_bidi_streams when creating the HTTP/3 server Connection.

This synchronization is only for libnghttp3 validation. Net::QUIC still owns
the real QUIC stream limit and MAX_STREAMS frames.

The initial priority is an ordinary HTTP Priority field on the Request.
Unblock::HTTP3 uses libnghttp3 to parse the field so malformed or extended
Structured Field values do not require a second Perl parser.

A client Transaction can change priority after request submission. libnghttp3
emits the PRIORITY_UPDATE frame on the HTTP/3 control stream.

A server Transaction reads the effective stream priority from libnghttp3 and
can override it for local response scheduling. The public API exposes only
urgency and the incremental flag, not native structs or frame details.

## Capsule Protocol

RFC 9297 Capsules use the same DATA path as an Extended CONNECT tunnel.

`Transaction->capsules` provides a small wrapper around the existing readable
and writable body streams. It adds Capsule type-length-value framing,
incremental parsing, type dispatch, and bounded value buffering. It does not
assign semantics to Capsule Types.

Malformed or truncated Capsules fail the affected request stream with
H3_MESSAGE_ERROR. They do not fail unrelated multiplexed requests.

Unknown Capsule Types can be skipped incrementally without buffering their
values when the caller uses type-dispatch handlers.

## Trailers

Request and response trailers are supported.

They are stored separately from normal headers by Uniform::HTTP 0.04.
Incoming initial fields are frozen when their HEADERS section completes while
trailers remain independently writable until the trailing section ends.

Fields that affect framing or routing are not generated as trailers.
Content-Length, Host, and TE are rejected on the outgoing trailer path.

## QPACK

QPACK is handled by libnghttp3.

Unblock::HTTP3 exposes configuration for the local QPACK dynamic-table capacity
and blocked-stream limit.

The defaults remain conservative.

## Stream lifecycle

RESET_STREAM and STOP_SENDING are passed between Net::QUIC and libnghttp3.

The Unblock Request and Response convenience subclasses record stream-abort
diagnostics without changing Uniform's generic message contract. Transaction
state remains the authoritative HTTP/3 lifecycle.

Cancelled streaming body buffers are released without losing later QUIC ACK
accounting.

Completed stream state and native body contexts are removed so a long-lived
connection does not accumulate finished transactions indefinitely.

## Protocol errors

libnghttp3 reports parser errors together with the HTTP/3 application error
code that should close QUIC.

After a fatal libnghttp3 read error, Unblock::HTTP3 stops calling into that native
HTTP/3 connection and closes the underlying Net::QUIC connection.

Malformed received messages, including Content-Length mismatches, are handled
by libnghttp3 using HTTP/3 message errors.

## Resource limits

The default decoded field-section limit is 64 KiB.

The default buffered message-body limit is 64 MiB.

The default queued streaming receive-body limit is 4 MiB.

These limits are configurable.

The field-section limit is advertised in HTTP/3 SETTINGS and is also enforced
locally. Resource-limit violations close the HTTP/3 connection with
H3_EXCESSIVE_LOAD.

Unblock::HTTP3 also records the peer's SETTINGS_MAX_FIELD_SECTION_SIZE and checks
every outgoing header and trailer section before submission. An oversized
local field section is rejected before a new request stream is opened.

HTTP/3 integer settings are also checked against the 62-bit QUIC variable
integer range before native state is created.

## Graceful shutdown

Unblock::HTTP3 can send the HTTP/3 shutdown notice and begin final graceful
shutdown.

Timing remains outside this module. An event-loop adapter or application can
decide when enough time has passed between the shutdown notice and final
shutdown.

## Scope

The first release is focused on the core HTTP/3 engine.

HTTP Datagrams and the current generic HTTP/3 extension surface are implemented.

HTTP/3 0-RTT is implemented with separate opaque QUIC and HTTP/3 saved state.
Accepted early data validates the new SETTINGS, and rejected early data rolls
back HTTP/3 stream state before ordinary 1-RTT use continues.

WebTransport and MASQUE applications are higher-level protocols, not missing
Unblock::HTTP3 features. They can build on the generic HTTP/3 facilities provided
here.

libnghttp3 1.18.0 explicitly does not implement HTTP/3 Server Push. Unblock::HTTP3
therefore does not expose Server Push.

## Dependency policy

Development and CI use released CPAN dependencies.

The current baseline is:

- Alien::nghttp3 0.01
- Net::QUIC 0.04
- Uniform::HTTP 0.04 as the runtime HTTP message layer

Unblock::HTTP3 integration tests do not install Net::QUIC from GitHub.

This keeps the tested dependency graph equal to what CPAN users can install.

## Proven integration path

The real loopback suite currently proves:

1. kernel UDP sockets
2. real QUIC and TLS handshake with h3 ALPN
3. HTTP/3 control and QPACK streams
4. GET and final response exchange
5. 103 Early Hints before a final response
6. buffered request and response bodies
7. streaming request and response production
8. streaming request and response consumption
9. ACK-driven output backpressure
10. request and response trailers
11. multiple concurrent request streams with out-of-order responses
12. cancellation with STOP_SENDING and RESET_STREAM
13. bounded transmit and receive buffering
14. HTTP/3 resource-limit errors
15. fatal libnghttp3 parser error mapping
16. basic CONNECT tunnels in both directions
17. CONNECT half-close and rejected CONNECT handling
18. generic extension SETTINGS in both directions
19. Extended CONNECT negotiation and bidirectional DATA
20. protocol-neutral Extended CONNECT rejection
21. generic Capsule Protocol framing and dispatch
22. malformed Capsule stream isolation
23. SETTINGS_H3_DATAGRAM negotiation over Net::QUIC 0.04
24. bidirectional HTTP Datagram routing by Quarter Stream ID
25. HTTP Datagram callbacks, zero-length payloads, and H3_DATAGRAM_ERROR
26. RFC 9218 initial and live priority updates
27. bodyless response semantics
28. outgoing Content-Length validation
29. completed stream and native-body cleanup
30. persistent HTTP/3 peer SETTINGS state
31. accepted 0-RTT request delivery
32. 0-RTT HTTP Datagram routing
33. rejected 0-RTT rollback and clean 1-RTT retry

A separate public-network suite verifies multiplexed streaming requests against
independent Cloudflare and LiteSpeed HTTP/3 servers.

All dependency modules are installed from CPAN.