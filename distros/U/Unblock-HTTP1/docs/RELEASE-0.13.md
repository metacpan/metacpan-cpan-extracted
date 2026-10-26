# Unblock::HTTP1 0.13

This release improves graceful shutdown, HTTP/1 response serialization,
memory ownership, and bodyless request processing without changing the
framework-neutral protocol interface.

## Changes

- Add `Server->drain()` to finish an admitted request and its response
  while refusing subsequent pipelined requests. The transport retains
  responsibility for flushing accepted bytes and enforcing deadlines.
- Serialize simple canonical `Uniform::HTTP` responses through a native
  fast path. Complex framing and subclasses retain the existing path.
- Stop retaining a second serialized output buffer after its bytes have
  moved into the engine output queue.
- Skip redundant completion and freezing work on already validated,
  complete bodyless requests.
- Add regression coverage for draining, response parity, output ownership,
  and bodyless request lifecycle.

## Compatibility

- Perl 5.16 or newer; `Uniform::HTTP >= 0.06`.
- Native borrowed-input ABI remains at version 1.
- No event-loop, transport, or framework-specific dependency is added.
- Consumers that call `Server->drain()` require Unblock::HTTP1 0.13 or newer.

## Verification

The 0.13 candidate passed the standalone test matrix on Linux, macOS,
and Windows, including the Perl 5.16 lane. Framework example smoke tests,
POD syntax checks, `distcheck`, and `disttest` also passed. The
coordinated Linux::Event::HTTP regression suite remained green.
