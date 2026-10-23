# Client performance measurement

This is development-only benchmarking for the Unblock::HTTP feature branch.
Run only after the distribution suite and live H1/H2/H3 tests are green.
Performance is an input to design decisions, not a substitute for protocol
and transport correctness.

## First reproducible comparison

    perl Makefile.PL
    make
    perl -Iblib/lib -Iblib/arch bench/client-vs-direct.pl 5000 500 5

The arguments are measured completed requests, warmup requests and rounds.
The harness runs the same short GET/200 loopback workload in two modes:

- direct: application uses Unblock::HTTP1::Client or
  Unblock::HTTP2::Client, with one attached Linux::Event TCP stream,
  constructs Uniform::HTTP::Request and registers callbacks.
- unified: application uses Unblock::HTTP::Client request sugar,
  with one framework connection factory, the same TCP stream type,
  and the matching native H1/H2 engine attached through the upper Client.

Both modes use the same Unblock::HTTP::Server definition and the same
Linux::Event framework. Every run starts a fresh listener/connection,
warms its engine, and issues one request at a time. It counts finished
requests and requires the server to have received each one. Protocols
are cleartext HTTP/1.1 and HTTP/2 prior-knowledge to avoid comparing TLS
handshake noise. Both have the same 1 MiB receive buffer limit.

The output includes elapsed wall time and requests per second, plus a
unified/direct wall-time ratio. This is a first low-concurrency comparison
of the Client application-facing path, not an end-to-end direct HTTP stack
comparison. It does not measure or assert zero copies, allocations,
cache pressure, CPU time, latency percentiles, slow receivers, stream
fairness, TLS overhead, or QUIC behavior.

## Measurement requirements

Do not treat a single CI run as a stable speed comparison. For a useful
local investigation:

1. Use the same pinned H1/H2 feature engine sources and Uniform::HTTP
   dependency in both modes; record the commits and Perl version.
2. Warm up both modes, repeat runs on a quiet machine, and inspect the
   distribution and variance of results. The current harness runs
   direct first, so additionally control run-order bias before treating
   small differences as real.
3. Repeat with keep-alive, H2 concurrency, varied header/body sizes,
   sustained streaming, and intentionally slow receivers in separate
   fixtures. Monitor maximum outstanding bytes and producer wakeups.
4. Instrument allocations/CPU profile and byte-copy counts at framework
   and engine boundaries before claiming fewer copies or faster dispatch.
5. Do not optimize by making the unified API perform per-body-chunk
   forwarding. Engine-owned framing, flow control and receive buffers
   remain mandatory.

The Actions workflow runs a short benchmark smoke check only to confirm
both modes can complete the same workload. No throughput threshold is used.

## Initial CI observations (not performance guarantees)

GitHub Actions real-sockets on the feature branch ran 1,000 measured
requests, 100 warmup requests and three alternating-order rounds per
protocol and mode, using a 1-connection, 1-in-flight GET/200 workload.
These are per-run medians from uncontrolled shared CI runners:

| Source | H1 direct | H1 unified | H1 ratio | H2 direct | H2 unified | H2 ratio |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Before optimization, CI 39076051442 | 0.28021s | 0.37543s | 1.340 | 0.26195s | 0.35947s | 1.372 |
| Skip unnecessary quiet pool defer, CI 39076255077 | 0.27318s | 0.35407s | 1.296 | 0.25810s | 0.34514s | 1.337 |

A ratio greater than 1 means the unified Client took longer for the
same measured request count. The relative gap remains material in
this narrow test. The scheduling change removes an unnecessary
framework callback when no queued work, idle timer or retirement
needs it, and it passed the complete correctness suites. Differences
between CI runner machines and caching mean the two rows do not
establish a precise improvement percentage.

Do not extrapolate these numbers to bulk streaming, multiplexed H2,
QUIC/H3, slow receivers, CPU consumption or production capacity.

## Request-path profiling checkpoint (2026-10-17)

The loopback comparison now times the synchronous call to request() as
well as the full application-level request/response wall time. Both
the direct-engine and unified modes include Uniform Request creation
in that call; the unified mode also parses and validates the URL,
selects an origin and native engine, and performs pool admission.
The extra Time::HiRes calls perturb each measured request, so figures
should be compared ONLY to runs with identical instrumentation.

bench/request-setup.pl is an additional pure user-space microbenchmark.
It measures URI parsing/validation, Uniform::HTTP::Request construction,
and their combination separately, with no sockets, engine, or pool.
These measurements are descriptive, not a decomposition that sums to
precisely the total request() time.

First instrumented CI 39079013272, median us/request() across three
alternating-order rounds of 1,000 measured requests:

| Mode | H1 direct | H1 unified | H2 direct | H2 unified |
| --- | ---: | ---: | ---: | ---: |
| Original pool scheduling | 45.61 | 93.18 | 45.22 | 99.82 |
| Reusable connection direct-dispatch, CI 39079217496 | 45.10 | 87.77 | 45.42 | 95.26 |
| Same direct-dispatch + 9 regression checks, CI 39079251789 | 73.67 | 131.22 | 80.54 | 148.14 |

The first microbenchmark reported medians of 9.871 us for URI
validation, 10.425 us for Uniform construction, and 20.872 us for
the combined case. They are not additive to protocol execution.

The Client optimization bypasses full queue insertion and pool scanning
only if exactly one healthy ready connection can immediately admit
the request, with no existing queued work, maintenance, callback stack
reentrancy, or idle_timeout. Every other path stays with the general
bounded scheduler.

CI 39079251789 passed 552 distribution checks and 145 live H1/H2/H3
tests. The direct-dispatch path was also covered by targeted unit tests.
Runner-to-runner timing variation is substantial, so the exact apparent
speedup is NOT established. What is established: a redundant scheduler
scan was removed in a provably eligible case without breaking regression
tests. The remaining synchronous overhead is material and needs
subcomponent profiling before more risky parser or pooling shortcuts.

Run:

    perl -Iblib/lib -Iblib/arch bench/client-vs-direct.pl 5000 500 5
    perl -Iblib/lib -Iblib/arch bench/request-setup.pl 20000 5

## Slow-reader correctness evidence (2026-10-17)

The upper branch's xt/linux-event-slow-reader.t is a correctness
fixture, not a throughput benchmark. The actual LinuxEvent client
socket pauses reading for 120 milliseconds, then resumes. Its server
sends a reproducible six-MiB response through the unchanged H1/H2
engines using a 16 KiB high / 4 KiB low output-watermark configuration.
The test verifies per-byte SHA-256 integrity and response lifecycle
after read resumption. CI 39083903027 passed 552 distribution tests
and 168 live TCP/QUIC tests including this fixture.

On that CI runner H1 reported one real false result from the transport
write method and one later on_drain callback. H2 reported none:
connection and stream credit can limit H2 send output upstream of
the TCP transport. A successful slow-receiver transfer without a
transport-level false return is not evidence of no flow control.

The LinuxEvent high_watermark is advisory, not a hard cap on bytes.
LinuxEvent also has max_pending_bytes, but the upper layer does not
manage that queue or expose a pending-byte high-water measurement.
We have not established a bounded worst-case memory commitment,
per-chunk copy counts, or actual sustained receiver-rate throughput.

## Genuine cooperative producer backpressure (2026-10-17)

The new xt/linux-event-producer-backpressure.t is a correctness and
queue-observability fixture, NOT a throughput benchmark. The real
LinuxEvent client socket stops reading for 400 ms while a streaming
H1/H2 server produces eight MiB in eight-KiB chunks. The producer
stops when native Transaction->write() returns false, resumes via
on_drain, limits itself to eight chunks per deferred loop turn, and
delivers every chunk once. The end() call is postponed if the final
accepted write itself returned false.

Transport configuration: high_watermark 32 KiB, low_watermark 8 KiB,
max_pending_bytes 512 KiB, SO_SNDBUF 32 KiB; sample pending_bytes()
after transport sends and drains. The maximum *sampled* bytes include
only pending data in the LinuxEvent socket queue. They are NOT
sufficient to bound HTTP2 nghttp2 provider queues, QUIC/HTTP3
buffers, unsampled intervals, kernel socket memory or Perl allocations.

Verified CI 39085138364: 552 distribution checks, 203 live TCP/QUIC
checks, all green. Observations on that host:

| Observed property | HTTP/1.1 | HTTP/2 |
| --- | ---: | ---: |
| Producer write() false | 51 | 95 |
| Producer on_drain resumptions | 51 | 95 |
| Actual TCP on_drain callbacks | 51 | 64 |
| Maximum sampled pending_bytes | 32,856 B | 32,821 B |
| Hard queue cap configured | 524,288 B | 524,288 B |

The difference between HTTP/2 producer and TCP drain counts reflects
engine-level flow control. High/low watermarks remain cooperative,
while max_pending_bytes is a separate hard cap. This fixture has not
forced that limit to reject an oversized write and does NOT establish
the boundary's rejection or partial-write semantics. Do not assert
a total bounded-buffer guarantee based on these numbers.

## Three-client slow-consumer isolation (2026-10-17)

xt/linux-event-pool-fairness.t exercises three separate H1 and H2
pooled TCP connections on one local origin. Two receiving sockets
are paused for 800 ms; the third request completes a 2 MiB streamed
response before those readers resume. Each server producer uses
4 KiB writes, at most four per deferred turn, and stops until native
on_drain after congestion. The response digests, bytes and terminal
callbacks are verified independently. The server sockets use a
512 KiB pending-output limit; all sampled queue values remained
well below it.

CI 39087771958 PASS: 552 distribution checks and 289 live checks,
including this three-client fixture. Measured maximum sampled TCP
queue: 32,832 bytes for H1 and 32,821 for H2. Both engines made
progress for the fast client despite the two paused readers.

These are functional isolation observations, not statistical
throughput/fairness or aggregate memory bounds. This fixture does
not cover H3 stream multiplexing, cross-origin competition,
thousands of sockets, Linux scheduler variance, or absolute
engine-buffer high water under sustained peer flow-control loss.

## Live H3 producer backpressure and mixed-stream progress (2026-10-17)

The existing H3/QUIC test suite now includes
xt/linux-event-quic-producer.t. An actual HTTP3::Transaction feeds a
2 MiB response through 4 KiB writes, at most four per deferred event-loop
turn. Native write(false) stops production; engine on_drain wakes it
without replaying bytes. Seven small buffered responses concurrently
share the same Net::QUIC connection and UDP socket.

CI 39088458914 PASS: 552 distribution and 368 live checks. The
H3 producer observed 256 native backpressure events and the same
number of on_drain wakeups, in 257 turns with a maximum burst of
two chunks per turn. Every response's integrity and lifecycle checks
passed. Native send_buffer_limit was set to 8192 bytes.

A later assertion also checks that one of the small requests
finishes before the large response completes. CI 39088663590
passed 552 distribution checks and 369 live checks, including
this cross-stream progress assertion.

The H3 native send_buffer_limit is not an aggregate Net::QUIC or UDP
memory limit. This workload does not stop H3 stream receive-credit
return, nor measure packet/stream outstanding bytes, allocator
high-water, CPU, or latency percentiles. These should be measured
separately before a general "bounded memory" or cross-stream
fairness claim is made.

## Pull Reader credit gating and observed queue bytes (2026-10-17)

The additional live H3 test at xt/linux-event-quic-reader-credit.t
uses an advanced HTTP3::Body::Reader without on_data. Holding off
next_chunk() for 500 ms stops application QUIC body-credit return.
The QUIC client advertises a 32768-byte per-stream receive window.
A short independent H3 response completes on the same authenticated
connection while a 2 MiB long response remains awaiting Reader
consumption. After release, deferred bounded polling drains the
queued body, resumes producer progress and verifies SHA-256.

CI 39092855745 PASS: 552 ordinary distribution checks and
387 live checks in nine files. Recorded observations:

| Quantity | Result |
| --- | ---: |
| Reader pending body bytes at hold release | 32,739 |
| Peak sampled Reader pending bytes | 32,739 |
| Producer backpressure events | 257 |
| Producer native on_drain resumptions | 257 |
| Bounded Reader polling turns | 667 |

Strengthened CI 39093070343 PASS with 552 distribution and
389 live checks. At the 500ms hold release the producer
had submitted only 10 out of 512 chunks and the maximum
sampled Reader pending was 32,739 bytes, at or below
the configured 32KiB stream window. This is direct
receive-credit stalling evidence, but still not total
process memory instrumentation.

An additional live observation samples the public
Net::QUIC::Connection->send_buffered_bytes() on the server.
That is outgoing Stream data retained for transmission,
including bytes awaiting acknowledgement. CI 39093371363
PASS (552 distribution and 391 live checks) measured
8,192 bytes at the 500 ms credit-hold release, and 8,192
bytes as the maximum sampled QUIC send-buffer count.
The client-side Reader still held 32,739 incoming bytes.
The producer had submitted only 10/512 chunks at release.

These counters are distinct and cannot simply be added as
total process memory: they cover the Reader's decoded
queued incoming bytes and QUIC's retained outgoing Stream
data, but not nghttp3's native send/provider retention,
QUIC packet metadata and retransmission allocations,
kernel networking buffers, or Perl allocator overhead.
An end-to-end bounded memory measurement needs those
additional counters and process high-water metrics under
controlled traffic; this fixture establishes neither a
general QUIC send-buffer cap nor a process RSS bound.
No rate or throughput claim is made from this correctness fixture.

## Next benchmarks to implement

- Concurrent client sockets, changing connection/stream caps, idle
  retirement and origin fairness.
- Large buffered versus streamed body throughput, throughput under
  transport backpressure, timer scheduling and pause/resume correctness.
- Real QUIC/TLS H3 performance relative to direct HTTP3 Client attachment,
  with and without multiple concurrent streams.
- Report throughput, latency distributions, CPU, memory high-water,
  queued bytes, and copying rather than only a single requests/s number.
