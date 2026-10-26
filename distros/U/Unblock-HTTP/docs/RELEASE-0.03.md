# Unblock::HTTP 0.03

This release extends the common Client and Server interfaces for
HTTP/1.1, HTTP/2 and HTTP/3 while keeping their standalone engines and
framework transports independent.

## Changes

- Add `on_transaction` to notify the Client when its real engine
  Transaction is admitted. Streaming producers can begin without polling.
- Add generic `on_handoff` for HTTP/1.1 Upgrade/CONNECT socket transfer
  and HTTP/2/HTTP/3 CONNECT stream-local handoff.
- Preserve HTTP/2 and HTTP/3 multiplexing during CONNECT handoff, with
  bounded deferred body transfer, EOF and backpressure handling.
- Release abandoned speculative HTTP/3 connectors when stream credit
  returns or the shared Client shuts down.
- Make HTTP/2 and HTTP/3 optional installation features. A default
  HTTP/1-only installation does not require HTTP/2, QUIC or WebSocket.

## Compatibility

- Perl 5.20 or newer and Uniform::HTTP 0.06 or newer.
- Unblock::HTTP1 0.13 or newer is required.
- Unblock::HTTP2 0.13 and Unblock::HTTP3 0.14 or newer are optional.
- WebSocket support uses the separately installed Unblock::WebSocket 0.02.
- No framework-specific adapter or event-loop dependency is bundled.

## Verification

Standalone HTTP1-only tests, real TCP/TLS/QUIC integration, WebSocket
and CONNECT handoff regressions, and release packaging checks passed.
The CPAN installability workflow separately verifies published engines,
the optional WebSocket distribution and the built source archive.
