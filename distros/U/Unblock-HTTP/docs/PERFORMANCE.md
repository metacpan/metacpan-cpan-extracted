### Canonical Client URL optimization verified

The conservative production change in 48465c3, followed by
the profiler invariant correction in c305ba1, passed both
[primary published-Net::QUIC-0.05 CI](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39304048428)
and
[optional QUIC feature CI](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39304048477).
The new URL behavior regression t/26 passed, and the CPU-only
split profiler verified no URI constructor calls for its
canonical URL. All existing live TCP/QUIC and sustained
16/32-inflight memory tests passed. Separate CI hosts and
clock instrumentation prevent claiming a reliable net
microsecond speedup from the observed totals. No further
full benchmark sweep was run for this change.

### Canonical Client URL benchmark invariant

The CPU-only optional phase profiler fixed at
https://localhost/profile previously asserted one URI constructor
call per Client request. The optimized canonical ASCII path now
deliberately calls none. The adjusted profiler checks zero
URI::new calls, while retaining instrumentation so unexpected
fallback is detected. Counts for all other constructors, dispatch
and engine requests remain unchanged, as do pool quiescence and
callback completion assertions. No performance threshold applies.

## Client canonical-URL parsing fast path (development)

The unified Client now recognizes a narrow subset of ordinary
lowercase, ASCII http/https URLs directly without allocating a
URI object. It preserves the same scheme, host, default or explicit
port, authority and request target as URI for this subset. Other
URLs, including IPv6, percent escapes, uppercase host/scheme,
unusual ports and fragments, take the unchanged URI parsing
and validation route. The existing Uniform::HTTP::Request is
still constructed in every case. The optimization does not cache
URLs, modify engine ABIs or bypass validation for noncanonical
inputs. t/26 compares fast and fallback behavior against URI.

Use the existing CPU-only Client request setup benchmark plus
mandatory real-QUIC integration tests for verification; no new
full 20-scenario suite or noisy CI speed threshold is required.

### Archived hosted sweep results

The complete 20-scenario x two-sweep summary, including every seven-round wall-ratio range and client CPU/setup comparisons, is retained in [PERFORMANCE-SWEEP-20261019.md](PERFORMANCE-SWEEP-20261019.md). It is descriptive hosted-CI evidence only; the raw original JSON artifact has 30-day retention.

## Separate-mode memory comparison (2026-10-19)

The offline comparator previously pooled private memory changes from
direct and unified request processes into one median. This was not
a meaningful comparison. The corrected output reports independent
median start/end changes for each mode in RSS, PSS and private memory
(KiB), plus unified-minus-direct differences between mode medians.
Unavailable /proc observations are null in JSON / NA in text.
These measure process size, NOT native copies or allocations. The
new t/25 fixture has distinct direct/unified memory changes.

### Updated engine pins verified on published Net::QUIC (2026-10-19)

The primary
[39269889137](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39269889137)
and optional transport-feature
[39269889206](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39269889206)
CI passed with feature heads HTTP1 bb8349e, HTTP2 51fb1ad and
HTTP3 6687bce. The existing 16/32 sustained memory regression
and TCP/QUIC tests remain green. An exploratory separate
[full 20-case seven-round diagnostic](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39269889496)
was still running at last check. Results were not yet available.
No released dependency or production engine has been modified.

## Full 20-scenario seven-round hosted real-QUIC diagnostic (2026-10-19)

A separate .github/workflows/h3-seven-round-diagnostic.yml
captures two complete workload sweeps on ONE hosted Ubuntu runner.
Each sweep checks 20 cases, 2048 measured requests, 128 warmups
and seven paired direct/unified rounds per case. The second
reverses URL-pattern order and rotates five workload pairs.
The fixed engine commits are HTTP1 bb8349e, HTTP2 51fb1ad,
HTTP3 6687bce with published CPAN Net::QUIC 0.05.

The job preserves per-trial profile JSON, raw per-case logs,
comparison JSON and human-readable paired summary as a workflow
artifact for additional examination. It is intentionally
independent of mandatory integration tests, and a speed
difference never fails CI. Hosted runner noise, scheduling,
throttling and CPU performance variability prevent its ratios
from being definitive. Confirmation still requires repeating
the full sweep on a quiet dedicated host.

### Matched independent-sweep CI results (2026-10-19)

The first independent-sweep benchmark smoke is fully CI-verified:
[primary published Net::QUIC 0.05 integration 39239243745](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39239243745)
PASS and
[separate QUIC feature diagnostic 39239243736](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39239243736)
PASS. The primary test ran two independent 96-measured/24-warmup,
three-paired-round 16-inflight 4/16-KiB sweeps, each with both URL
patterns and reverse ordering. Paired unified/direct median wall
ratios from run A vs run B were 1.0513 vs 1.0741 for cycled URLs,
and 1.0761 vs 1.0881 for unique URLs. Three-round ranges overlapped;
the first cycled run B included a round as low as 0.9099. The
synchronous request setup differential was roughly 51-57 us/request.
These observations demonstrate working independent comparison, NOT
a stable API-overhead ratio. All unchanged 16/32 sustained memory
regressions passed. The full quiet-host seven-round sweep is pending.

## Independent real-QUIC cross-sweep validation (2026-10-19)

The primary Linux::Event workflow now runs two independent real-QUIC
benchmark sweeps with identical 96 measured requests, 24 warmup,
3 direct/unified rounds, concurrency 16 and alternating 4/16 KiB
responses for each cycled and unique URL pattern. In the second
sweep, cycled and unique URL order is reversed. The offline
comparator reads four separate real-QUIC trial reports, checks
metadata and writes a comparison JSON without enforcing a
performance threshold. Hosted CI is not a dedicated quiet host.

For focused local repeats:

    perl bench/h3-profile-sweep.pl --pair=c16-b4096-16384 \
      --samples=96 --warmup=24 --rounds=3 /tmp/h3-pair-a
    perl bench/h3-profile-sweep.pl --pair=c16-b4096-16384 \
      --samples=96 --warmup=24 --rounds=3 \
      --swap-url-order /tmp/h3-pair-b
    perl bench/h3-compare-sweeps.pl /tmp/h3-pair-a /tmp/h3-pair-b

The new --pair filter selects both URL patterns for one
concurrency/payload combination. It cannot be combined with --only.
The comparator rejects identical directories, including symlink
aliases, so its output cannot mistake a self-comparison for two
independent measurements. Synthetic regressions cover both features.
The full seven-round, twenty-case quiet-host experiment is still
required before production optimization.

### Verified cross-sweep comparator

The feature-branch comparison tool at source ebf9a1b passed complete
published-Net::QUIC-0.05 primary integration
[39230363530](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39230363530)
and optional QUIC-feature diagnostics
[39230363646](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39230363646).
This includes the new synthetic rejection tests, the existing
bounded-memory 16/32 stress, and the real-QUIC one-case self-comparison
that exercises saved-report decoding. The self-comparison always
reports no change; it does not estimate performance variability.
A dedicated-host paired 20-case sweep remains outstanding.

## Compare two controlled-host sweeps (2026-10-19)

After two complete same-host sweep runs at matching sample counts and
rounds, with rotated and reversed URL order:

    perl bench/h3-compare-sweeps.pl --json=/tmp/h3-comparison.json \
      /tmp/h3-sweep-01 /tmp/h3-sweep-02

The analyzer recomputes per-round direct/unified statistics and checks
saved medians, completed case sets, identical inputs, hardware/kernel,
Perl, upper Git commit, Net::QUIC version and governor metadata.
It refuses incomplete or incompatible reports. Rotation does not
change the comparison pairing because scenario IDs are matched by name.

The output shows both sweeps' median paired wall ratios and ranges,
client CPU ratios, synchronous request-time differences, per-round
p95/p99 differences and private-process memory changes. Direction
reversals across repeated sweeps are exposed without using any
arbitrary significance threshold. A median of per-round p95 differences
is not a pooled p95, and RSS/private differences do not count native
copies or allocations. These are descriptive benchmark comparisons,
not CI performance pass/fail gates. Source provenance still requires
separate recording of lower engine and native dependency build hashes.

The synthetic regression t/25-h3-compare-sweeps.t rejects incomplete
runs, host mismatches and inconsistent saved summaries. The existing
published-Net::QUIC-0.05 CI smoke compares its completed one-scenario
real-QUIC sweep against itself to exercise raw result validation.
Such a self-comparison establishes plumbing correctness, not a
second independent performance measurement.

### Sweep launcher CI verification

The launcher and its new schedule regression passed primary
published-Net::QUIC-0.05 Linux::Event workflow
[39190997695](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39190997695)
and separate optional feature diagnostic
[39190997771](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39190997771).
Primary CI exercised a 24-request, one-paired-round real-QUIC
single-scenario run, verified its versioned manifest, and retained all
the existing 16/32-concurrent 2048-request memory guards. No
dedicated-host 20-case, seven-round result was produced.

**Source-provenance caution:** the launcher checks the loaded
Net::QUIC version is 0.05, not the cryptographic origin of its installed
source. An unreleased feature checkout may also expose version 0.05.
Use the published CPAN Net-QUIC-0.05 distribution for the dedicated
sweep, and record the installation source plus the exact upper/H3
engine commit identifiers; do not substitute the optional feature
diagnostic run for a published-dependency result.

## Automated controlled-host real-QUIC sweep (development)

Use the feature-branch benchmark-only launcher to avoid accidentally
comparing different client/server workloads or copying profiler settings
by hand. It invokes the existing isolated Linux::Event/QUIC profiler
without touching production code or installing any new dependency:

    perl Makefile.PL && make
    perl bench/h3-profile-sweep.pl --dry-run /tmp/h3-plan-only
    perl bench/h3-profile-sweep.pl /tmp/h3-sweep-01
    perl bench/h3-profile-sweep.pl --rotate=5 --swap-url-order /tmp/h3-sweep-02

Defaults are **2048 measured requests, 128 warmups, seven paired rounds**
per scenario. There are 20 cases: both cycled and unique target patterns
at concurrency 1, 8, 16, 32 with 1 KiB or alternating 4/16 KiB bodies;
64 KiB responses at 1 and 8 concurrent requests only. The high
inflight/64 KiB combinations are deliberately omitted to avoid
confounding comparisons with the default approximately 1 MiB QUIC
receive-credit window. Cycled/unique scenarios stay adjacent; rotating
the ten scenario pairs and swapping URL order makes repeat-host passes
less dependent on an arbitrary starting order. The seven internal
direct-vs-unified rounds also alternate execution order.

The launcher enforces **published Net::QUIC 0.05** and rejects optional
checkpoint/registry/wire/heap instrumentation during timing runs.
Each case gets its own raw text log and versioned profiler JSON file.
An atomically updated sweep.json records the scenario order, Perl,
kernel/architecture/CPU model, observed governor if readable, upper
Git commit, Net::QUIC version, completed cases and their paired wall
ratios. A failing trial stops the sweep with its log and incomplete
manifest preserved; existing result directories are not overwritten.
This captures provenance, not CPU isolation. Record external host load,
governor changes, exact lower engine source pins, and repeat runs too.

For a cheap REAL-QUIC launcher smoke on an already configured host:

    perl bench/h3-profile-sweep.pl --only=c08-b1024-unique \
      --samples=24 --warmup=8 --rounds=1 /tmp/h3-sweep-smoke

The regression t/24-h3-profile-sweep.t checks all schedule combinations,
pair adjacency, deterministic rotation, reverse ordering and option
validation without requiring QUIC. The primary Linux::Event workflow
also executes an opt-in one-case real-QUIC launcher smoke against CPAN
Net::QUIC 0.05. This is not a benchmark performance gate or a substitute
for quiet-host seven-round measurements.

## Verified paired-profile reporting and JSON CI (2026-10-18)

At upper feature source 9ba46d8, published-Net::QUIC-0.05 primary
integration [39187454014](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39187454014)
PASS and independent QUIC feature diagnostic
[39187454090](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39187454090)
PASS. New t/23 paired-statistics regressions and the two-round,
32-inflight live-QUIC versioned-JSON smoke passed. Full 16/32
2048-measured-request bounded-memory checks remained enabled and passed.
No speed thresholds or production code changes.

At identical 384-measured/48-warmup/3-round 16-inflight alternating
4/16-KiB workloads on the primary hosted runner, paired median
unified/direct wall ratios were 1.0267 (cycled URLs) and 1.0608
(unique URLs). The preceding successful hosted primary run
[39187178815](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39187178815)
had produced the opposite ordering: 1.0771 cycled and 1.0496
unique. This reversal between runs is a useful warning against
interpreting small CI ratio differences as a URL-cache benefit.
The new reporting format makes order/round variation visible; it
does not eliminate shared QUIC, scheduler, TLS or CPU noise.

## Paired-round and JSON profile capture (development, 2026-10-18)

The real-QUIC profiler now prints **paired round** comparisons in
addition to its historical direct and unified wall-time medians. Each pair
comes from the same round and workload, with alternating mode order.
The median of seven paired wall ratios is not generally the ratio of the
two independent wall-time medians. Each pair also reports the ratio of
client-only process CPU time, unified-minus-direct synchronous request
cost, and p50/p95/p99 completion latency differences (microseconds).
A zero direct CPU reading produces NA rather than a division by zero.

For a reproducible archive of raw per-trial measurements, opt in to a
single versioned JSON file. The writer runs **after** all timed trials,
not in an HTTP callback or QUIC hot path:

    UNBLOCK_H3_PROFILE_URL_MODE=unique \
    UNBLOCK_H3_PROFILE_JSON_FILE=/tmp/h3-unique-c16.json \
      perl -Iblib/lib -Iblib/arch \
      bench/h3-workload-profile.pl 2048 128 7 16 4096,16384

The JSON contains workload parameters, all direct/unified round results,
their memory checkpoint arrays (when explicitly enabled), and paired
summary statistics. Keep the exact Perl/XS versions, CPU model, clock/
governor, OS/kernel, and runner load with the resulting file; the JSON
does not claim to fingerprint or control the machine. Use unique output
filenames for each scenario. Never compare checkpoint-instrumented runs
against ordinary timing runs.

For the controlled-host sweep repeat this command with concurrency 1,
8, 16 and 32, 1024-byte, alternating 4096/16384-byte and 65536-byte
responses, and both cycled/unique URL modes. Change one parameter at
a time. Record the order of scenarios and preferably rotate that order
across repetitions. Seven alternating-order rounds reduce, but do not
eliminate, time/order effects. Compare within host, record median paired
ratios AND their range along with CPU and p95/p99, and make no
production changes from hosted-CI speed ratios alone.

The primary Linux::Event integration CI also exercises the JSON writer
on its existing two-round 32-inflight real-QUIC smoke. It checks the
decoded schema, paired rounds, trials and expected order, without a
performance threshold; the 16/32 sustained retention guards remain
separate and unchanged.

The pure-Perl paired-statistics validator has a synthetic test
(t/23-h3-profile-summary.t), including malformed/missing trials and the
difference between paired-ratio median and ratio-of-medians. No change
was made to application request construction, URL parsing, or transport.

## Matched repeated-vs-unique URL control results

On the same Ubuntu GitHub runner, the published Net::QUIC 0.05
primary workflow
[39184885870](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39184885870)
PASS ran identical two-body, 16-concurrent, 384-request,
48-warmup, three-round workloads in immediate succession:

| URL pattern | Direct median wall | Unified median wall | Unified/direct |
| --- | ---: | ---: | ---: |
| Repeating two paths (original) | 0.8121 s | 0.9021 s | 1.111 |
| Unique `?req=N` per request | 0.8106 s | 0.8672 s | 1.070 |

Every trial was a fresh client/server QUIC session using identical
payloads, HTTP3 engine, callbacks, and validation, and none of the
timing paths enabled smaps checkpoints. The surprising smaller
unified/direct ratio on unique URLs does **not** establish that
unique paths are inherently faster. In particular, these are
sequential hosted-CI workloads, not a dedicated CPU-isolated
experiment or an allocation/copy measurement. Variation in CPU
scheduling and TLS/UDP/QUIC effects remains possible. This
does not justify reinstating the speculative URL parse cache.

The separate dynamic-URL three-size smoke on primary
[39184272657](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39184272657)
also PASS: direct/unified median throughput 902.9/827.2 req/s
at 1 inflight, 1024 bytes; 541.0/525.3 req/s at 16 inflight,
alternating 4096/16384 bytes; and 135.7/129.4 req/s at
8 inflight, 65536 bytes. In every case response bodies,
terminal callbacks and private memory stayed within the
expected short-workload bounds. These numbers are
descriptive single-run measurements, **not** stable
library overhead percentages.

## Verified unique-URL real-QUIC profiles

Primary published-Net::QUIC-0.05 Linux::Event integration
[39184272657](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39184272657)
PASS. Separate QUIC feature diagnostic
[39184272709](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39184272709)
PASS. The primary job ran the same direct/unified protocol and
callback checks under fresh QUIC/TLS client+server process pairs:
384 measured requests after 48 warmups, three alternating-order
rounds, one unique path+query per request.

| Inflight / body sizes | Direct median | Unified median | Unified / direct wall |
| --- | ---: | ---: | ---: |
| 1 / 1024 bytes | 902.9 req/s | 827.2 req/s | 1.092 |
| 16 / 4096,16384 bytes | 541.0 req/s | 525.3 req/s | 1.030 |
| 8 / 65536 bytes | 135.7 req/s | 129.4 req/s | 1.049 |

These are hosted-runner *descriptive* ratios, not portable speed
claims. Request setup is proportionally more conspicuous at
one in-flight small response, while larger payloads/concurrency
have more shared engine/transport work. All three verified complete
responses and successful terminal callbacks. Private/PSS/RSS client
memory stayed near-flat over these relatively short trials; the
existing separate 2048-request 16/32 memory guards remain the
actual retention regression checks.

A subsequent CI revision adds an **exactly matched cycled-URL
control** (same requests, sizes, concurrency, warmup and rounds)
immediately before the unique-URL 16-concurrent scenario on a
single hosted runner, so URL pattern can be examined within-run
rather than across runners. That control has no pass/fail
performance threshold and must be read with host-noise caveats.

## Unique-URL workload characterization

The real-QUIC workload profiler also supports
`UNBLOCK_H3_PROFILE_URL_MODE=unique`. Each GET receives a distinct
`?req=N` query component, with request numbers unique across warmup
and measurement for each trial. The server verifies the query and
continues to choose the same response body by the path index.
Both direct and unified clients therefore send **identical**
deterministic targets. The default `cycled` mode is unchanged,
preserving all historical comparisons and the long-running 16/32
memory regression guards. This option does not require a new
request/response type or production code change.

A reproducible, non-gating workload sweep on a reasonably quiet Linux
machine with fixed Perl, XS modules and Net::QUIC 0.05 can run:

```sh
# First capture the exact Perl, CPU, kernel and module versions.
perl -V:version
uname -sr
perl -MNet::QUIC -e 'print "$Net::QUIC::VERSION\n"'

# Avoid checkpoint smaps sampling for timing comparisons.
# Repeat full sets and compare within each set, not across hosts.
UNBLOCK_H3_PROFILE_URL_MODE=unique perl -Iblib/lib -Iblib/arch \
  bench/h3-workload-profile.pl 2048 128 7 1 1024
UNBLOCK_H3_PROFILE_URL_MODE=unique perl -Iblib/lib -Iblib/arch \
  bench/h3-workload-profile.pl 2048 128 7 16 4096,16384
UNBLOCK_H3_PROFILE_URL_MODE=unique perl -Iblib/lib -Iblib/arch \
  bench/h3-workload-profile.pl 2048 128 7 8 65536
UNBLOCK_H3_PROFILE_URL_MODE=unique perl -Iblib/lib -Iblib/arch \
  bench/h3-workload-profile.pl 2048 128 7 32 4096,16384
```

Use the per-round client-only wall time, CPU, synchronous
`request_us`, and p50/p95/p99 completion latency together.
The profiler rotates direct-first/unified-first order, forks fresh
client/server processes, verifies response status and body, and
excludes TLS connection setup through its warmup. Each scenario
still has only one QUIC connection: it does not simulate multiple
upstream origins or Internet latency. Inflight count and body size
jointly affect connection-level credit; avoid drawing conclusions
from a setting that stalls for flow-control reasons.

Do not compare uninstrumented timings with memory-checkpoint
runs, wire-counter runs or constructor-hook runs. Hosted CI
automatically smokes three of these unique workloads, but speed
thresholds are not asserted. No actual native copy or allocation
events are counted here. If a consistent end-to-end difference
persists on a quiet host, then instrument the specific native
copy boundary identified in `docs/PERFORMANCE-COPY-BOUNDARIES.md`
in the HTTP3 engine repository rather than estimating from RSS.

## URL cache experiment: rejected (October 18, 2026)

A bounded four-entry exact-URL parse cache was tested on the upper
feature branch and subsequently removed. The restored primary
published-Net::QUIC-0.05 integration
[39179316288](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39179316288)
and separate diagnostic
[39179316250](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39179316250)
both PASS, including the original 16/32-concurrency resource guards. The canonical `URI->new`
parser and normal per-request validation remain unchanged.

Paired benchmark evidence:
- Published-Net::QUIC-0.05 real-QUIC run
  [39178500583](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39178500583)
  compared 1024 measured requests after 64 warmup, three rotated
  fresh-process rounds, 16 in flight, alternating 4/16 KiB response
  bodies. Median unified uncached 0.9683s versus cached 0.9308s
  (4.0% less wall time on this single runner).
- A second matched full real-QUIC run
  [39178731269](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39178731269)
  reported only a 1.004 uncached/cached wall ratio (about 0.4%).
- That later run also compared 16 distinct rotating URLs in the
  CPU-only mock benchmark. Cache disabled: 81.967 us/request;
  four-entry cache enabled but every URL missing:
  84.151 us/request (2.7% slower). This isolates miss overhead
  but excludes QUIC, TLS, UDP and server work.
- The repeated single-URL mock was much more favorable:
  57.478 us/request uncached versus 39.721 cached
  [39178289739](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39178289739).
  Its request/finish path does not include the actual
  network/HTTP3 stack.

This was too workload-dependent for an always-on optimization.
The cache introduced state and a miss penalty, while its real-QUIC
benefit varied on hosted CI. The change was reverted without
touching the established 16/32-concurrent memory regressions
or HTTP3 engine lifecycle fixes. The diagnostic source and output
remain available in the experimental feature commit history
(`199e3b3` through `13d0a1f`), but are not part of the
current benchmark/production tree. No native allocation or
payload-copy counts were measured.

# HTTP/3 performance experiments

The high-level Client and direct HTTP/3 engine need to be compared on the
same workload. These scripts are experiments, not performance gates. They
do not change protocol engines, QUIC, Uniform::HTTP or application APIs.

## Run them

Install the feature-branch dependencies described in
`Handoff.md`, and build this distribution with `perl Makefile.PL`
and `make`. With Linux::Event and the QUIC TLS stack installed:

```sh
perl -Iblib/lib -Iblib/arch bench/h3-client-vs-direct.pl 1000 100 7
perl -Iblib/lib -Iblib/arch bench/h3-workload-profile.pl 500 80 7 1 2
perl -Iblib/lib -Iblib/arch bench/h3-workload-profile.pl 500 80 7 4 16384
perl -Iblib/lib -Iblib/arch bench/h3-workload-profile.pl 200 40 7 4 262144
perl -Iblib/lib -Iblib/arch bench/h3-workload-profile.pl 500 80 7 12 16384
perl -Iblib/lib -Iblib/arch bench/h3-workload-profile.pl 500 80 7 32 16384
perl -Iblib/lib -Iblib/arch bench/h3-workload-profile.pl 500 80 7 8 4096,262144
```

The `h3-workload-profile.pl` arguments are **measured requests,
warmup requests, rounds, maximum requests in flight, and response-body
bytes**. The fifth argument also accepts up to eight comma-separated byte
sizes (for example `4096,262144`, each at most 1 MiB). Each size is
selected by the request's index in the current warmup or measured phase,
and encoded in its URL path so out-of-order multiplexed completion cannot
change the expected body. Both modes use the same deterministic request
sequence, server, payload contents and bounded concurrency. A single size
retains the original `/profile` path for backwards comparison.
The accepted ranges are documented in the script's usage and validation.

The profiler permits up to 32 in-flight requests, which can be used to
compare direct and unified response buffering at the upper pool's normal
per-connection multiplexing limit. At 32 x 16 KiB, one full in-flight wave
fits below the default 1 MiB connection receive window. This is NOT a
connection-credit starvation regression or a throughput guarantee.

The primary published Net::QUIC 0.05 integration CI now exercises **both**
16 and 32 concurrent requests, each with 128 warmup plus 2,048 measured
requests, two isolated rounds, alternating 4/16 KiB complete responses,
and per-256-completion memory and engine-registry checkpoints. This
compares bounded-retention behavior when the pool doubles its active
stream capacity, with no additional native copy/alloc counters. The
32-concurrency scenario is a resource and correctness stress, not a
repeatable throughput claim. Published Net::QUIC 0.05 CI
[39176260513](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39176260513)
PASSED, as did independent optional QUIC-feature CI 39176260525.
At 32 concurrent requests the unified private process memory in KiB
went 7,744 -> 7,900 (round 1) and 7,844 -> 7,860 (round 2);
direct memory went 6,744 -> 6,788 and 6,604 -> 6,716.
At every checkpoint unified ready_transactions stayed between 2 and
13 queue slots, not proportional to completed requests, and the
active engine transaction registry stayed within concurrency.
RSS/PSS also remained nearly flat. These are bounded-retention
observations for this particular callback-driven workload.

CI now also enables `UNBLOCK_H3_PROFILE_ASSERT_BOUNDED=1` for BOTH
the sustained 16- and 32-concurrent profiles. This opt-in diagnostic
requires registry checkpoints, and checks each 256-completion sample:
`ready_transactions <= concurrency+64`, live engine Transactions
`<= concurrency+1`, and no more than 8 MiB of private-memory growth
since measurement began.

The assertions have now passed in primary published-Net::QUIC-0.05
CI [39176739238](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39176739238)
for both the 16- and 32-inflight sustained runs. At 32 inflight,
the guarded run reported unified private memory (KiB)
7,924 -> 7,968 and 7,860 -> 7,972 across its two rounds,
with just two weak notification queue slots left at each
final completion checkpoint. Direct private memory was
6,788 -> 6,940 and 6,756 -> 6,808 KiB. These remain
small versus the earlier roughly 80+ MiB runaway retention. The last is intentionally a generous
regression guard for the original approximately 80+ MiB growth;
it is not a CI throughput performance gate or a universal memory
bound for arbitrary request/response sizes. RSS/PSS/private
memory do not count temporary Perl or native allocations or copies.

A trial uses two fresh child processes: one running the HTTP/3 server and
one running the measured client. They communicate over loopback UDP using
Net::QUIC::Driver. The same Unblock::HTTP::Server definition and response
body are used for both client modes. Direct mode uses Unblock::HTTP3::Client. Unified mode uses
the reusable Unblock::HTTP::Client, its URL parsing, pool scheduler,
and one attached HTTP/3 engine. Neither mode opens extra connections
to increase throughput. Up to the configured number of GET requests
can be outstanding at once.

Warmup must finish before the timed phase begins. Runs alternate
direct-first and unified-first order to reduce ordering bias. **Each
trial forks a client process, which forks a dedicated server process before
creating either event loop, socket or QUIC state.** The server announces
its UDP port through a pipe. After the client validates its last response,
it signals the server to stop; the server reports its request count and any
error before the next trial starts. This prevents one trial's native state
from accumulating in later trials. Both modes validate every buffered
response body and status. A request that does not finish, a wrong payload,
or an unexpected transport error aborts the experiment.

## CPU-only request-dispatch control

`bench/client-dispatch-profile.pl` compares a **ready, reusable**
`Unblock::HTTP::Client` and a direct fake HTTP3 engine with the same
`Uniform::HTTP::Request` implementation. It deliberately stubs only
`Unblock::HTTP3::Client`; the unified Client's URL validation, pool
lookup, operation lifetime tracking, callback adapters and scheduler
are real. Both paths finish a fake transaction and validate
`on_response` and exactly-once `on_finish` counts. Each round
alternates which mode runs first. No real HTTP3 frames, TLS, network,
Net::QUIC, response buffering or body copies take place.

```sh
perl -Iblib/lib -Iblib/arch bench/client-dispatch-profile.pl 20000 7
UNBLOCK_H3_DISPATCH_SPLIT=1 \
  perl -Iblib/lib -Iblib/arch bench/client-dispatch-profile.pl 20000 7
```

With `UNBLOCK_H3_DISPATCH_SPLIT=1`, a separate follow-up
run intercepts the **real** unified `_dispatch` method, the
fake H3 engine `request`, and the three constructors
`URI->new`, `Uniform::HTTP::Request->new`, and
`_ClientOperation->new`. It reports `request_us`,
`outside_dispatch_us`, `dispatch_us`, `fake_engine_us`,
`uri_us`, `uniform_us`, `operation_us` and a
`residual_us` that includes remaining validations, origin/pool
lookup, callback extraction and measurement overhead.
The phase timers wrap every request, and so change its measured CPU
cost. These phase totals are diagnostic and MUST NOT be directly
compared with the uninstrumented medians as if they were the same
measurement.

The full constructor-level diagnostic passed on published Net::QUIC
0.05 CI [39174909939](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39174909939).
All three rounds measured the same 3000 mocked requests/callbacks.
The reported averages in microseconds/request were:

| Measured call/boundary | Round 1 | Round 2 | Round 3 |
| --- | ---: | ---: | ---: |
| Instrumented unified request() | 74.392 | 74.790 | 74.245 |
| URI->new | 10.151 | 10.109 | 9.990 |
| Uniform::HTTP::Request->new | 21.453 | 21.600 | 21.418 |
| _ClientOperation->new | 2.217 | 2.246 | 2.200 |
| Outside dispatch residual | 30.511 | 30.631 | 30.485 |
| _dispatch (including fake request) | 10.059 | 10.204 | 10.153 |
| Fake engine request | 2.010 | 2.015 | 1.991 |

These boundaries show no single justified replacement for canonical URL
and Uniform construction, and the residual includes miscellaneous
validation, callback extraction, origin-key/pool operations and
timing overhead. Constructor timing and enclosing request timing
**overlap**; do not sum each line, assume exact cost attribution, or
infer network/QUIC speedup from this mock.
The complete upper published-0.05 workflow and the separate optional
transport-feature workflow
[39174909923](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39174909923)
were successful.



The pre-constructor-split primary published-Net::QUIC-0.05 integration
workflow [39174402639](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39174402639)
PASS reported three separate CLOCK-INSTRUMENTED rounds:
`request_us` 47.627, 47.523, 47.455;
`outside_dispatch_us` 41.133, 41.041, 41.020;
`dispatch_us` 6.494, 6.483, 6.435;
`fake_engine_us` 1.382, 1.386, 1.361.
The uninstrumented mock medians on the same run were direct 14.445 us
and unified 58.899 us per request/callback cycle. Different instrumentation,
different scope: those totals are **not** interchangeable. This result
motivated constructor-specific timing, not a production optimization
inside the very small fake engine boundary. They include clock and wrapper overhead; the phase
subtractions are approximate. In particular, `outside_dispatch`
includes URI parsing, Uniform construction, operation creation,
origin lookup, and the time spent outside the fast dispatch call.
It is not a direct count of object allocations.

This separates application request/dispatch overhead from real QUIC
transport costs. It is **not** a fair end-to-end direct-vs-unified HTTP3
benchmark, because the dummy engine removes shared engine/transport
work and the direct path does not parse a full URL or perform pooling.
The results are a diagnostic bound/lead, not evidence of a production
speedup or an actual native copy count. The separate
`bench/request-setup.pl` measures Uniform construction and URI
parsing in isolation. Compare this control with the real QUIC workload
before deciding where to optimize.

## Sustained independent-Reader stress

The real-socket `xt/linux-event-quic-six-credit.t` fixture defaults to six
independent 1 MiB streamed HTTP/3 responses plus one independent fast response
on an authenticated QUIC connection. Its 8192-byte native producer threshold,
sequential Reader release, digests, producer fairness, exactly-once completion
and per-stream retention accounting are unchanged.

The same fixture accepts `UNBLOCK_H3_CREDIT_STREAMS` from 6 through 16 and
`UNBLOCK_H3_CREDIT_HOLD_SECONDS` of 0.5 or whole seconds 2..180. Each Reader has its own
32768-byte receive window. The QUIC connection receive window also needs
space for blocked sibling streams and timely connection-wide MAX_DATA
advertisements. The tested bounded defaults are 256 KiB at six, 512 KiB
for seven through twelve, and 1 MiB for thirteen through sixteen streams.
These are configured receive-credit limits, not maximum process memory.

```sh
UNBLOCK_H3_CREDIT_STREAMS=12 UNBLOCK_H3_CREDIT_HOLD_SECONDS=2 \
    prove -v -b xt/linux-event-quic-six-credit.t
UNBLOCK_H3_CREDIT_STREAMS=16 UNBLOCK_H3_CREDIT_HOLD_SECONDS=3 \
    prove -v -b xt/linux-event-quic-six-credit.t
```

To test a prolonged period of withheld Reader credit on one connection,
set `UNBLOCK_H3_CREDIT_HOLD_SECONDS=10` (also supports whole seconds from
2 through 180). This leaves all 12 1 MiB producers attached on the same
connection while their Readers hold per-stream credit, then resumes them
in sequence and checks all payload hashes and callbacks:

```sh
UNBLOCK_H3_CREDIT_STREAMS=12 UNBLOCK_H3_CREDIT_HOLD_SECONDS=60 \
    prove -v -b xt/linux-event-quic-six-credit.t
```

This stresses a sustained **idle/flow-blocked** connection; it is not the
same as continuous 60-second throughput or 60 seconds of active reads. The
extended watchdog accounts for the hold plus bounded completion time.
The CI smoke runs a shorter 10-second held-Reader variant against
published Net::QUIC 0.05.

The previous diagnostic set a 448 KiB connection window for 12 deliberately
credit-held Readers. That fixture reliably stalled, despite each Stream
having its own 32 KiB window and registered QUIC send-capacity waiters.
The sender's connection send credit reached zero. ngtcp2 deliberately
coalesces MAX_DATA increases until sufficient receive credit has been
returned. With eleven other Readers held, the remaining aggregate receive
space was too small to let the one active Reader trigger that update.
Changing only the connection window to 512 KiB made all 12 complete with
the same native budget, payloads and assertions. A 16-Reader case passed
with a 1 MiB connection window. This is a receive-budget configuration
constraint, not evidence that HTTP3 should broadcast ACK wakeups.

For comparative diagnostics, `UNBLOCK_H3_CREDIT_WIDE_CONN_WINDOW=1` uses
a 32 MiB connection receive window. A selected diagnostic window can be
specified using `UNBLOCK_H3_CREDIT_CONN_WINDOW` (458752, 524288, 720896
or 1048576); the 458752-byte case is intentionally below the necessary
headroom for the 12-Reader workload and is not a passing correctness gate.

Published Net::QUIC 0.05 passed the original six-Reader and both expanded
bounded-window regressions in the upper integration CI. A separate
unreleased Net::QUIC feature branch independently corrects an activity
notification when peer MAX_DATA increases, but that fix is not required
for these correctly budgeted HTTP3 workload tests.

These are deterministic forward-progress regressions, not throughput
benchmarks, whole-process memory caps or measured allocation/copy counts.
Hosted CI timing remains descriptive rather than a release performance gate.

## Reading the numbers

- `req/s` and `wall`: measured completions and wall time in the
  post-warmup interval, including host event loop, UDP, TLS and HTTP/3.
- `request_us`: mean time spent inside the synchronous request()
  call; this includes URL/request construction in the unified Client
  and is **not** the full request/response latency.
- `p50_us`, `p95_us`, `p99_us`: time from application submission to
  its on_finish callback, including queuing and network scheduling.
  Percentiles are approximate nearest-rank observations, not
  confidence intervals. Tiny samples make p99 almost meaningless.
- `client_cpu`: measured client-process user plus system CPU seconds for the
  post-warmup interval, including client QUIC/TLS and the client event loop.
  It excludes server-process CPU, but not work charged to the client process
  in the operating system's networking stack.
- `client_rss_start_kib`, `client_rss_end_kib`,
  `client_rss_sample_peak_kib`: sampled client-process Linux
  /proc/self/status VmRSS at start, every 16 measured completions and
  at end. It excludes the separate server process, but shared mappings
  are counted in each process's RSS and it is **not** an allocator
  high-water mark or a reliable bound on transient peaks.

The client and server have separate process CPU clocks and address spaces.
Client CPU and RSS exclude the server process; the **client measurement
still includes the Linux::Event loop, Net::QUIC, TLS, UDP transport and
protocol engine**, and therefore cannot be attributed solely to the
unified library. RSS includes shared library mappings and copy-on-write
pages. End-to-end wall time still depends on the separate server, kernel
and scheduler. The script does not report server CPU/RSS, allocation counts,
Perl object counts, payload copies, nghttp3/QUIC per-stream retained-byte
surfaces, kernel buffers, packet loss, slow readers, streaming response
throughput or multi-origin pooling. The native retained-byte integration tests cover a distinct
part of those questions.

## Memory diagnostics and transport-byte accounting

The profiler now samples client-only Linux smaps_rollup memory **at the start
and end** of the post-warmup phase: \`client_pss_start_kib\`,
\`client_pss_end_kib\`, \`client_private_start_kib\` and
\`client_private_end_kib\`. PSS is proportional resident set size; private
memory is Private_Clean plus Private_Dirty. Values are printed as \`NA\` if
the kernel does not expose smaps_rollup. Neither metric counts allocations,
distinguishes Perl objects from native QUIC/TLS state, nor establishes a
transient maximum. Compare deltas only under otherwise identical conditions.

To count bytes and datagrams crossing the **client QUIC UDP socket boundary**
during the measured phase, enable the opt-in wire counters:

\`\`\`sh
UNBLOCK_H3_PROFILE_WIRE=1 perl -Iblib/lib -Iblib/arch \
    bench/h3-workload-profile.pl 500 80 7 8 4096,262144
\`\`\`

The reported sent/received byte totals include QUIC framing, ACKs, TLS
handshake follow-up traffic and retransmissions in the measured phase.
They do **not** count Perl string copies, borrowed-input copies or bytes
retained by nghttp3/Net::QUIC. This opt-in adds small per-datagram counter
operations; compare wire totals rather than treating its elapsed time as an
uninstrumented performance baseline.

For a snapshot of **live Perl SVs and their references**, the client can
optionally dump its heap at the warmup/measurement boundary and immediately
after the measured phase. Install \`Devel::MAT::Dumper\` separately; it is **not**
a distribution or benchmark-default dependency:

\`\`\`sh
cpanm Devel::MAT::Dumper
mkdir -p /tmp/unblock-h3-heap
UNBLOCK_H3_HEAP_DIR=/tmp/unblock-h3-heap \
    perl -Iblib/lib -Iblib/arch \
    bench/h3-workload-profile.pl 500 80 3 8 4096,262144
\`\`\`

For every direct/unified round, this produces two \`.pmat\` files named with
mode, round, client PID and \`before\`/\`after\`. Review them with
\`Devel::MAT\` analysis tools (separate optional installation). The dumps
describe **retained objects at two instants**, not the number of temporary
SVs allocated/freed in between. Native C heap allocations and kernel
buffers are not included. Heap dumping also perturbs heap state and can
consume substantial CPU/memory; ignore throughput, CPU and RSS
comparisons from heap-dump runs. Do not publish dumps indiscriminately:
they can contain application data, TLS state and strings from memory.

No instrument here can legitimately claim the number of internal
Perl-to-native payload copies. To determine copy counts, a separate
instrumented engine/allocator build or an allocation profiler with a
known scope and control workload would be required. Preserve the
production engine paths while gathering this evidence.

## Same-connection sustained profile and memory checkpoints

For a longer test of **one authenticated QUIC connection per client trial**,
the profiler accepts up to 20,000 measured requests. Warmup is excluded,
and each trial process (and its separate server process) stays alive for the
whole measured interval. A trial is fresh between direct and unified modes,
so inter-trial memory growth is **not** a valid leak indicator. Choose
in-flight concurrency and body sizes so the peer's connection receive
window retains sufficient aggregate headroom.

To sample memory at deterministic completed-request intervals, opt into
`UNBLOCK_H3_PROFILE_CHECKPOINT_EVERY` (0 by default; 64..4096 when enabled).
`UNBLOCK_H3_PROFILE_WATCHDOG_SECONDS` adjusts the independent client and
server watchdogs (60 by default; up to 3600 for a long-running trial):

```sh
UNBLOCK_H3_PROFILE_CHECKPOINT_EVERY=256 \
UNBLOCK_H3_PROFILE_WATCHDOG_SECONDS=600 \
    perl -Iblib/lib -Iblib/arch \
    bench/h3-workload-profile.pl 10000 256 5 16 4096,16384
```

Each `# checkpoint` record contains the client-process completed-request
count, seconds elapsed in the timed phase, interval throughput, number of
in-flight requests at the sampling instant and resident/PSS/private KiB.
Values come from the same child process and QUIC connection across the
measured requests. With the option disabled, there is no added smaps
sampling in the completion callback. Checkpoints **perturb throughput**;
run a separate uninstrumented trial for meaningful relative speed.
Compare repeated checkpoints with the same concurrency and workload,
not absolute RSS values between fresh forked processes. An upward memory
trend does not prove a leak, and flat resident memory does not establish
an absence of temporary Perl or native allocations.

This test continuously exercises buffering and multiplexing. It does not
hold arbitrary response Readers for minutes; that is a separate,
application-specific slow-consumer scenario. Native payload copy counts
remain unknown without source-level instrumentation at the exact copy
boundaries. UDP send/receive counts and retained-heap snapshots are not
substitutes for those counters. CI runs both a 2048-request, two-round instrumented retention smoke
and a 2048-request, three-round uninstrumented comparison; neither
replaces the 10,000-request manual dedicated-host example.

## Completed-Transaction retention fix and verification (October 18, 2026)

The upper Client's operation handle had an ownership cycle:
operation -> Transaction -> on_finish closure -> operation. The closure
also captured Client/pool/connection strongly. Callback-driven HTTP3
response completion therefore retained every finished Transaction while
the connection stayed open, even after the HTTP3 engine had begun using
weak entries for callback-owned pull notifications.

The upper feature branch now uses a strong active-operation registry
until terminal completion, with weak references from engine callbacks
back to the Client/pool/connection/operation. Handles intentionally kept
by the application still expose the **same real** engine Transaction.
The engine fix preserves callback/pull FIFO identity and strongly queued
pull-only entries. Its periodic weak-slot compaction (every 64 callback
insertions) also prevents a live old callback notification from pinning
thousands of expired weak *queue slots* behind it. Neither the active
transaction nor the payload is duplicated in a new wrapper.

Verification was performed against **published Net::QUIC 0.05**, with
the corrected HTTP3 feature commit
`5e0d496bb52331670edc9850d6fa417d984d0e67`, at upper CI
[39172126688](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39172126688).
The workflow completed distribution tests, real-socket TCP/H3 integration,
12/16 independent held-Reader stress including a 10-second hold, and
the deterministic 128-warmup + 2048-measured request profile in each
of two isolated direct and two isolated unified client processes.
All response bodies/statuses/callbacks were validated. The standalone
HTTP3 Perl 5.20/5.28/5.36/5.44 matrix
[39172069382](https://github.com/haxmeister/perl-Unblock-HTTP3/actions/runs/39172069382)
and independent interoperability
[39172069428](https://github.com/haxmeister/perl-Unblock-HTTP3/actions/runs/39172069428)
also passed.

| Client / round | Private KiB at start | Private KiB at end | PSS KiB start -> end | RSS KiB start -> end |
| --- | ---: | ---: | --- | --- |
| Direct / 1 | 6340 | 6416 | 11916 -> 11985 | 26524 -> 26576 |
| Unified / 1 | 7356 | 7480 | 12795 -> 12913 | 27152 -> 27260 |
| Unified / 2 | 7396 | 7436 | 12831 -> 12865 | 27180 -> 27204 |
| Direct / 2 | 6292 | 6364 | 11906 -> 11969 | 26580 -> 26624 |

At **every 256-completion checkpoint** (256..2048, both rounds),
unified HTTP3 `ready_transactions` had only **2 or 3 entries**;
the direct client had 1..5. Unified active HTTP3 transaction registry
was 1..16, streams 7..22, buffered QUIC send bytes 0..240 in this
workload; `ready_informational` was always zero. These figures are
snapshots taken during the completion callback, so one just-finished
transaction can legitimately remain visible. The earlier unbounded
unified `ready_transactions` count 2176 and ~95 MiB private end
footprint are no longer present. Private/PSS/RSS changes across the
2,048 measured requests are small in both modes.

These are **bounded-retention observations for this workload**, not
proof of no leaks for every user application or data size. RSS/PSS/private
do **not** count temporary allocations, native retained payload buffers,
or actual byte copies. User-held operation handles intentionally
retain the completed Transaction and its response by contract.
Unconsumed pull-only notifications remain strongly queued by design.

The memory-checkpoint run reported direct 1553.4 and 1574.1 requests/s
versus unified 1342.7 and 1365.1 requests/s on one hosted runner.
Its 256-completion smaps scans and registry introspection perturb
the timings; **do not use those figures as an API overhead benchmark**.
The matched 2048-request / 128-warmup, 3-round test **without**
optional checkpoint/registry/wire instrumentation passed against
published Net::QUIC 0.05 in upper CI
[39172590547](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39172590547).
Direct rounds delivered 1081.6, 1091.7, 1083.1 requests/s; unified
rounds delivered 998.5, 985.8, 994.3 requests/s. Median wall time was
1.8908 s direct versus 2.0598 s unified (ratio 1.089). Per-round
synchronous request() setup time was 136.30, 136.22, 135.92 microseconds
direct versus 190.52, 194.35, 189.95 microseconds unified.

End-to-end callback latency samples, in microseconds, were:

| Mode / round | p50 | p95 | p99 |
| --- | ---: | ---: | ---: |
| Direct 1 | 8848.9 | 14079.1 | 14632.0 |
| Unified 1 | 9366.0 | 12878.2 | 13964.9 |
| Unified 2 | 8923.1 | 12965.9 | 13721.9 |
| Direct 2 | 8769.0 | 13908.9 | 14315.8 |
| Direct 3 | 8759.0 | 13930.1 | 14559.0 |
| Unified 3 | 8789.1 | 12892.0 | 13344.0 |

All status/body and exactly-once callback validation passed. The
additional optional unreleased Net::QUIC feature diagnostic CI
[39172590469](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39172590469)
also passed, but is not a release dependency. The matched workload
suggests a measurable **request-construction/scheduling** difference at
this concurrency, not an identified individual hot-path cause.
The HTTP3 client remains correct and bounded in the independent
instrumented memory test.

**Do not interpret the 1.089 CI wall-time ratio as a stable overhead
estimate**. All results are single-run hosted Linux CI, with OS scheduling
and native TLS/UDP effects; they are neither dedicated-host repeated
benchmarking nor actual payload-copy/allocation instrumentation.
Request_us is time inside synchronous request(), *not* network latency.
The known audited byte copy sites in HTTP3 and Net::QUIC remain
unmeasured. A controlled dedicated-host profile at fixed versions,
multiple body sizes, equal concurrency, and repeated runs is needed
before deciding whether any native allocation/copy optimization is
worth production complexity.

The remaining measurement task is controlled repeated high-concurrency
latency and throughput on a quiet dedicated Linux machine with a fixed
Perl/XS/QUIC dependency set. Exact native copy/allocate counts would
require temporary counters at the audited copy sites rather than
extrapolating from RSS or UDP wire bytes.

## Comparing results fairly

Use a quiet, otherwise idle machine, a fixed Perl/XS/QUIC stack and
repeat several rounds. Compare the median and variation of both
modes for each **identical response size and concurrency**. Do not
compare different settings to claim an overhead or speedup. Report
full parameters, architecture, operating system, library versions
and the raw per-round results. Run again on multiple days or machines
before making quantitative performance claims.

GitHub Actions performs short correctness/smoke runs only. Hosted
runner CPU and memory scheduling vary; its timing numbers are useful
to spot obvious issues, not sufficient for a regression threshold.

Related: `bench/client-vs-direct.pl` covers HTTP/1.1 and HTTP/2 over
TCP; `xt/linux-event-quic-multi-credit.t` tests independent QUIC
receive credit, and `xt/linux-event-quic-join-cancel.t` checks
producer lifecycle under backpressure.
