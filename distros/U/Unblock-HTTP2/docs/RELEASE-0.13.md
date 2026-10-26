# Unblock::HTTP2 0.13

This release fixes HTTP/2 protocol conformance for late frames, retired
streams, legacy priorities, and stream flow-control errors. The public
API and transport-neutral architecture are unchanged.

## Changes

- Reject invalid DATA and HEADERS on retired or skipped streams while
  preserving valid races after a local RST_STREAM.
- Keep HPACK state correct when trailing headers arrive after a local
  reset, without disrupting other multiplexed streams.
- Validate legacy PRIORITY frames alongside RFC 9218 modern priorities.
- Handle stream-window overflow with a stream-local FLOW_CONTROL_ERROR
  rather than terminating unrelated streams.
- Bound retired-stream history to 1024 distinct ranges. Pathological
  fragmentation closes the connection with ENHANCE_YOUR_CALM.
- Clarify final GOAWAY output, transport shutdown, and graceful drain
  behavior in the integration and cookbook documentation.

## Compatibility

- Minimum Perl: 5.16.
- Requires Uniform::HTTP 0.06 and Alien::nghttp2 0.003 or newer.
- Native transport ABI remains version 1, with no layout changes.
- No new framework or event-loop dependencies.

## Verification

The 0.13 release candidate passed all 147 strict h2spec cases in each
of 16 configurations: cleartext/TLS, responses on headers/full requests,
Perl/NativeABI input, and two libnghttp2 versions (2,352 case executions,
zero failures, errors, or skips). Cross-platform tests, nghttp/nghttpd
interoperability, public POD checks, distcheck, disttest, installed
NativeABI header checks, and optional framework example tests passed.
