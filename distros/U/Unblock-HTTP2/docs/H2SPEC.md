# HTTP/2 conformance checks

The `h2spec` workflow runs pinned h2spec 2.6.0 against a standalone
Unblock::HTTP2 server. It requires all 147 strict cases to pass, without
failures, errors or skips. It tests both the system nghttp2 and pinned 1.70.0.

Each backend runs eight combinations: TCP/TLS, responses at initial headers
or after the full request, and Perl input or NativeABI input. No framework
adapter is involved. TLS uses the optional test dependency IO::Socket::SSL.
The fixture body is long enough to exercise the negative flow-control-window
case; a three-byte body causes h2spec to skip that case.

## Run locally

Build the distribution normally, then run:

```sh
perl Makefile.PL
make test
H2SPEC_BIN=/path/to/h2spec bash .github/scripts/check-h2spec.sh
```

This runs the four TCP combinations. To include TLS, supply
`UNBLOCK_HTTP2_TLS_CERT` and `UNBLOCK_HTTP2_TLS_KEY` with a test certificate
and key. Reports and complete server logs are written to `.h2spec-results`.
The test runner also rejects unexpected fixture exceptions or child crashes;
a crashed server must not count as a successful protocol-error response.

`t/47-h2spec-regressions.t` runs without h2spec or sockets. It checks exact
GOAWAY codes, fragmented/coalesced input, both input APIs, client and server
stream retirement, local-reset races and HPACK continuity, modern priority
negotiation, error precedence and bounded stream-history storage.

## What the repair covers

The reported 13 failures came from the earlier standalone TLS fixture in
Linux::Event::HTTP workflow 40166951263. Ten were also present through that
framework's native and Perl adapters:

| h2spec cases | Fault covered |
| --- | --- |
| http2/5.1/5, 6, 8, 9, 11, 12; http2/6.1/2 | DATA or HEADERS after the peer closed/reset its stream |
| http2/5.1.1/2 | Opening a previously skipped lower stream ID |
| http2/5.3.1/2; http2/6.3/1 | Legacy PRIORITY self-dependency or stream zero |

The remaining three cases (generic/3.8, http2/5.4.1/1 and http2/7/1) concern
connection shutdown. A manual driver must drain final protocol output and
then close the socket when the engine no longer wants input or output. The
new fixture follows this contract. Keeping an idle socket open after GOAWAY
can produce a timeout even when the engine generated the right response.
Conversely, closing TCP with unread data can send RST and hide the final
protocol error. The fixture half-closes its write side and briefly drains
in-flight input, including TLS shutdown, before the final socket close.

The local 1.59.0 baseline reproduced seven of the ten protocol cases; the
other three are sensitive to response/input scheduling. The regression suite
and CI cover both early and completed-request response timing.

## Receive boundary and resource policy

nghttp2 owns framing, HPACK, active stream validation and flow control.
With modern priorities enabled it discards closed streams, so its conservative
fallback cannot distinguish some invalid late frames from legitimate bytes
already in flight after a local reset.

The private receive guard records coalesced ranges of retired request stream
IDs and skipped IDs. It distinguishes peer closure from local resets, leaving
legitimate late DATA and trailers after a local reset to nghttp2, including
HPACK updates needed by other streams. A later peer RST_STREAM ends that
exception. Both regular input and NativeABI use this same guard.

The guard inspects frame envelopes, the five-byte legacy PRIORITY payload,
and the four-byte stream WINDOW_UPDATE increment. nghttp2 1.70.0 escalates
stream-window overflow to a connection error; the guard instead queues the
required FLOW_CONTROL_ERROR stream reset using nghttp2's authoritative send
window. Other streams continue normally.
It does not decode HPACK or copy body payloads. Fragmented prefixes need at
most 14 bytes. Ordinary sequential completion coalesces into one history range,
so the history does not grow with the total number of normal requests.

A connection producing more than 1024 separate history ranges is terminated
with ENHANCE_YOUR_CALM. This bounds memory for pathological patterns of skipped
IDs, out-of-order closure and mixed reset histories. It is a limit on history
fragmentation, not on requests or concurrent streams. Forgetting old reset
facts would make legitimate late frames indistinguishable from illegal reuse.

Modern RFC 9218 negotiation and the public API/native ABI remain unchanged.
EOF, GOAWAY and wire errors still use the normal output/transport lifecycle.
