# Hosted HTTP3 paired sweep - October 19, 2026

This is a retained, **exploratory** snapshot of the full real-QUIC
diagnostic workflow
[39269889496](https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39269889496),
not a quiet-host benchmark, performance gate or performance promise.

- Tested upper commit: 115b0b685934a3879ee6d7c5aa24375f5e91969c
- Fixed dependencies: Net::QUIC 0.05 (published CPAN);
  Linux::Event 0.117; HTTP1 feature bb8349e, HTTP2 feature 51fb1ad,
  HTTP3 feature 6687bce
- Two independently launched complete real-QUIC sweeps on the same
  GitHub-hosted Ubuntu 24.04 runner
- Every case: 2048 measured / 128 warmup / 7 round-paired
  direct vs unified HTTP3 observations
- Pass B rotated the ten workload pairs by five and reversed
  cycled vs unique URL pattern order
- Number of cases: 20; wall-ratio direction reversals: 2
- The median ratio here is the median *within-round* unified/direct
  wall-time ratio, not a ratio of independent wall-time medians.
  Larger than 1 means unified Client took more time.
- Client CPU ratios are independent metrics. Setup differences are
  unified minus direct synchronous request call duration in us,
  not end-to-end latency or wall-time overhead.
- Exact per-trial JSON and logs were uploaded as the 30-day
  workflow artifact h3-seven-round-hosted-diagnostics
  (artifact ID 12198069225).

## Per-scenario observations

The ratio interval is the full min..max range of seven round-paired
wall ratios, **not** a confidence interval.

| Case | Pass A wall (range) | Pass B wall (range) | A/B CPU ratio | A/B setup delta (us) |
|---|---:|---:|---:|---:|
| c01-b1024-cycled | 1.1107 (1.0991..1.1280) | 1.1042 (1.0802..1.1259) | 1.1545/1.1329 | 75.00/71.61 |
| c01-b1024-unique | 1.1155 (1.0876..1.1235) | 1.1039 (1.0978..1.1357) | 1.1588/1.1372 | 73.39/74.31 |
| c01-b4096-16384-cycled | 1.0357 (1.0309..1.0430) | 1.0425 (1.0156..1.0479) | 1.0413/1.0473 | 64.30/73.90 |
| c01-b4096-16384-unique | 1.0393 (1.0262..1.0588) | 1.0307 (1.0226..1.0728) | 1.0449/1.0370 | 66.30/73.40 |
| c01-b65536-cycled | 1.0306 (1.0061..1.0510) | 1.0333 (1.0181..1.0551) | 1.0309/1.0282 | 91.26/105.71 |
| c01-b65536-unique | 1.0320 (1.0189..1.0388) | 1.0328 (1.0210..1.0446) | 1.0223/1.0218 | 94.41/95.42 |
| c08-b1024-cycled | 1.0025 (0.9817..1.0151) | 0.9798 (0.9611..1.0206) | 1.0267/1.0161 | 65.51/69.52 |
| c08-b1024-unique | 0.9816 (0.9295..1.0116) | 0.9864 (0.9584..1.0419) | 1.0147/1.0210 | 63.54/66.10 |
| c08-b4096-16384-cycled | 1.0304 (1.0252..1.0893) | 1.0626 (1.0374..1.1259) | 1.0302/1.0624 | 65.68/72.25 |
| c08-b4096-16384-unique | 1.0774 (1.0343..1.1156) | 1.0854 (1.0498..1.0928) | 1.0774/1.0853 | 69.77/88.04 |
| c08-b65536-cycled | 1.0108 (0.9888..1.0235) | 1.0062 (0.9890..1.0436) | 1.0109/1.0059 | 78.25/93.48 |
| c08-b65536-unique | 1.0279 (0.9928..1.0552) | 0.9999 (0.9971..1.0388) | 1.0280/1.0000 | 84.08/80.61 |
| c16-b1024-cycled | 0.9616 (0.9380..0.9897) | 0.9578 (0.9147..1.0019) | 1.0034/1.0001 | 63.44/59.60 |
| c16-b1024-unique | 0.9550 (0.9485..1.0106) | 0.9615 (0.9405..1.0392) | 1.0022/1.0014 | 62.28/66.79 |
| c16-b4096-16384-cycled | 1.0661 (1.0117..1.0828) | 1.0504 (1.0190..1.0833) | 1.0664/1.0504 | 67.02/73.55 |
| c16-b4096-16384-unique | 1.0646 (1.0223..1.0837) | 1.0704 (1.0493..1.0895) | 1.0652/1.0704 | 65.48/73.13 |
| c32-b1024-cycled | 0.9656 (0.9426..0.9954) | 0.9669 (0.9456..1.0136) | 1.0035/1.0026 | 61.41/66.57 |
| c32-b1024-unique | 0.9638 (0.9465..1.0237) | 0.9662 (0.9483..0.9895) | 0.9964/0.9959 | 60.26/67.48 |
| c32-b4096-16384-cycled | 1.0662 (1.0389..1.0956) | 1.0441 (0.9948..1.0775) | 1.0662/1.0440 | 67.24/71.07 |
| c32-b4096-16384-unique | 1.0473 (1.0302..1.0889) | 1.0759 (1.0386..1.0881) | 1.0473/1.0758 | 68.57/72.23 |

## Interpretation boundaries

The 1-KiB tests at 16/32 concurrency frequently had unified wall
ratios below 1 while client CPU ratios remained approximately 1:
that is not evidence of less CPU work. The 4/16-KiB cases showed
around 4-8% higher unified wall time in many scenarios, but shared
host load, OS scheduling, TLS/QUIC processing and execution order
all influence the result. Two workloads crossed ratio 1 between
sweeps, reinforcing that a single run can mislead.

The original comparator printed pooled private-memory process-size
deltas across direct and unified trials. **Those pooled values are
not retained here**, because they do not provide a valid comparison
of the two modes. The follow-up comparator at source 09396c3
separates RSS/PSS/private start/end changes for each mode, but
this original workflow used the old comparator. Raw per-trial JSON
remains the source for a corrected post-hoc memory comparison.
Neither process memory nor wall-time ratios count native memcpy,
malloc operations or retained Perl SVs.

No production Client, HTTP3 engine or Net::QUIC optimizations
were made in response to these hosted measurements. Before
selecting a hot-path change, repeat the identical matrix on a
quiet controlled Linux host and inspect CPU, request setup,
latency and memory independently.
