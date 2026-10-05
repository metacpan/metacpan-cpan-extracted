# Unblock::HTTP2 feature scope

Unblock::HTTP2 0.10 is feature-complete for its intended role as a reusable,
event-loop-neutral HTTP/2 protocol engine.

That does not mean every historical or optional HTTP/2 extension is included.

## Included

The 0.10 core includes:

- client and server HTTP/2 sessions
- connection preface handling
- HEADERS, CONTINUATION, DATA, and HPACK through libnghttp2
- Transaction objects carried by multiplexed HTTP/2 streams, including half-close state
- request and response streaming
- trailers
- informational responses
- RST_STREAM with preserved error codes
- SETTINGS send, receive, ACK tracking, and inspection
- connection and stream flow control
- manual receive consumption
- PING
- GOAWAY and graceful draining
- ordinary CONNECT
- Extended CONNECT
- RFC 9218 priorities
- header-list limits
- invalid-frame observation
- safe handling of unknown extension frame types
- fatal session failure reporting
- Uniform::HTTP 0.06 native C path for canonical messages
- versioned native transport ABI with an installed public header for borrowed
  input and native output draining

HTTP messages use Uniform::HTTP 0.06. Exact canonical Uniform messages use the
native C ABI for direct inspection and validated construction. Adapters and
subclasses keep the portable message contract.

## Intentionally not included

### Server Push

Server Push is not exposed. Clients advertise
`SETTINGS_ENABLE_PUSH = 0`.

### Old HTTP/2 priority trees

The deprecated RFC 7540 dependency-tree priority API is not exposed.
Unblock uses RFC 9218 extensible priorities instead.

### Transport and negotiation

Unblock::HTTP2 does not own:

- sockets
- DNS
- TLS
- ALPN
- event loops
- HTTP/1 upgrade negotiation
- connection pooling

### Higher-level HTTP policy

Unblock::HTTP2 does not own:

- automatic retries
- redirects
- cookies
- authentication policy
- proxy policy
- caching

It exposes protocol facts such as GOAWAY boundaries and reset codes so a higher
layer can make those decisions.

### Tunnel protocols

Extended CONNECT is generic.

WebSocket, CONNECT-UDP, MASQUE, and other tunnel semantics belong to their own
protocol layers.

### Optional extension frames

Optional extensions such as ORIGIN and ALTSVC are not required for the 0.10
core.

Unknown frame types are safely ignored as required by HTTP/2.

## Future work

Future changes should normally be one of:

- bug fixes
- interoperability improvements
- performance improvements
- optional extensions
- documentation improvements

The core transport boundary and HTTP/2 session model do not need further
feature work for the 0.10 release.
