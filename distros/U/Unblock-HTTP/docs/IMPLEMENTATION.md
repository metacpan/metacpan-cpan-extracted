> **Release note (2026-10-21):** This file is an engineering history with
> dated feature-branch checkpoints and obsolete development restrictions.
> For the released 0.02 API and dependency requirements, use README.md,
> Makefile.PL, and the public module POD. The completed work is on main.
>
## HTTP3 Client WebSocket Extended CONNECT (2026-10-20)

The unified Client now implements opt-in `http3 => { websocket => 1 }`
with `connect_websocket(url => 'wss://...', http_version => '3')`.
Version 3 becomes the implicit selection only when H1 and H2
WebSocket modes are not enabled. The read-only WebSocket handshake
helper constructs a real HTTP3 Extended CONNECT; the original
Client pools and `connect_quic` factory remain in use.

The H3 Client does not send CONNECT until the CURRENT peer HTTP3
SETTINGS frame has arrived and confirms
SETTINGS_ENABLE_CONNECT_PROTOCOL = 1. Its
`on_extension_settings` callback schedules pool admission on a
later framework-deferred turn, avoiding reentrancy into H3/QUIC
receive callbacks. Remembered early-data settings are insufficient.
An existing H3 connection waiting for SETTINGS does not trigger
more QUIC connection attempts. A peer without support fails the
unsent operation with on_error/on_finish, with no CONNECT or
fallback. If H3 request credit is exhausted, the existing
on_request_available one-shot wakeup retries that SAME queued
operation without a second socket or replay of sent bytes.

A successful HTTP 200 creates the real
`Unblock::WebSocket::Client`, available through on_open and
`operation->websocket()`. Incoming HTTP3 DATA is delivered to
its `input` callback. Outgoing frames go through the existing
deferred per-stream `_WebSocketH2Body` bridge to the real H3
Transaction. Stream cancellation, Close, on_finish, H3 body credit,
and Client shutdown follow the existing multiplexed pool
lifecycle. The underlying QUIC connection can carry multiple
WebSockets and ordinary HTTP3 streams simultaneously.

One real QUIC test uncovered a rejected-handshake bug: exceptions
thrown by the H3 client response validation could unwind the QUIC
receive callback. HTTP3 now records the application operation
error, schedules stream-local cancellation outside the callback,
and discards an ordinary HTTP 400/403 error response body without
attempting to parse it as WebSocket frames. H2's existing tested
error path remains unchanged.

t/36-client-websocket-h3.t exercises the full unified Client and
Server over real localhost UDP/TLS using published Net::QUIC 0.05:
QUIC factory, peer SETTINGS gate, outgoing/incoming WebSocket
frames, multiple concurrent WebSocket streams, ordinary HTTP3
request, rejected handshake, stream-local cancellation, Client
shutdown while a WebSocket remains active, and WebSocket Close.
t/37-client-h3-websocket-admission.t verifies unsupported peer
SETTINGS and QUIC credit exhaustion without new socket attempts.
Both tests and the corrected H3 rejection lifecycle PASSED
FULL CI at production/test source
a3f429edf66562a55ab23e0d5b55a8e3eb989b7c:
- Published Net::QUIC 0.05: run 39516674510 PASS
- Optional QUIC MAX_DATA feature: run 39516674529 PASS
Both ran 29 distribution files and 1,170 checks, including real
QUIC/TLS WebSocket Client/Server, unsupported peer SETTINGS, and
stream-credit retry without opening another socket. Existing live
TCP/QUIC, resource tests and diagnostic smoke also passed. No
performance change is claimed. No lower library, native ABI or
QUIC library changes were needed.

## HTTP3 Server WebSocket Extended CONNECT (2026-10-20)

Opt-in `http3 => { websocket => 1 }` now enables the unified
Server's per-stream RFC9220 WebSocket Extended CONNECT over HTTP/3,
using the same application `on_websocket($tx, $request)` API as H1/H2.
The Server requires a `defer($work)` callback which schedules work on
a later event-loop turn. It advertises HTTP/3 Extended CONNECT setting 8
only when enabled; `enable_extended_connect => 0` with WebSocket
enabled is explicitly rejected. The lower Unblock::HTTP3 and Net::QUIC
libraries remain read-only.

The existing H3 Transaction receives incoming CONNECT DATA with its
native streaming `on_data` callback, and the actual
Unblock::WebSocket::Server parses WebSocket frames. On handshake success
the transaction responds HTTP 200 with `stream_body => 1`. The same
deferred per-stream outgoing frame bridge used for H2 supplies
`Transaction->write`, `end`, and `on_drain`; the bridge schedules
those calls outside native protocol callbacks. No QUIC stream or
connection wrapper, new UDP socket, or app-level HTTP parser is
introduced. A normal H3 request continues through the direct HTTP
callbacks unchanged. Application denial uses HTTP 403, invalid WebSocket
handshakes HTTP 400. A terminal transaction releases its WebSocket
bridge independently of sibling streams.

`t/35-server-websocket-h3.t` establishes **real** Net::QUIC 0.05
UDP/TLS loopback connections with generated short-lived localhost
certificates, negotiates H3 SETTINGS, sends a WebSocket greeting and
echo in both directions over HTTP3 DATA, verifies ordinary HTTP3
requests can share the connection, and tests WebSocket Close/FIN.
Expanded cases cover invalid HTTP 400 and application-denied HTTP 403
CONNECT requests without disrupting an active WebSocket.
This Server milestone is complemented by the now-verified unified
HTTP3 Client WebSocket implementation described above, including
current peer SETTINGS admission and QUIC request-stream credit.

The expanded real QUIC/TLS positive and 400/403 test source
b43532e92917d5850b6abc78c16485e3e16acc37 PASSED both FULL
Unblock::HTTP integration workflows:
- Published Net::QUIC 0.05: 39513252507 PASS
- Optional QUIC MAX_DATA feature: 39513252547 PASS
Both passed 27 distribution test files / 1,102 checks including t/35
and t/34, all existing live TCP/QUIC and resource guards and preexisting
smoke steps. No speedup is claimed, and no lower library is modified.
H3 Client WebSocket remains disabled pending its own implementation.
No broad profiling or release preparation.

## HTTP2 Client WebSocket Extended CONNECT (2026-10-20)

Unified Client now supports opt-in `http2 => { websocket => 1 }`.
Use `connect_websocket(url => 'wss://...', http_version => '2')`,
or omit http_version when HTTP2 is the only enabled WebSocket policy.
HTTP1 remains the default when both H1 and H2 support WebSockets.
The internal RFC8441 handshake helper creates a real H2 CONNECT request.
The Client waits for initial peer SETTINGS and does not submit CONNECT
unless ENABLE_CONNECT_PROTOCOL = 1. An H2 connection pending peer SETTINGS
does not cause repeated TCP connection establishment. A peer that rejects
Extended CONNECT fails the queued operation explicitly and cannot cause
a silent HTTP1 fallback or replay after dispatch.

On successful H2 HTTP 200 response validation, the original H2 Transaction
and a real Unblock::WebSocket::Client are passed to on_open($ws, $tx).
The operation's websocket() accessor exposes that engine. Incoming H2
on_data is forwarded to ws->input, and outgoing WebSocket frame buffers
flow through the same deferred H2 DATA bridge as server sessions.
on_drain wakes the bridge after H2 output congestion. The stream remains
active through WebSocket Close and END_STREAM, so on_finish refers to the
final H2 transaction outcome, not to initial handshake success.

The H2 TCP/TLS socket remains pooled and multiplexed throughout. Ordinary
HTTP2 and multiple WebSockets can share the same engine; cancellation
resets only its own stream and shutdown lets active streams drain.
HTTP1 upgrades still transfer the whole socket out of the pool.
HTTP3 WebSocket remains disabled.

t/33-client-websocket-h2.t tests the actual H2 and WebSocket engines,
SETTINGS gating, two simultaneous WebSocket streams, normal HTTP traffic,
cancellation isolation, close lifecycle and unsupported peer handling.
The two full CI integration workflows for source
bebb92c02d817c3b89bef956e03e846235040b40 PASSED:
published Net::QUIC 0.05 run 39510286760 and optional QUIC-feature
run 39510286933. Both ran 25 distribution test files and 1,054
checks, plus all existing live TCP/QUIC, resource guard and
benchmark smoke stages. No performance gain claimed. No lower
library source or ABI changes. No release work.

## HTTP2 Server WebSocket Extended CONNECT (2026-10-20)

The shared Server now supports opt-in `http2 => { websocket => 1 }`
with the same `on_websocket($tx, $request)` callback used for HTTP1.
H2 requires a `defer($callback)` option on the Server definition,
which the framework MUST schedule on a later event-loop turn. It
advertises ENABLE_CONNECT_PROTOCOL only when configured to allow
WebSocket; conflicting manual SETTINGS are rejected. Without
WebSocket permission, CONNECT advertising remains off.

When the real HTTP2 Server receives Extended CONNECT with
`:protocol = websocket`, on_websocket selects handshake options,
callbacks and optional on_open, or returns undef for HTTP 403.
The read-only Unblock::WebSocket handshake helper validates RFC8441
and constructs HTTP 200 (invalid handshakes receive HTTP 400).
The same real HTTP2 transaction is switched to streaming receive
using `on_data`; it sends a streaming response (not a 101 switch).
The TCP/TLS connection and all ordinary HTTP2 transactions continue
unchanged. No framework-level WebSocket socket takeover is involved.

Internal _WebSocketH2Body accepts complete WebSocket frame buffers,
queues them, and sends each to the original H2 Transaction via
`write` on the deferred event-loop turn. It obeys H2 on_drain
congestion and uses `end` only after queued frames are accepted.
A WebSocket abort resets only its own H2 transaction. The bridge
keeps weak Transaction/WebSocket references so normal terminal
cleanup releases all per-stream state. The ordinary HTTP paths
remain unchanged when H2 WebSocket is disabled.

t/31-server-websocket-h2.t runs actual HTTP2/WebSocket engines and
checks SETTINGS, validation, on_open, bidirectional frames,
concurrent ordinary HTTP, denial, invalid requests, Close exchange,
END_STREAM, and connection reuse after WebSocket Close.
t/32-h2-websocket-bridge.t separately checks whole-buffer transfer,
deferred scheduling, congestion/resume, graceful end ordering and
stream-local cancellation. These tests are in the upper feature
branch; individual protocol engines, Unblock::WebSocket, Net::QUIC
and Uniform::HTTP remain read-only, with no ABI change.

This Server H2 milestone is now FULL CI VERIFIED at production/test
source 9e7a122c4d9ae6105ed3997540469a1d67a35e16:
- Published Net::QUIC 0.05 full integration run 39398673128: PASS
- Optional separate QUIC MAX_DATA full integration run 39398673160: PASS
Both ran 24 distribution files / 1,010 checks, plus all existing
live TCP/QUIC, resource guards and diagnostic smoke steps. No
quantified performance change is claimed. Both workflows used the
pinned read-only protocol engines and Unblock::WebSocket 0.02.
Unified Client H2 WebSocket and HTTP3 WebSocket remain disabled.
Do not restart release work or the prior performance sweep.

## HTTP1 Client WebSocket and native successor handoff (2026-10-19)

HTTP/1.1 WebSocket support now includes the opt-in unified Client.
`Client->connect_websocket(url => 'ws://...'| 'wss://...', ...)`
returns the existing request operation immediately. It uses an HTTP1
handshake request from Unblock::WebSocket::Handshake, negotiates strictly
HTTP/1.1 through the existing connect_stream factory, and validates the
101 response before switching input ownership. The transport supplies
`unblock_upgrade($ws)` and continues using its existing ordered queue.
On success the HTTP1 engine leaves the per-origin connection pool
without being closed or passed to release_connection. `on_open($ws, $tx)`
receives the actual WebSocket Client and HTTP1 transaction; the
operation's `websocket()` accessor then provides the same WebSocket
engine. `on_finish($tx)` reports the HTTP upgrade transaction only,
not eventual WebSocket Close. A successful WebSocket is unaffected by
the HTTP Client's later shutdown. Protocol flags for H2/H3 WebSockets
remain unavailable.

A terminal-callback lifetime bug was found and corrected during
integration: removing the upgraded connection from the pool also
released its weak callback bookkeeping too early. A temporary
upgrade_retirement reference on the operation lasts exactly through
HTTP1 on_finish and is deleted before the application's on_finish
callback. t/30-client-websocket.t tests real in-memory H1/WebSocket
traffic, pool detach, subsequent normal HTTP, shutdown, disabled
policy and rejected handshake. Implementation/test source is
65c88e0fa57ad11c753b03ba1745ac832f46de16. Both full CI
workflows PASSED: primary published Net::QUIC 0.05 run 39365198070
and optional QUIC-feature run 39365198109. Both passed 22 files /
960 distribution checks plus existing live TCP/QUIC, sustained
resource tests and pre-existing benchmark smokes. No claimed
throughput improvement comes from those shared runners.

Native borrowed input is covered separately by
t/29-server-websocket-native.t: it drives the actual native HTTP1
consumer, checks INPUT_SWITCH's consumed prefix and forwards only
the unconsumed suffix to the established WebSocket. It also covers
fragmented HTTP headers. The optional LinuxEvent stream adapter
switches data, EOF, error and output-resume handling to WebSocket,
and examples/linux-event-websocket-server.pl shows the complete
HTTP/1.1 server use case. That adapter uses public Perl input; an
XS/native framework must still retain and hand over its borrowed
unconsumed native buffer itself. This earlier source
3505abf5c01993f02ace9ef31b76f2d6069d076f passed full
published-Net::QUIC CI 39364338085 and optional QUIC-feature CI
39364338022. No NativeABI version change or lower-engine edits.

## HTTP1 Server WebSocket transition slice (2026-10-19)

On the upper feature branch only, opt-in `http1 => { websocket => 1 }`
plus `on_websocket` uses the read-only Unblock::WebSocket handshake and
framing engine. The HTTP1 Server remains the HTTP parser and original
transaction owner. During the completed request callback, the WebSocket
handshake is validated, negotiated connection options are applied, and the
HTTP1 engine sends the 101 response. Its existing `on_switch` fires only
after the transport has accepted the outgoing 101 bytes. That callback
calls the framework's additional `unblock_upgrade($websocket)` hook and
moves `take_remainder()` to the same established WebSocket engine once.
A normal HTTP request still reaches ordinary `on_request` unchanged.

The WebSocket callback returns constructor options including its message
handlers and optional `on_open`, or undef to reject with 403. Malformed
WebSocket handshakes receive 400 without switching. The optional WebSocket
dependency loads only on a WebSocket attempt; the CI workflows pin the
existing read-only WebSocket main revision for new `t/28-server-websocket.t`.
No engine or Net::QUIC source changes. H2/H3 Extended CONNECT and unified
Client WebSockets remain unsupported and their policy gates stay closed.
No new broad performance campaigns or release actions.

The full primary CI (39343711783) and optional QUIC-feature CI
(39343711492) both PASS at production source d8c8c421974cf43b72d45c2358d38503b2a562de.
The distribution suite passes 20 files / 890 checks including the 34
new t/28 WebSocket checks; existing live TCP/QUIC, memory and benchmark
smoke steps also pass.

The subsequent Client and native input work above extends this
original server-only milestone. Native borrowed-input providers own
their unconsumed input window when HTTP1 returns INPUT_SWITCH; they
must transfer exactly that suffix to the new WebSocket consumer.
HTTP2 and HTTP3 Extended CONNECT WebSocket streaming are still
unimplemented. Keep existing feature branches.

## Verified graceful Client shutdown (2026-10-19)

The upper Client now provides shutdown() and is_shutdown().
Calling shutdown() prevents new request admission, clears Alt-Svc,
cancels queued and connecting requests and their timer/factory
callbacks, and immediately releases idle connections. In-flight
HTTP/1.1, HTTP/2 and HTTP/3 transactions are NOT cancelled:
the engine still finishes them normally, and the Client releases
a retired transport after its final active stream completes.
This is an explicit nonblocking drain, not a blocking wait.
shutdown() is idempotent. Applications needing immediate close
may explicitly cancel their retained active operation handles.
Transport release callbacks see reason shutdown.

Test t/27-client-shutdown.t covers cancellation, reentrant
on_finish, late readiness, H2 multiplexed draining, H3 draining
and idle timer cleanup. Full Linux::Event integration CI with
published Net::QUIC 0.05 passed at run 39310090480, and the
separate optional QUIC feature integration passed 39310090357.
No lower engine code or runtime ABI changed.

# Implementation status and continuation plan

Updated: 2026-10-17
Branch: feature/high-level-client-server
Status: Server, Client pool, Alt-Svc and optional deadlines CI verified. Not a release candidate.

## Implemented

Server is a reusable definition with shared protocol policy. attach_stream
returns the actual H1/H2 Server engine; attach_quic returns the actual started
H3 Server engine. Frameworks retain those engines and own sockets and timers.
The optional LinuxEvent adapter feeds the selected engine directly. QUIC
server managers attach each ready connection through the shared definition.

Only explicitly enabled protocols can attach. Settings containers are copied.
No transaction wrapper, subclass, reblessing, or method injection is used.
The whole-buffer output contract is unchanged.

Ordinary Server callbacks now have the intended application timing:

- on_headers($tx, $request): incoming headers, before body delivery.
- on_request($tx, $request): successful complete body and trailers.
- on_error($tx, $error, optional code): underlying engine failure.

Each protocol defaults to buffered reception capped at 1 MiB. Change the
positive max_buffered_body_bytes option in that protocol's tuning hash.
Register tx->on_data during on_headers to select streaming without a full
body accumulator. on_request still runs once on successful streamed reception.
Register tx->on_finish before terminal state to observe complete/error/cancelled.
A completed request can still have an unfinished response.

The engine owns reception and installs the body before freezing the same
Uniform message. The upper layer stores no body chunks and maps callbacks
once when constructing the shared definition. There is no per-chunk forwarding
closure in the unified layer.

Old upper-layer on_body and on_request_end constructor options are removed,
without aliases. They remain low-level interfaces in the individual engines.

## Coordinated dependency branches

The user explicitly authorized changes to HTTP1, HTTP2, HTTP3 and this repo.
All dependency work is on feature/unified-receive-lifecycle. Main branches
remain untouched. See ENGINE-CONTRACTS.md and each engine's Handoff.md.

H1/H2 add bounded buffering while retaining their default stream mode. H3
retains its buffered default and reuses its existing accumulator/Reader.
All add on_data and on_finish. H3 body-limit failure now resets its stream
instead of failing the connection. Native ABI layouts remain unchanged.

Released H1/H2 0.11 and H3 0.12 lack these methods. Attachment rejects old
engines explicitly. Feature versions have not been bumped for release.
Do not install this upper branch with released engines and expect it to work.

## Validation

Local Perl 5.38.2, 2026-10-17:

- HTTP1: 36 files, 320 top-level tests/subtests pass.
- HTTP2: 30 files, 525 top-level tests/subtests pass.
- Upper layer: 6 files, 182 top-level tests/subtests pass. Five files use engine
  doubles; t/14-server-receive.t runs real H1/H2 attached engines.

The new engine tests cover buffered/streamed bodies, limits, empty bodies,
cancellation, object identity, callback ordering and native/portable parity.
H1 also covers chunked trailers, truncation, and throwing completion/error
callbacks. H2 covers simultaneous streams and overflow isolation.

H1 uses Uniform::HTTP 0.06 from the read-only dependency checkout. H2 was built
against the actual system nghttp2 1.59.0 shared library and matching upstream
headers, using a scratch build configuration because Alien::nghttp2 is absent.
The repository Makefile.PL is unchanged.

H3 native/ownership/terminal tests pass locally: 3 files, 92 top-level checks.
The local native build uses upstream nghttp3 1.18.90 development and cannot
run live QUIC because Net::QUIC is not installed locally.

Full GitHub CI now passes for all three engines, including live H3 tests:

- HTTP1 test 39058702399 and framework examples 39058702329.
- HTTP2 test 39058704851 and interoperability 39058704842.
- HTTP3 test 39059118633 (26 files / 942 top-level tests/subtests) on
  Perl 5.20, 5.28, 5.36, 5.44, with distribution/POD/installed ABI checks.
  Interoperability 39059118732 also passed.

CI uses the released dependency configuration. The upper workflow pins the
published engine source revisions listed in Handoff.md. Initial integration
39058779436 passed; strengthened final integration 39059172525 also passed
(182 distribution checks and 15 live TCP/QUIC checks).
It checks H1/H2 TCP and an H3 POST over QUIC/TLS, including complete body,
transaction/message identity, frozen message and lifecycle order.

## Next steps

1. Ordinary Server receive/lifecycle milestone is complete and CI verified.
2. Keep all four feature branches; no merge, release or version bump is authorized.
3. Publication and CI fixes are already authorized. Do not ask for the same
   confirmation again. Main branches and read-only dependencies stay unchanged.
4. Continue the original design after verifying this ordinary Server milestone.
   No benchmark improvement is claimed.

## Shared Client implementation slice (2026-10-17)

The first Client slice has been committed to the upper feature branch.
Client is now a reusable policy and per-origin connection pool, not the
older one-connection forwarding wrapper. Factories are callback-based and
framework-neutral: connect_stream(origin, alpn_choices, ready),
connect_quic(origin, ready), and defer(callback). The ready callback returns
the real HTTP1/2/3 engine. Frameworks retain the engine and socket; the pool
does not forward input bytes.

request(method => ..., url => ...) returns _ClientOperation immediately,
including while connecting. operation->transaction is the real engine
Transaction once dispatched. A strict http_version (1.1/2/3) must match.
Cold requests prefer existing H2/H1 negotiations, not unvalidated H3
discovery. HTTP3-only and explicit HTTP3 requests use connect_quic. The
pool enforces positive limits: pending queue 128, connections/origin 4,
multiplexed requests/connection 32 by default. Idle H1 is reusable,
H2/H3 capacity is shared, and incompatible idle engines can be evicted.
The defer factory prevents reentering H1 from its finish callback.

The engine performs the only buffered reception (default 1 MiB).
Without on_data, on_response runs after successful completed response;
with on_data, on_response runs at headers and on_end at body completion.
on_finish runs after transaction terminal state. A pre-dispatch failure or
cancellation has no engine tx, so callbacks receive the request operation.
No automatic retries are attempted. HTTP 404/500 are responses, not errors.

New isolated contract file t/15-client-pool.t covers factories, streaming,
terminal callbacks, queue cap, multiplexing, H1 deferred reuse, strict
protocols, and error/cancellation. The previous t/10 selector test now
tests _Session as a low-level helper. The old QUIC client manager now
returns the actual HTTP3 Client engine rather than constructing the
obsolete one-connection unified Client. The live TCP test is converted
to the new Client factory API.

Validation checkpoint: CI run 39061708958 passed the distribution suite
(7 files / 245 checks); its live TCP test still used the old Client API.
The replacement live TCP test exposed an H2 Client constructor rejection of
the Server-only enable_connect_protocol option, also applicable to the H3
enable_extended_connect option. Client now removes these before constructing
H2/H3 engines. Verified Client pool CI: run 39062331531 passed all 256 distribution
checks and 15 live TCP/QUIC checks at commit df6fa8ea. No local shell git checkout is possible in this session because
github.com DNS resolution fails; edits/publication used the GitHub connector.

## Alt-Svc discovery and safe connection fallback (2026-10-17)

Implemented on the upper feature branch in this follow-up:

- A bounded in-memory Alt-Svc cache. Accepts the same-host h3=":PORT"
  syntax on authenticated HTTPS responses only, with one origin-scoped
  entry, a maximum lifetime of 24 hours, Age adjustment, clear handling,
  stale entry removal and bounded cache size (256 origins).
- Framework connect_stream must return verified_origin => 1 after TLS
  certificate/hostname validation against the request origin before
  Alt-Svc headers are trusted. Merely setting a URL scheme to https
  does not establish TLS authentication.
- Subsequent requests with no strict http_version may choose H3. The
  connect_quic factory gets the original origin plus alternative_host
  and alternative_port, then must return verified_origin => 1 to confirm
  the alternative is authoritative for the ORIGINAL origin. The request's
  scheme, authority and target are unchanged.
- Cross-host alternative services are deliberately unsupported for now.
  No silent TLS verification bypass, DNS discovery, 0-RTT or connection race.
- A failed advertised QUIC connection may fall back to existing TCP
  BEFORE dispatch, because no HTTP request has been transmitted. This
  does not invoke application on_error, does not retry a strict version
  and invalidates the failed advertisement. After engine request()
  dispatch, there is never an automatic replay, even for GET; the
  application sees the original error.
- Unit tests in t/16-alt-svc.t and integration tests in
  t/17-alt-svc-client.t cover parser/expiry/authentication, strict
  selection, factory failure and prevention of unsafe request replay.

Alt-Svc source/test commit 557cb101e5cd2342368d43f18afc400e69546634
passed integration CI run 39062960467: 9 distribution test files, 316 checks,
and 2 live H1/H2/H3 tests, 15 checks. Source and POD were reviewed again
after that run. Server and all three engine branch sources remain unchanged.

## Optional request deadlines and factory cancellation (2026-10-17)

A Client now accepts optional schedule_timer(seconds, callback) returning a
timer cancellation coderef. Requests may specify timeout as a positive number
of seconds covering time spent queued, connecting and active. No native timer
or event-loop dependency is introduced. The timer is cancelled when the
operation reaches a terminal state.

A connecting operation can abandon its in-flight factory without keeping
the per-origin connection slot occupied. If the factory returned a cancellation
coderef it is called; any late ready() is ignored. The framework must dispose
of a transport it created after cancellation. The operation retains native
engine identity and no unprocessed request is automatically replayed.

Pre-dispatch expiry emits on_error(operation, reason) before
on_finish(operation). After dispatch the real engine Transaction is cancelled
and the Client emits on_error(tx, timeout reason) before on_finish(tx). The
operation records an error, while the underlying transaction reflects the
actual cancellation, not a fabricated protocol failure. Explicit user
cancellation remains separate and does not invoke on_error.

t/18-client-timeouts.t supplies deterministic framework-timer and fake
transport tests, including late factory readiness, queue release and
callback ordering. The live HTTP1/H2 tests also use actual framework timers,
confirming successful operation cleanup.

Run 39064100968 passed at commit f8be6219a7db440b8fe38acbcf5741066f7c488d:
10 distribution test files / 371 checks and two live TCP/QUIC test files /
17 checks. After this run, the upper Client and t/15 gained an additional
terminal callback dispatch guard and regression: a request enqueued inside
H1 on_finish must wait for the next framework deferred turn instead of
reentering the engine. Run 39064232198 passed with that guard and test:
10 distribution files / 375 top-level checks plus 2 live files /
17 checks. This Client deadline and factory lifecycle slice is verified.

## Bounded pool admission and concurrent transport test (2026-10-17)

The shared Client now distinguishes H2 connections temporarily limited by
peer SETTINGS_MAX_CONCURRENT_STREAMS from permanently draining connections.
It uses the real H2 Client->can_open_transaction and schedules a new pump
after the engine's on_settings control callback. Peer zero capacity waits
without evicting a healthy idle engine; a GOAWAY/draining engine is not
reused after its active streams finish. H3 GOAWAY similarly retires idle
connections. Synchronous connect factories are budgeted to at most the
per-origin connection limit per scheduler pump; this prevents unbounded
recursion/churn when a peer admits no requests.

The HTTP3 engine on its feature branch now offers a narrow
on_request_available($h3_client) constructor callback, emitted once after
request() failed to open a QUIC bidi stream and Net::QUIC subsequently
reported bidi stream availability. The callback is advisory, not stream
credit reservation. The upper Client keeps the unsent operation in its
bounded queue, prevents reentry on that H3 connection, and schedules a
deferred admission attempt when the callback runs. Active transactions
are never replayed; queued cancellation and timeout remain effective.

Verified: H3 feature CI 39069441321 (full Perl matrix) and interoperability
39069441276 passed with this contract. The upper CI now pins tested H3
commit 9bfd9314fb66f19860a96a20ec6eb082e86e3ce5 and passed run
39069934513: 11 distribution files / 444 checks and 2 real-socket
integration files / 19 checks. The live QUIC/TLS path now routes an
authenticated H3 POST through the shared Client connection factory,
not just the low-level QUIC manager. Peer-credit exhaustion and wakeup
remain isolated deterministic engine and unified unit regressions;
the live test validates normal available-credit HTTP3 admission.

New t/19-client-admission.t covers peer zero/increased SETTINGS, active
H2 GOAWAY, sync non-admitting factory, H3 unavailable stream credit,
H3 GOAWAY, and independent multi-origin queue limits. First CI for
t/19 passed 419 distribution checks and the previous 17 live checks.

The expanded live xt/linux-event-tcp.t now issues twelve H1 and twelve H2
requests. Its first run exposed that the earlier test-only connect_stream
factory reused one LinuxEvent stream for multiple engines. The test factory
was corrected to establish a distinct framework-owned socket on each new
connection, matching the documented transport contract.

Verified run 39065677169 on commit e13e5004e60e3df28875d5164b61e3e74459bb9c:
11 distribution files / 419 checks, and 2 live TCP/QUIC files / 19 checks
passed. All 24 H1/H2 requests completed, each operation timer was cancelled,
and the earlier H3 live socket regression remained green. The final queued
state correction was included in that run.

The verified HTTP3 feature branch now supplies the one-shot bidi stream
availability callback, and the unified Client queues unsent requests
until notified. A non-consuming stream-credit *quantity* is still not
available; the notification may race other QUIC users, so another failed
admission simply re-arms the signal. The pool does not infer or cache
a fabricated stream limit.

## Opt-in idle connection expiry (2026-10-17)

The shared Client accepts idle_timeout as a positive duration in seconds,
with no default expiration. It requires the existing framework
schedule_timer(seconds, callback) contract. A connection with zero active
transactions and no queued demand for its origin gets one cancellable
one-shot timer. Reusing it cancels the pending timer; a stale timer cannot
close that active engine. Completion begins a fresh idle lifetime. Queued
H2 SETTINGS-limited and H3 credit-limited operations hold their connection
in an active pool without idle eviction.

release_connection(host, engine, protocol, reason) is an optional framework
cleanup hook called once per retired connection. The Client releases
idle-expired, non-reusable and capacity-evicted engines; when the hook is
absent, it invokes engine close when available, otherwise the QUIC
connection close. Empty idle origin pools are removed. Frameworks own
the actual socket cleanup and should use the hook when required.

t/20-client-idle.t covers reuse and timer invalidation, H2 multiplex
lifetimes, peer-zero-credit demand, H3 resource cleanup, retirement at a
strict connection cap, empty origin deletion and validation. The live
QUIC suite issues eight independent POST transactions on one real H3
connection and verifies each request and response by identity without
assuming stream completion order.

Source and expanded live regression CI run 39073163329 PASS at
a0b8a0164e741e55010c954b1f35f0e7ee350e98:
12 distribution files / 487 checks and 2 live TCP/QUIC files /
78 checks. No performance claims or code changes to the three engines.

## Explicit network-change invalidation and pool stats (2026-10-17)

The upper Client adds explicit network_changed(), called by the framework
when network topology or identity changes. It clears cached Alt-Svc
entries, abandons outstanding factory attempts with their optional
cancellation hooks, keeps queued operations and their timeouts intact,
and schedules fresh establishment on the next framework turn.
Old factory readiness can never attach afterward. Idle stale engines
are immediately released through the one-shot framework cleanup hook.
Active transactions remain on their original engines until they
terminate, at which time the old connection is retired; no user
request is automatically replayed after dispatch. A stale connection's
late response cannot repopulate Alt-Svc for the new network.

pool_stats() provides a copied snapshot of aggregate and per-origin
counts: active, idle, retiring, connecting, pending, credit-blocked,
and connection totals. It returns no live engines/sockets/QUIC instances
and does not mutate the pool or schedule any work. This is
observability, not a new cross-protocol buffering layer.

t/21-client-network.t covers factory cancellation, repeated changes,
stale ready suppression, active HTTP2 retention, stale Alt-Svc,
idle timer cleanup, H3 credit-blocked migration, and read-only
snapshot contents.

Verified CI 39073823298 on source/test commit
9727113f5f85382f69026af74b67e7b5ac643aaf:
13 distribution test files / 540 checks PASS; two live H1/H2/H3
TCP/QUIC files / 78 checks PASS. No engine or transport dependency
source was edited; subsequent commits change only documentation.

## Large-body streaming, backpressure and first benchmark (2026-10-17)

New xt/linux-event-streaming.t tests three concurrent uploads and
downloads of 1,179,648 bytes under each of H1 and H2. It registers
server per-transaction on_data at headers and uses the public Client
on_data/on_end streaming callbacks for the response. Default buffered
receive limits are 1 MiB, so the oversized bodies must remain streamed.
The live test checks byte counts, incremental SHA-256, callback ordering,
transaction identity, exact one-time completion and timer cleanup.

The live H3/QUIC socket suite also mixes one large streamed POST/response
with seven ordinary buffered requests on the same connection, checking
isolation, integrity and independent callback lifetimes.

Controlled framework output-pressure injection returns false AFTER fully
accepting bytes and resumes the actual H1/H2 engine on a future framework
timer. This validates the accepted-then-blocked contract, not sustained
slow-receiver socket throughput or queue memory high-water.

CI 39075534537 PASSED with 13 distribution files / 540 checks
and 3 live TCP/QUIC files / 145 checks. No engine source changes.

bench/client-vs-direct.pl uses real LinuxEvent sockets and compares
the direct H1/H2 Client with Unblock::HTTP::Client using the same Server.
Repeated 1000-request/100-warmup, 3-round alternate-order smoke in CI
39076051442 showed median unified/direct elapsed-time ratios of 1.340
for H1 and 1.372 for H2 on that runner. This is a low-concurrency
application API cost, not a claim about concurrent/production traffic.

Removed an unnecessary framework defer after healthy transactions
with no queued work, idle timer or retiring connection. Additional
regression assertions preserve H1 on_finish reentrancy, idle expiry,
and asynchronous queue progress. CI 39076255077 PASSED with
13 distribution files / 543 checks and 3 live files / 145 checks.
Its repeated benchmark ratios were 1.296 H1 and 1.337 H2. These
separate CI machines do not prove an exact speedup; meaningful
remaining overhead must be profiled before more optimization.

See docs/BENCHMARKING.md for comparable workload scope and
reproducibility limitations. Outstanding: sustained slow receivers,
measured buffer high-water and partial writes, stream-body producer
backpressure, H3 direct-engine baseline, concurrency fairness and
runtime/CPU/allocation profiling.

## Synchronous request setup profiling and safe direct dispatch (2026-10-17)

The live TCP direct-versus-shared Client benchmark now times the request()
call separately from end-to-end request completion. An isolated
bench/request-setup.pl microbenchmark compares URI validation and Uniform
object construction without network, parser or scheduling overhead.
The instrumented first baseline reported ~45 us direct request() call
versus ~93 us unified H1 / ~100 us unified H2. The isolated URI and
Uniform setup cases measured ~9.9 us and ~10.4 us respectively on that
CI runner. These are not rigorously additive measurements.

The Client request hot path now directly calls the real engine via
_dispatch when exactly one reusable pooled connection already exists,
the native engine admits a transaction, and no queue/connection/maintenance
work, callback reentrancy or idle timer can interfere. All other requests
still follow the bounded scheduler; strict policy, cancellation,
network-change retirement, H1 reentrancy and H3 stream-credit waiting
remain unchanged. No per-byte forwarding or new request wrapper was added.

t/15-client-pool.t covers bypass of redundant pool scans for eligible
H2 multiplexed requests, continued bounded queuing at capacity, deferred
capacity wakeup and exclusion of idle-managed connections. CI
39079251789 passed 13 distribution files / 552 checks and three live
TCP/QUIC files / 145 checks. The same CI run completed the
three-round real-socket benchmark and the URI/Uniform microbenchmark.

The timed H1 unified request() median changed from ~93 to ~88 us on
nearby separate CI runners; H2 from ~100 to ~95 us. There is still
substantial observed overhead, and CI machine variation prevents
a precise speedup claim. Further profiling must distinguish
object allocation and URL validation from pool management and engine
callback setup before broader optimizations are considered.
See docs/BENCHMARKING.md for raw results and limitations.

## Actual TCP slow-reader and socket watermark test (2026-10-17)

xt/linux-event-slow-reader.t pauses reads on the real LinuxEvent client
socket for 0.12 seconds while the H1 or H2 server streams a six-MiB
response. The framework connection sets a small receive buffer;
the server uses 16 KiB high / 4 KiB low output watermarks.
The test verifies zero application reads before resumption, exact
response bytes and SHA-256, one response/end/finish callback sequence,
and native-transaction completion. This is an actual socket pause,
not the synthetic accepted-but-blocked output injection in
xt/linux-event-streaming.t.

Verified upper GitHub Actions run 39083903027 on source commit
5eaca204f773331eec98870bdfc5e64e948365e1:
13 distribution files / 552 checks and four real TCP/QUIC files /
168 checks, all PASS. The H1 transport reported one real
unblock_send=false and one on_drain. H2 reported zero transport
pressure/drain callbacks on that runner, despite successfully
completing after its input pause; its stream/connection flow control
can prevent TCP send-queue pressure before the framework watermark.

This does not establish a bounded pending-output high-water mark:
LinuxEvent high_watermark is advisory; max_pending_bytes is a
different hard-limit option. Further work should measure real output
queue sizes and exercise producer resume callbacks under sustained
slow peers, including HTTP/3. No engine or core API change was needed.

## Live cooperative producer backpressure with sampled hard-capped socket queue (2026-10-17)

xt/linux-event-producer-backpressure.t exercises native H1 and H2
server Transaction->respond(stream_body => 1, on_drain => ...),
write(8KiB) and end(). The LinuxEvent receiving socket pauses reads
for 400 milliseconds, while a producer sends 8 MiB of response data,
never more than eight chunks in an event-loop turn. A write returning
false is *accepted* but pauses subsequent production. The application
resumes from on_drain without resending those accepted bytes, and
defers end() when the final write returned false.

The actual LinuxEvent server socket is configured with high and low
watermarks (32KiB / 8KiB), a max_pending_bytes limit of 512KiB,
and SO_SNDBUF 32KiB. The fixture samples the official pending_bytes
accessor following writes and drain notifications, and verifies
that the observed socket queue remains within the configured limit.
The sampling does NOT count native HTTP2 provider buffers, kernel
SO_SNDBUF content, or all allocations; it also does not force the
hard limit to reject a write. Consequently this is not yet a proof
of bounded worst-case total memory or oversized-write behavior.

CI 39085138364 PASS at a0fd7adb52d6126d44e73800dde7de4f4ca268e2:
13 distribution files / 552 checks and five TCP/QUIC live files /
203 checks. The test verifies producer pause, resumptions, exactly
one end, digest and byte equality, client/server completion, callback
order, and per-turn emission budget. On that CI runner, H1 had
51 backpressure events / 51 producer resumptions, peak sampled TCP
pending queue 32,856 bytes; H2 had 95/95 with peak 32,821 bytes.
H2 had 64 transport drain callbacks because H2 flow control can
block and resume the stream independently of the TCP queue.

The change is exclusively in upper feature tests and CI; production
Client, Server and H1/H2/H3 engine source is unchanged. Follow-up
testing should cover hard-cap rejection, partial transport writes,
multiple slow peers with fairness, total engine memory high-water,
and H3 stream producer backpressure. See docs/BENCHMARKING.md.

## Fatal socket output cap and attached H1 completion (2026-10-17)

The real LinuxEvent max_pending_bytes is a fatal output hard cap, not
a cooperative high-water mark. When a write would exceed the cap,
LinuxEvent reports structured Error(type=output_limit,
operation=write, pending_bytes, limit) and closes the Stream.
The bytes from that rejected write were not fully accepted. An
attached transport adapter must fail the HTTP connection instead
of interpreting the failed write as "accepted, please resume later."
The upper LinuxEvent adapter already throws when its underlying
write closed the stream; the native engines abort appropriately.

New xt/linux-event-hard-output-limit.t forces a 2 MiB response
through an attached HTTP1/2 Server with a 4096-byte pending-output
cap. It verifies both fatal errors, immediate socket teardown,
absence of ordinary producer on_drain, no complete response at
the client and exactly-once server terminal notification.

The test exposed an H1-specific lifecycle bug: while parsing pipelined
input, the H1 engine completed buffered server transactions before
the outgoing bytes had been accepted by the host. This could report
on_finish(complete) despite a fatal synchronous output rejection.
The coordinated H1 feature branch now holds pending terminal
notifications until the batched output is accepted, or fails those
transactions on host rejection. It preserves coalesced pipeline
output, normal graceful close and manual mode. A false return from
an alive host still means whole-buffer acceptance and congestion,
NOT a hard rejection. Neither normal terminal completion nor
host acceptance guarantees remote peer consumption.

Verified H1 feature source 783e2a951dafac2756ba2c3cf34ea35fc043de6f:
full Linux/macOS/Windows CI 39087355734 PASS (37 H1 files /
324 Linux checks) and framework examples 39087355806 PASS.
The upper integration workflow pins this source; CI 39087487036
PASS with 13 distribution files / 552 checks and six live
TCP/QUIC files / 226 checks.

New xt/linux-event-pool-fairness.t exercises two simultaneously
paused slow readers plus one fast connection on the same shared
origin, with three framework-owned TCP sockets. Every H1/H2 producer
uses native Transaction->respond(stream_body => 1, on_drain => ...)
and limits itself to four 4KiB chunks per deferred loop turn.
Each response is 2 MiB. CI 39087771958 PASS on upper test source
99d19a5cd77b37ab57768af61955ddd4807cab5e:
13 distribution files / 552 checks and seven live TCP/QUIC files /
289 checks. The fast response finished while both other clients were
still paused for 0.8s. All six per-protocol slow/fast response copies
have correct SHA-256 digests, callback order and once-only completion.
Peak sampled socket queue per protocol was 32,832 B for H1 and
32,821 B for H2, below the configured 512 KiB cap.

This is bounded concurrent scheduling fairness for three sockets on
one localhost endpoint, NOT a measured fairness guarantee under
hundreds of clients or across H3 streams/origins. The engine/provider
and kernel pending bytes still require separate monitoring.

## HTTP/3 native producer backpressure over live QUIC/TLS (2026-10-17)

xt/linux-event-quic-producer.t extends the live H3 loopback fixture:
seven small buffered responses and one 2 MiB incremental response
run concurrently on a SINGLE authenticated Net::QUIC connection.
The reusable upper Server configures http3 send_buffer_limit=8192.
Its real engine Transaction responds with stream_body => 1,
then writes 4 KiB chunks through a deferred producer (no more than
four chunks per event loop turn). A false native write() is an
accepted-body backpressure signal. Production stops until the
native on_drain callback wakes it; even the final end() waits
after a blocked last write. No body callback forwarding wrapper
is inserted into the upper Client or Server.

Initial coordinated upper CI 39088458914 PASS on source
c47bd77b574f97218984c3a7c0bb96c53741aa62:
13 distribution files / 552 checks and eight real TCP/QUIC
files / 368 checks. In the H3 producer fixture the native engine
reported 256 backpressure events, 256 resumptions, 256 drain
callbacks, and 257 producer event-loop turns; maximum produced
chunks per turn was two. The full streamed receive was hashed
byte-for-byte. Seven concurrent small HTTP3 exchanges also
completed with the expected callbacks and native identity.

Follow-up CI 39088663590 PASS: 552 distribution checks and 369
live checks, with a strengthened assertion that at least one
smaller HTTP/3 response completes before the large streamed
response. This demonstrates concurrent progress on the one
QUIC connection, not general multi-stream fairness under
arbitrarily blocked receivers.

These counters describe HTTP/3's internal retained-body buffer
relative to send_buffer_limit, NOT the UDP socket's queue size or
maximum Net::QUIC memory. HTTP3 callback streaming returns receive
credit automatically; the test does not pause receiving credit on
an individual H3 stream and therefore is not equivalent to the
H1/H2 socket-pause fixtures. Additional instrumented memory and
QUIC receive-flow-control testing remains outstanding.

## HTTP/3 pull Reader credit held across a live QUIC/TLS connection (2026-10-17)

The live xt/linux-event-quic-reader-credit.t fixture tests actual
receive-credit withholding. It pairs the reusable upper Server
with the existing low-level HTTP3 Client on a shared authenticated
QUIC connection. The client explicitly selects receive_body =>
'stream' on one request and uses Body::Reader->next_chunk() in
pull mode, WITHOUT a response on_data callback. The upper
high-level Client intentionally manages receive_body and defaults
to buffering when no on_data is supplied; this fixture does not
silently change that application-facing contract.

The Net::QUIC client advertises stream_window=32768 and
connection_window=131072. A 2 MiB streaming Server response
emits 4 KiB chunks, with cooperative native write(false) and
on_drain. The Reader is not consumed for 0.5 seconds. It retains
incoming body bytes without returning the corresponding QUIC
credit, the large response stays nonterminal, and a second short
H3 response on the same QUIC connection completes. After the
hold, a timer-driven consumer pulls up to eight Reader chunks
per turn, returning credit as each chunk is consumed. It checks
that the producer resumes, completes exactly once, and delivers
the exact full body with SHA-256 integrity.

CI 39092855745 PASS after a fixture-only QUIC helper on_ready
callback arity fix: 552 distribution checks and nine live files
/ 387 checks. The Reader held 32,739 bytes at release and its
peak sampled pending_bytes was 32,739 bytes. The producer had
257 backpressure signals, 257 resumptions, and the polling
consumer used 667 scheduled turns. Strengthened CI 39093070343 PASS with 552 distribution and
389 live checks. It additionally proves the producer had
submitted only 10 of 512 full 4KiB chunks at the credit-release
point, and peak sampled Reader pending remained 32,739 bytes,
below the configured 32KiB stream receive window. This confirms
a real receive-credit stall rather than delayed callbacks alone.

The follow-up fixture also samples the public
Net::QUIC::Connection->send_buffered_bytes() method on the
SERVER's QUIC connection, separately from the CLIENT Reader's
pending_bytes(). This counts QUIC Stream data retained
for transmission, including unacknowledged Stream data.
CI 39093371363 PASS on source bb891776d3aad4de3020c3f7e2f6ee273b11477f:
552 distribution checks and nine live files / 391 checks.
The Reader peak sampled queued body was 32,739 bytes.
The QUIC retained-send peak and hold-release sample were
both 8,192 bytes. Only 10/512 producer chunks had been
issued during the credit hold. The full body later completed.

These are two independent snapshots from opposite sides of the
connection: incoming decoded Reader-owned body and outgoing QUIC
send retention. Do NOT sum these as total HTTP3/QUIC memory.
Native nghttp3 retained/provider buffers, QUIC packet
metadata/retransmission allocations, kernel queues and RSS are
not accounted for by these counters. No engine or QUIC
dependency source changes were needed.

## Multiple H3 receive-credit holds and aggregate send fairness (2026-10-17)

xt/linux-event-quic-multi-credit.t opens one real TLS/QUIC socket
with three 1 MiB H3 streamed responses, each using a pull-mode
Body::Reader and 32768-byte individual QUIC receive window. A fourth
fast H3 response finishes while all three Readers hold credit.
The test then drains Readers strictly one at a time, asserting that
unreleased responses remain incomplete and receive no credited body.
All payload digests, lifecycle events and producer chunk counts match.

The first fixture used a connection-wide 8192-byte H3 native
send_buffer_limit. It deadlocked when three producers filled the
shared retained-body budget while their Readers withheld credit
(upper CI 39095627619). Adding the nghttp3 partial-write
block_stream/unblock_stream handshake to the HTTP3 FEATURE engine
was correct output-scheduling work but did not resolve this distinct
aggregate producer-fairness problem (upper CI 39096018997).
Increasing the global threshold to 131072 also failed in
39096310032: Reader0 consumed 90112 bytes, then stalled behind
other producers' retained native body bytes. Per-stream fair
producer scheduling with a bounded aggregate budget is still TODO.

The isolated receive-credit regression uses a 4 MiB H3
send_buffer_limit, exceeding the three 1 MiB response bodies.
It deliberately does NOT test producer write(false) or on_drain:
the existing xt/linux-event-quic-reader-credit.t does those
things with a true 8192-byte native threshold and one withheld
Reader. The new multi-reader test instead establishes stream
isolation and QUIC receive-credit behavior without confusing
them with the unresolved shared producer budget.

Source/test commit ceeca6638e6faf6f2561089fcaaf3d5ad0c626d7,
upper LinuxEvent CI 39096607845 PASS: 552 distribution tests
and ten real TCP/QUIC test files / 446 live checks. Benchmark
smoke passed but supplied no reliable speed claim.
Each uncredited Reader had 32739 queued bytes at release
(under 32768), and QUIC's sampled send-buffer retention
peaked at 3061953 bytes with the deliberately high threshold.
These measurements do not bound total process memory.

HTTP3 fix source 14eaaf2f94173650b830799a2f43fca0c77ab0a1
passed native test matrix 39095993708 and interop 39095993713;
upper CI pins that source. Only upper and HTTP3 authorized
feature branches changed. HTTP1/HTTP2, Net::QUIC, Uniform,
main, versions, tags, merges and releases remain untouched.

NEXT: native nghttp3 per-stream retained-buffer observability,
a bounded fair aggregate producer budget with regression at
8192/131072, process RSS/copy measurement, and larger-scale
direct-H3 vs unified stress benchmarking.

## H3 fair-share outgoing producer wakeup, small budget verified (2026-10-17)

New HTTP3 feature code uses internal native per-stream retained-body
byte accounting (separate from receive-side Reader pending bytes and
Net::QUIC send_buffered_bytes). Its active unfinished producer count
divides the existing send_buffer_limit into dynamic per-stream shares.
write(false) is still complete-byte acceptance, now advisory about
that stream's share rather than a shared aggregate condition that
can starve other producers. on_drain wakes a producer only once its
own retained bytes have decreased below its current share. nghttp3
QUIC-partial-output block/unblock remains as in the prior milestone.
No public NativeABI layout or framework-facing API was changed.

HTTP3 feature source 96cf41e9378333fb4f7b48d89c8311c1dcf7cee7
PASSED the full engine matrix CI 39098239956; its same production
code passed the interoperability suite 39098219785. The upper
workflow pins this exact source. All other engines stay pinned.

The original three-Reader small-budget stress case now passes:
xt/linux-event-quic-multi-credit.t tests three independently streamed
1 MiB responses (and a fourth fast response) using ONE authenticated
QUIC connection, send_buffer_limit=8192, with individual 32 KiB
receive stream windows. Hold all Readers, then release each separately
and confirm the remaining streams stay unfinished, each producer
observes true accepted-write backpressure/on_drain wakeups, final
body lengths and SHA-256 match and terminal callbacks fire once.
At the first hold one Reader may have no pending body data yet because
of nghttp3/QUIC interleaving; the regression does not confuse zero
pending with having consumed receive credit. With a separate 4 MiB
native buffer, all three Readers must have pending bytes before the
first release, validating independent flow-control observation.

VERIFIED source/test commit a545a4ddecef5501e3392dcd3f4f3a4a56223efd:
upper GitHub Actions integration 39098422769 PASS,
13 distribution test files / 552 tests, ten real TCP/QUIC files /
453 tests using the 8192 native limit, and a separate high-budget
multi-stream file / 56 tests. Benchmark smoke ran but was not
a controlled throughput claim. QUIC retained send samples at
the peaks were 8192 bytes (small native limit) and 3061953 bytes
(large native limit), respectively; these are fixture values,
not proof of a process, nghttp3, kernel or retransmission
memory cap.

The send_buffer_limit is SOFT: every application write is accepted
before the false return, and one oversized write can exceed its
fair share. Do not represent the calculation as a hard upper memory
limit. Remaining milestones: per-stream native body retention and
copy/RSS measurement, bigger concurrent stream/burst stress,
fairness of dynamic producer joins and cancellations,
and controlled direct-engine versus unified Client benchmarks.
HTTP1/HTTP2, Net::QUIC and Uniform unchanged, no main edits,
releases, merges, tags or version changes.

## Live native retained-body accounting, three buffer budgets (2026-10-17)

xt/linux-event-quic-multi-credit.t now samples internal native per-stream
outgoing retained-body byte counts while three concurrent 1 MiB H3
streamed responses are active. Every sample reconciles their sum with
the H3 native connection-wide retained-body counter. Distinct sampled
QUIC send_buffered_bytes and per-Reader pending_bytes are retained
separately. This test instrumentation does not change the public API
or imply a full-stack memory limit.

Upper feature source 556d296392745b7ab16a31b7b213bcf62638aa6b,
CI 39098755460 PASS: 552 distribution checks, 10 real TCP/QUIC
files / 455 checks at send_buffer_limit 8192, 64 checks
at 131072, and 58 checks at 4194304; benchmark smoke PASS.
No native per-stream versus aggregate accounting mismatches.
All three streamed responses complete under real small-buffer
backpressure; all separate Reader release and checksum checks
pass. The earlier 8192 deadlock and the 131072 deadlock are
no longer reproducible under this fixture.

Observed native producer-retained peaks at limits
8192, 131072, 4194304 respectively: 13618, 173406,
3047511 bytes. QUIC sampled send-retained peaks were
8192, 131072, 3061953 bytes, respectively.
Per-stream native peak measurements in the 8192 case
were 5391, 5397, 9493 bytes; the individual peaks
occurred at different times, so they cannot be summed
as a simultaneous aggregate sample. The native soft
threshold is not a hard cap: full accepted writes
can exceed active shares. Buffering at the QUIC,
TLS, kernel and allocator layers is not bounded here.

Engine source pin remains
96cf41e9378333fb4f7b48d89c8311c1dcf7cee7,
previously verified HTTP3 full CI matrix and interop.
No HTTP1/HTTP2, Net::QUIC, Uniform, main, release,
tag or version changes.

Follow-up: dynamic producer arrival/cancel/EOF stress,
native discard and ACK-accounting invariants, controlled
throughput and latency baseline, RSS/copy instrumentation,
larger stream concurrency, and direct engine vs unified
Client performance comparison. Do not claim a throughput
improvement from CI smoke timings.

## Dynamic QUIC producer join/cancel and first direct-H3 benchmark (2026-10-18)

New xt/linux-event-quic-join-cancel.t runs authenticated real
QUIC/TLS loopback over the existing optional LinuxEvent adapter:
one 1 MiB streamed response remains unread with a pull Reader,
another streamed producer is cancelled during that hold, a
512 KiB streamed response joins afterward, and a small fast
response completes independently. Repeated cancellation is
idempotent. The test checks the cancellation terminal outcome
at both endpoints, discard of the cancelled native retained
body bytes, complete response lengths/digests, per-stream
streaming retained bytes reconciling with native connection
total, accepted-byte write(false)/on_drain wakeups and
deferred producer write bursts. No transaction wrappers or
production forwarding layer were introduced.

HTTP3 engine native lifecycle test-only commit
e6c1cbb0e54b0dbe40ed6d29e5884e50983a3319
extended t/01-native to cover dynamic join/discard/EOF
active producer counts, per-stream and total retained-byte
invariants, and repeated discard. The complete HTTP3 Perl
matrix CI 39133563818 PASSED. The upper integration workflow
pins this source; engine production remains unchanged from
the previously verified fair-share implementation.

Upper CI run 39133882442 PASSED at source
9a507a5534c138e6eebe5d09ab9e6646c259ddb4:
552 distribution checks, 11 real TCP/QUIC files / 485
checks including live join/cancel, plus 64 checks at native
send_buffer_limit 131072 and 58 at 4194304. All live
payloads and native accounting reconciled. Benchmark smoke
passed at this source. Shared native thresholds remain SOFT;
the tests do not prove an upper bound on RSS or all buffers.

A separate opt-in benchmark bench/h3-client-vs-direct.pl
compares Unblock::HTTP3::Client directly against the upper
Unblock::HTTP::Client using the same Net::QUIC::Driver,
loopback UDP and reusable upper Server. It sends one
sequential tiny GET at a time, alternates run order and
excludes handshake with separate warmup. It records
completed request interval and request() inclusive time,
but does not measure native copies, allocations, RSS,
packet loss or multi-stream throughput. Do not promote
hosted-runner timings to a performance claim.

The first CI benchmark smoke 39134321636 failed only
because direct on_complete supplies the Transaction alone,
not a separate Response argument. The script was corrected
at benchmark-only source 10a6b57109f76ced416aa05b0343ef08615e9cb3.
Coordinated CI 39134487091 PASSED: 552 distribution,
11 live TCP/QUIC files / 485 checks, plus 64 at the 128 KiB
native limit and 58 at 4 MiB, and all benchmark smoke commands.
Its one 30-request H3 warmup-excluded run observed direct 574
requests/sec and 237.41 us mean request() time, versus unified
542 requests/sec and 309.59 us mean request() time.
Unified/direct whole-interval ratio was 1.061 on this shared
CI host. ONE tiny run is NOT a controlled or stable throughput,
latency or cost comparison; do not publish a speed regression
or speedup claim based on these samples. For a useful follow-up,
repeat alternating rounds and measure RSS/copies, CPU and the
response/batch shapes users actually need.

No main/merge/release/tag/version changes; HTTP1/HTTP2,
Net::QUIC and Uniform::HTTP are unchanged.

## Concurrent direct-H3 versus unified profiling (2026-10-18)

The new opt-in bench/h3-workload-profile.pl extends the earlier serial
bench/h3-client-vs-direct.pl. It runs a bounded number of outstanding
buffered GET requests over a single authenticated H3 connection, against
the same loopback Unblock::HTTP Server and Net::QUIC driver in each mode.
Response bodies, concurrency (1..16), measured/warmup requests and
alternating rounds are configurable. Warmup finishes before measurement.
The client path either calls Unblock::HTTP3::Client directly or the
pooled Unblock::HTTP::Client API with URL parsing.

It validates every response and reports measured-request wall time,
throughput, mean synchronous request() cost, p50/p95/p99
application-submission-to-on_finish latency, process CPU time and
sampled Linux VmRSS. These are NOT isolated client CPU, allocation or
copy counts, RSS high-water marks, slow-receiver performance, packet-loss
tests or a reliable speedup claim on a shared CI runner.

Initial benchmark source cbbca7182f9d6aa2721a01adf84cb765c0ea9098
and workflow 49f2968e5296d8bfdc7fed1b94cae38a8b041a98
PASSED upper CI 39136691305 with all existing 552 distribution,
485 real TCP/QUIC, extra 64/58 H3 checks. The first runner samples
were short and showed process RSS monotonically increasing across
trials because trial objects shared a Perl process; these raw RSS
numbers are NOT comparable between modes.

The profiler now forks an independent child per trial, before creating
event loops, sockets or native QUIC state. The parent collects a
tiny JSON result. The isolated source
b63f08650c75c762b01b32ff75466465b5656bd6
PASSED upper CI 39136915734, including the legacy suites and both
workload smoke settings, and reset RSS starting points across trials.
Memory still represents combined client+server process RSS sampled
every sixteen completions, not the client library alone.

High-resolution process CPU using CLOCK_PROCESS_CPUTIME_ID and proper
even-round median logic were added at
82e5bf55f88e2e7515cd6b82e42be2b24f83b7a6.
The expanded workflow at cff8be90c8f3b9183557addfea03ff516504ab43
runs 100 measured/20 warmup requests, concurrency 4, 16KiB body,
3 alternating rounds; plus 30/10 requests, concurrency 2, 256KiB
body, 3 rounds. CI 39137178777 PASSED: 552 distribution tests,
485 live TCP/QUIC checks across 11 files, and 64/58 additional H3
flow-credit checks; all benchmark smoke commands passed.

At 16KiB, 4 outstanding, the three-round medians were
283.6 req/s direct and 271.0 req/s unified (elapsed ratio 1.047).
At 256KiB, 2 outstanding, both median throughputs were
~30.1 req/s (ratio 1.000). Isolated child RSS at start/end
was stable across alternating rounds, unlike the first
non-isolated profiler; it includes both server and client.
Process CPU nearly matched wall time. None of these CI
samples isolate client-only CPU/memory, count copies,
or establish a statistically controlled regression.
Full raw results: https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39137178777 .
Usage and interpretation instructions are in docs/PERFORMANCE.md.

Remaining: CPU/allocation/copy and RSS instrumentation with
separate client and server processes, stable throughput/latency
repeats on an idle pinned host, larger stream concurrency, and
benchmark payload/control comparability before asserting a
quantitative regression or improvement. Engine sources, Net::QUIC,
Uniform, all main refs, versions, merges, releases and tags
remain unchanged in this continuation.

## Later design milestones

Cross-host Alt-Svc, DNS HTTPS discovery, explicit network-change
invalidation, safe retries after dispatch (if defensible), broader
backpressure/load testing, and pool status/observability remain pending.
Request deadlines, peer-aware H2 admission, H3 credit wakeup, and opt-in
idle expiration are implemented and CI verified.

The initial receive milestone left WebSocket enablement rejected. The
subsequent opt-in HTTP1 Server Upgrade slice described at the top now
implements a checked handshake, permission callback and host-consumer
handoff using the existing H1 engine on_switch and remainder contracts.
Unified Client WebSockets and H2/H3 Extended CONNECT remain unsupported
and their policy gates stay closed. Later work includes Client pool removal
on Upgrade, H2/H3 safe streaming transaction composition, and bounded
pause/resume. No Net::QUIC modifications are authorized.

Complete live stress tests, direct-engine benchmarks, and final application
versus adapter documentation before considering a release. The original
approved design remains in design-handoff.txt.
