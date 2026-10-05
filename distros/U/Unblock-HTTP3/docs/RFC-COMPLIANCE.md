# RFC compliance

This file records the protocol-completeness audit for Unblock::HTTP3.

The goal is to make ownership clear. Some HTTP/3 requirements are enforced in
Perl, some are intentionally delegated to libnghttp3, and QUIC transport rules
belong to Net::QUIC.

## RFC 9114 - HTTP/3

Covered by Unblock::HTTP3 and its tests:

- request and response streams
- informational and final responses
- buffered and streaming bodies
- trailers
- CONNECT and Extended CONNECT stream semantics
- SETTINGS state and extension SETTINGS
- graceful shutdown and GOAWAY
- field-section size enforcement
- connection-specific field rejection
- Host and :authority validation
- Content-Length validation
- Perl-layer malformed-message stream rejection
- server-initiated bidirectional stream rejection
- unauthorized server-push rejection when no push capacity was advertised
- reserved and unknown unidirectional stream handling
- critical-stream closure, reset, and STOP_SENDING handling
- decompressed Cookie field-line coalescing
- replay-safe server delivery of 0-RTT requests

libnghttp3 owns the HTTP/3 frame state machine, HEADERS/QPACK decoding, frame
placement checks, SETTINGS-first enforcement, duplicate critical stream
detection, GOAWAY validation, and native request/response serialization.

Known native-library limitation:

RFC 9114 requires a detected malformed request or response to be a request
stream error of type H3_MESSAGE_ERROR. libnghttp3 1.18.0 returns internally
detected malformed HTTP header and messaging errors from
`nghttp3_conn_read_stream2()`, whose public contract says any negative return
is a connection error and the connection object must no longer be used.
Unblock::HTTP3 handles malformed semantics that reach its Perl validation as
request-stream H3_MESSAGE_ERROR, but malformed cases rejected inside
libnghttp3 can therefore close the whole connection.

Current upstream libnghttp3 1.18.90 documents the same contract, so a simple
library upgrade does not remove this limitation.

Server Push is optional in HTTP/3 and is not exposed by Unblock::HTTP3. Because
Unblock::HTTP3 never advertises push capacity, incoming push streams are
unauthorized and are rejected.

RFC 9114 imports the HTTP early-data replay rules. Unblock::HTTP3 may parse
0-RTT request bytes before the QUIC handshake completes, but it does not expose
the Transaction or run application Datagram policy until the handshake is
complete and the early data has not been rejected.

QUIC packet processing, stream flow control, TLS, transport 0-RTT acceptance,
congestion control, retransmission, migration, and timers remain Net::QUIC
responsibilities.

## RFC 9204 - QPACK

QPACK encoding and decoding are provided by libnghttp3.

Unblock::HTTP3 configures and validates:

- SETTINGS_QPACK_MAX_TABLE_CAPACITY
- SETTINGS_QPACK_BLOCKED_STREAMS
- QPACK encoder and decoder critical stream lifecycle
- duplicate QPACK stream rejection through libnghttp3
- QPACK encoder and decoder instruction errors through libnghttp3
- remembered nonzero QPACK capacity across accepted 0-RTT

A remembered nonzero dynamic-table capacity must be repeated exactly for 0-RTT.
An incompatible value uses QPACK_DECODER_STREAM_ERROR.

## RFC 9218 - Extensible Priorities

Supported:

- Priority request field
- RFC default urgency and incremental values
- Transaction priority inspection
- client PRIORITY_UPDATE
- server local scheduling override
- PRIORITY_UPDATE control-stream placement and direction checks
- invalid request-stream identifiers
- malformed Priority fields falling back to defaults

Known native-library limitation:

libnghttp3 1.18.0 does not fully preserve the RFC 9218 rule that, after a
Structured Fields Dictionary parses successfully, a recognized priority
parameter with an out-of-range value or unexpected type is ignored while other
valid parameters still apply. Its priority parser can reject the complete
priority value instead.

libnghttp3 does not expose the raw received PRIORITY_UPDATE value through a
public callback, so Unblock::HTTP3 cannot completely repair this behavior
without adding its own RFC 8941 Structured Fields parser or replacing that part
of native priority processing.

Push-priority updates are not applicable while Server Push is not exposed.

## RFC 9220 - Extended CONNECT

Supported:

- SETTINGS_ENABLE_CONNECT_PROTOCOL
- :protocol
- required Extended CONNECT pseudo-fields
- client refusal before peer capability is known
- server refusal when Extended CONNECT was not enabled
- application-visible protocol identifier
- full-duplex DATA and half-close behavior
- application rejection of unsupported protocols

Protocol-specific session semantics remain above Unblock::HTTP3.

## RFC 9297 - HTTP Datagrams and Capsule Protocol

Supported HTTP Datagram behavior includes:

- SETTINGS_H3_DATAGRAM
- setting value validation
- negotiation in both directions
- Quarter Stream ID encoding and decoding
- maximum Quarter Stream ID validation
- malformed Datagram rejection with H3_DATAGRAM_ERROR
- empty Datagram payloads
- path-size accounting
- closed receive-side Datagram dropping
- future-stream Datagram dropping
- request-level semantic opt-in
- request abort when a Datagram has no negotiated request semantics
- bounded receive queues
- 0-RTT setting compatibility
- bounded early Datagram retention until replay-safe application delivery

Supported Capsule behavior includes:

- QUIC-varint Capsule Type and Length
- incremental parsing
- GREASE Capsule types
- unknown Capsule ignoring
- bounded retained values
- truncation detection
- per-request malformed-message handling
- Extended CONNECT data-stream integration
- prohibition of Content-Length, Content-Type, and Transfer-Encoding
- prohibition of status 204, 205, and 206 while Capsule Protocol is active
- Capsule-Protocol response-header status restriction

The meaning of individual Capsule Types and the negotiation rules of the
higher-level protocol remain outside this module.

## RFC 9412 - ORIGIN

Supported:

- server ORIGIN advertisement
- empty ORIGIN frame
- multiple origin entries
- RFC 6454 ASCII origin validation when sending
- client inspection of peer origins
- invalid received origin serializations ignored
- defensive copies of the peer origin set

The ORIGIN frame is serialized and parsed by libnghttp3 on the HTTP/3 control
stream.

## Audit tests

The focused audit coverage is primarily in:

- t/01-native.t
- t/04-http3-loopback.t
- t/05-field-rules.t
- t/07-content-length.t
- t/08-extension-settings.t
- t/09-capsule.t
- t/10-priority.t
- t/11-http-datagram.t
- t/12-settings-state.t
- t/13-zero-rtt.t
- t/14-origin.t
- t/16-rfc-wire-errors.t
- t/17-critical-stream-lifecycle.t
- t/18-client-protocol-errors.t
- t/19-cookie-coalescing.t

The interoperability tests under xt/ additionally exercise independent HTTP/3
implementations.
