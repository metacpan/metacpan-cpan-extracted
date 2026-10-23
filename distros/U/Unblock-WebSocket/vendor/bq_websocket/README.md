# Vendored bq_websocket

Upstream: https://github.com/bqqbarbhg/bq_websocket
Upstream commit: 6c188d3f0edca38d7a8926e0d30f4c145414ba4c
License used here: MIT

Unblock::WebSocket vendors the protocol core directly so CPAN installs do not
depend on a system bq_websocket package. The library socket/HTTP layer is not
used. Unblock owns WebSocket protocol behavior only; the caller owns transport,
TLS, HTTP, timers, and event-loop policy.

This source carries the RFC fixes previously proven by
Linux::Event::WebSocket:

- incoming Close codes accept the RFC range through 1014 plus 3000-4999 while
  rejecting reserved 1004, 1005, and 1006;
- incoming Close reasons are checked against RFC 3629 before automatic echo;
- one-byte Close payloads are rejected;
- control payloads larger than 125 bytes are rejected before Ping/Close side
  effects can occur;
- the configured application message limit applies to data frames while control
  frames retain their independent RFC 125-byte limit;
- valid messages queued before a later malformed frame in the same input batch
  remain receivable, preserving wire-order delivery before the protocol error;
- text payloads use incremental RFC 3629 validation while bytes arrive,
  including across continuation frames, so invalid UTF-8 fails as soon as the
  offending octet is knowable rather than waiting for logical message completion;
- negotiated RSV1 is accepted only on the first data frame of a
  permessage-deflate message, carried internally through fragment reassembly,
  and exposed to the Unblock wrapper as a compressed-message flag;
- compressed outgoing data can be queued through the native framer so bq still
  owns framing and masking while Unblock's shared RFC 7692 codec owns DEFLATE;
- every received Ping retains its own Pong response instead of keeping only the
  latest pending Pong;
- when control messages are exposed, a validated received Close is copied before
  the original object is retained for automatic echo; rejected Close frames are
  never copied, preserving native allocation ownership on protocol errors.

The former Linux-only getrandom(2) masking patch is intentionally not present.
Client mask entropy is supplied by Unblock::WebSocket's native portability
layer. That layer uses a secure operating-system source behind one internal
interface, so the bq protocol core itself has no platform dependency.

The XS adapter configures bq with skip_handshake, disables its automatic
ping/timeout policy, removes the library's partial-fragment count cap while
preserving the configured message-size limit, and compiles each context
single-threaded because an individual WebSocket engine is driven serially by
its caller.

Any future upstream refresh must re-apply and re-test these differences with
the normal suite and Autobahn before it is accepted.
