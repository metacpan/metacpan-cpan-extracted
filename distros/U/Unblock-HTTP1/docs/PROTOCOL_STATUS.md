# Unblock::HTTP1 protocol status

Unblock::HTTP1 is feature-complete for its declared HTTP/1 protocol-engine
scope.

This file records the protocol behavior covered by the engine. Transport,
application policy, and higher HTTP client/server features are intentionally
outside this distribution.

## HTTP versions and request targets

Implemented:

- HTTP/1.0
- HTTP/1.1
- compatible handling of higher HTTP/1 minor versions
- origin-form request targets
- absolute-form request targets
- CONNECT authority-form
- OPTIONS asterisk-form
- case-sensitive method semantics
- exact request-target preservation
- Host validation and absolute-form authority handling

## Message framing

Implemented:

- Content-Length request and response framing
- repeated equivalent Content-Length values
- conflicting Content-Length rejection
- Transfer-Encoding and Content-Length ambiguity rejection
- chunked request and response framing
- response transfer-coding chains
- close-delimited response bodies
- strict CRLF chunk framing
- configurable chunk-extension limits
- fragmented input
- EOF and truncation handling

## Bodies and trailers

Implemented:

- buffered bodies
- streaming bodies
- request trailers
- response trailers
- ordered trailer preservation
- automatic Trailer field announcement for known outgoing trailers
- forbidden framing fields rejected from trailers
- cooperative output backpressure

## Response semantics

Implemented:

- HEAD
- informational 1xx responses
- 101 protocol switching
- 204
- 205
- 304
- Expect: 100-continue
- unsupported Expect handling
- HTTP/1.0 informational-response rules

## Connections

Implemented:

- HTTP/1.1 persistence
- HTTP/1.0 close-by-default behavior
- HTTP/1.0 keep-alive
- serial client request queueing
- server-side pipelined input boundary preservation
- cancellation
- early final responses
- connection reuse decisions
- unsolicited response-byte rejection

The Client intentionally does not pipeline multiple outstanding requests on one
connection.

## Upgrade and CONNECT

Implemented:

- Upgrade request validation
- Upgrade response validation
- offered protocol matching
- CONNECT authority validation
- CONNECT framing restrictions
- successful CONNECT switch behavior
- non-2xx CONNECT as ordinary HTTP
- exact switch boundaries
- preservation of bytes received after the HTTP boundary

## Security and limits

Implemented:

- obsolete folded-field rejection
- request-smuggling framing checks
- finite configurable head size
- finite configurable header count
- finite configurable chunk-extension budget
- serializer field and method validation
- constructor option validation
- exact protocol-error handling before application delivery where required

## Portability

The engine is independent of sockets, TLS, operating-system readiness APIs, and
event loops.

CI covers:

- Linux
- macOS
- Windows
- Perl 5.16
- current supported Perl in CI

## Outside this distribution

Unblock::HTTP1 intentionally does not own:

- socket creation
- DNS
- TLS or certificate policy
- ALPN
- connection pools
- redirects
- cookies
- authentication policy
- proxy selection
- retry or replay policy
- WebSocket framing
- tunnel protocol implementation
- HTTP/2
- HTTP/3

Those belong to transports, adapters, or higher HTTP layers.
