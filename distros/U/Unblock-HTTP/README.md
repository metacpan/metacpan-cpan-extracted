# Unblock::HTTP

Unblock::HTTP is the framework-neutral application layer above HTTP/1,
HTTP/2, HTTP/3, and WebSocket. Protocol parsing stays in the
existing engines. WebSocket sessions use the separate Unblock::WebSocket
distribution; this top layer adds no XS.

Unblock::HTTP 0.03 provides reusable Server attachment, a shared Client
with per-origin pools and bounded queues, and opt-in WebSocket handshakes
over HTTP/1.1 Upgrade and HTTP/2/3 Extended CONNECT. Unblock::WebSocket
is an optional dependency, loaded only when WebSockets are used.
Cross-host Alt-Svc and post-dispatch request replay are intentionally not
provided; optional framework-driven request deadlines are available.
Base requirements are Unblock::HTTP1 0.13+ and Uniform::HTTP 0.06+.
HTTP/2 requires optional Unblock::HTTP2 0.13+; HTTP/3 requires optional
Unblock::HTTP3 0.14+. Enable the corresponding installation feature or
install that engine explicitly before enabling the protocol. An unavailable
enabled engine produces an explicit attachment error. The separate
[implementation notes](docs/IMPLEMENTATION.md) record development history.

## One Server, many connections

Application code creates one definition:

```perl
use Unblock::HTTP::Server;

my $server = Unblock::HTTP::Server->new(
    http1 => {},
    http2 => {},
    http3 => {},
    on_request => sub {
        my ($tx, $request) = @_;
        $tx->respond(status => 200, body => "hello\n");
    },
);
```

An omitted protocol is disabled. Each protocol hash can carry engine tuning
options. WebSocket remains disabled by default; enable it per protocol
using `websocket => 1` and supply `on_websocket($tx, $request)`.
HTTP/2 and HTTP/3 require a framework `defer($callback)` that schedules
work on a later event-loop turn. The Server advertises Extended CONNECT
only for explicitly enabled protocols. WebSocket acceptance affects
one multiplexed stream on H2/H3, but transfers a whole HTTP1 socket.

`on_headers($tx, $request)` runs first. By default the engine buffers up to
1 MiB, then calls `on_request($tx, $request)` with the complete frozen request.
Set `max_buffered_body_bytes` in a protocol hash to change that positive limit.

For streaming, register `$tx->on_data(sub { my ($tx, $bytes) = @_; ... })`
during `on_headers`. This suppresses full-body accumulation. `on_request`
still runs after successful body completion. Failed or cancelled bodies do
not reach it. Register `$tx->on_finish(...)` before the transaction is terminal
to observe completion, error, or cancellation exactly once.

For enabled protocols this requires Unblock::HTTP1 0.13+, Unblock::HTTP2
0.13+, or Unblock::HTTP3 0.14+. Attachment also checks required engine methods
and gives an explicit error for an incompatible older engine.

## Framework attachment

For each incoming TCP/TLS connection, the adapter attaches its stream:

```perl
my $engine = $server->attach_stream(
    transport => $stream,
    alpn => $negotiated_alpn,
);

$engine->input($bytes);
```

The returned object is the actual HTTP1 or HTTP2 Server engine. Transactions
also come directly from that engine. There is no forwarding connection object.
The framework retains the engine and continues to own its socket and buffers.

The stream supplies `unblock_send`, `unblock_finish`, and `unblock_abort`.
`unblock_send` accepts the entire buffer or throws. A defined false result
means the bytes were accepted but the host is congested. The framework calls
`resume_output()` when it has capacity again.

Configure TLS using `$server->alpn_protocols`. This returns enabled TCP choices,
with H2 preferred. Empty ALPN selects H1 only when H1 is enabled. Unknown or
disabled protocols fail. For cleartext H2 prior knowledge, pass
`protocol => 'h2'` instead of `alpn`.

A ready HTTP/3 QUIC connection uses:

```perl
my $engine = $server->attach_quic(connection => $ready_h3_connection);
```

It returns a started HTTP3 Server engine. UDP and timer events continue to go
to `Net::QUIC::Driver`. The framework is responsible for supplying a connection
negotiated for H3. A QUIC manager can attach all ready connections to the same
definition:

```perl
my $endpoint = Unblock::HTTP::QUIC->server(
    server => $server,
    certificate_file => $cert,
    private_key_file => $key,
    send => $send_datagram,
    set_timeout => $replace_timer,
);
$endpoint->start;
```

Read `perldoc Unblock::HTTP::Integration` for the adapter contract.

## Shared Client

The Client now owns reusable HTTP policy, request scheduling, and per-origin
connection pools. An application makes one Client for many destinations:

```perl
my $op = $client->request(
    method => 'GET',
    url => 'https://example.com/data',
    on_response => sub {
        my ($tx, $response) = @_;
        print $response->status, "\n";
    },
);
```

The request returns an operation handle right away. Its `transaction()` is
undefined while waiting for a connection, then becomes the **real engine
Transaction** after dispatch. `cancel()`, `state()`, and `error()` work
without polling. A strict `http_version => '3'` requires HTTP/3, not a
fallback to HTTP/2. HTTPS cold requests use H2/H1 ALPN; later requests may use H3
through an authenticated, fresh, same-host Alt-Svc advertisement.

An integration supplies `connect_stream`, `connect_quic` and a `defer`
callback. The factory opens TCP/TLS or QUIC through its framework and calls
`$ready->(...)`. **The ready callback returns the real connected engine.**
The adapter keeps that engine on its framework-owned stream or connection and
feeds input directly to it. The `defer` callback schedules work in a later
event-loop turn. See `perldoc Unblock::HTTP::Client` and
`perldoc Unblock::HTTP::Integration` for the exact contracts.

By default the Client buffers up to 1 MiB of response data in the chosen
engine, then calls `on_response` once after body completion. Supplying
`on_data` automatically streams the response: `on_response` fires when
headers arrive, then `on_data($tx, $chunk)`, `on_end($tx)`, and terminal
`on_finish($tx)`. Client buffering does not add another body accumulator.

A request may set `timeout => $seconds` to cover queuing, establishment,
and its active HTTP transaction. The framework adapter supplies an optional
`schedule_timer($seconds, $callback)` constructor callback returning a timer
cancellation coderef. A timed-out active request cancels its real engine
transaction and reports a timeout on the operation. A factory can return
a cancellation coderef so a timed-out or manually cancelled connection
attempt releases its pool slot; late factory readiness is ignored.

When HTTP/3 QUIC bidi stream credit is exhausted, an unsubmitted
request stays in the bounded Client queue; the H3 engine notifies when
request stream availability changes, and the Client retries admission
only after framework deferral. No submitted request is replayed.

The framework may call `$client->network_changed` when its network
identity changes. This discards idle old-network sockets and Alt-Svc
hints, while active transactions continue on their original engines
until completion. Pending operations are retried only BEFORE dispatch
using fresh connections; a transmitted request is never replayed.
`$client->pool_stats` returns read-only origin and pool counts to
inspect queued, connecting, active, idle, and retiring connections.

Fatal hard-limit output rejection is distinct from cooperative
backpressure. The repository-only Linux::Event integration tests propagate
max_pending_bytes violations as transport errors; it does not
replay the rejected bytes. Unblock::HTTP1 0.13+ waits until attached output is accepted before
reporting a successful server terminal callback. See docs/IMPLEMENTATION.md.

Idle connection eviction is opt-in with `idle_timeout => $seconds`.
When enabled, the framework supplies `schedule_timer` and may supply
`release_connection($host, $engine, $protocol, $reason)` to close its own
socket or QUIC resources. Timers are cancelled on reuse and never close
connections with active streams or queued requests waiting for peer credit.

The repository-only live integration tests also exercise streamed request and
response bodies exceeding 1 MiB on H1/H2/H3, with integrity checks and
controlled accepted-but-blocked output resumption. A preliminary
direct-engine versus unified-Client TCP loopback benchmark is included
at `bench/client-vs-direct.pl`. HTTP/3 additionally has
`bench/h3-client-vs-direct.pl` for serial requests and
`bench/h3-workload-profile.pl` for isolated concurrent CPU, latency
and sampled RSS workloads. Read `docs/BENCHMARKING.md` and
`docs/PERFORMANCE.md` for how to run them and interpret their
limitations. CI correctness tests do not enforce throughput rates.

The queue defaults to 128 pending requests, with at most four connections per
origin and 32 concurrent streams per H2/H3 connection. An H1 connection runs
one request at a time. The limits are adjustable. Pool idle expiry and
WebSocket upgrades/Extended CONNECT are implemented; validated DNS HTTPS
discovery and convenience framework connector classes remain future work. Authenticated same-host Alt-Svc now permits
future requests to select HTTP/3. Advertisements are only learned when
the TCP factory explicitly reports verified_origin => 1 after certificate
and origin hostname verification. When advertised HTTP/3 is selected, the
QUIC factory receives alternative_host and alternative_port and must confirm
verified_origin => 1 before the request can be sent. A failed advertised
QUIC connection may safely fall back before dispatch; a request already
submitted to an engine is never automatically replayed.

## WebSockets across HTTP/1, HTTP/2 and HTTP/3

For each enabled protocol, Server `on_websocket` returns the WebSocket
session options/callbacks, or undef to reject the request with HTTP 403.
The handshake is validated before creating an established
Unblock::WebSocket::Server. H1 uses HTTP 101 and a socket input-consumer
switch; H2/H3 use HTTP 200 and independent streaming CONNECT
transactions on their existing multiplexed connections.

    my $server = Unblock::HTTP::Server->new(
        http2 => { websocket => 1 },
        http3 => { websocket => 1 },
        defer => sub { $framework->defer($_[0]) },
        on_request => sub { $_[0]->respond(status => 200, body => 'HTTP') },
        on_websocket => sub {
            return {
                on_message => sub {
                    my ($ws, $message, $type) = @_;
                    $ws->send_text("echo:$message") if $type eq 'text';
                },
            };
        },
    );

A unified Client selects its WebSocket protocol explicitly with
`http_version => '1.1'`, `'2'`, or `'3'`, or defaults to the
first enabled WebSocket protocol in that order:

    my $operation = $client->connect_websocket(
        url => 'wss://example.com/chat',
        http_version => '3',
        on_open => sub {
            my ($ws, $tx) = @_;
            $ws->send_text('hello');
        },
    );

The operation's `websocket()` accessor holds the actual WebSocket
Client once opened. H2/H3 WebSockets remain in the Client's pool until
their individual streams finish, allowing ordinary HTTP to share the
connection. HTTP3 Client WebSockets wait for the peer's current
Extended CONNECT SETTINGS before dispatch; if QUIC bidi-stream
capacity is unavailable, the original unsent operation remains
queued until credit returns. A denied/invalid handshake fails only
the relevant operation. Consult the [WebSocket cookbook](docs/WEBSOCKET-COOKBOOK.md),
Server and Client POD for running all three protocols, the exact
transport ownership rules, backpressure, Close and callback contracts.

## Examples and tests

The optional Linux::Event examples are:

- `examples/linux-event-server.pl`: a shared Server with H1/H2 attachment.
- `examples/linux-event-quic-server.pl`: a shared Server with a QUIC manager.
- `examples/linux-event-websocket-server.pl`: H1 Upgrade or H2 Extended CONNECT WebSocket echo.
- `examples/linux-event-websocket-client.pl`: matching H1/H2 shared Client transport factory and WebSocket echo.
- `examples/linux-event-quic-websocket-server.pl`: H3 WebSocket echo on QUIC/TLS.

Each separates application behavior from framework plumbing. The core does
not require Linux::Event. The distribution requires Perl 5.20; some
optional example programs use newer Perl syntax. No framework adapter
is installed by this distribution.

Run isolated contract tests:

    prove -lr t

Run the live tests after installing the real engines, Linux::Event and Net::QUIC:

    prove -l xt/linux-event-tcp.t xt/linux-event-websocket.t xt/linux-event-quic.t

The distribution suite combines isolated contract tests with real H1/H2
WebSocket exchanges, a borrowed native H1 input handoff regression,
and full localhost QUIC/TLS H3 WebSocket Server/Client tests.
The optional live integration suite additionally exercises real sockets,
streamed bodies, QUIC flow credit and resource bounds. CI does not
enforce performance or throughput thresholds.

## License

MIT License.
