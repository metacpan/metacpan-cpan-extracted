# Performance plan

Unblock::WebSocket is portable, but portability is not permission to add an
unavoidable Perl copy at every transport boundary.

## Baseline

Linux::Event::WebSocket already has a native bq_websocket implementation with
real application-path measurements. Those results are the extraction baseline,
not disposable historical data.

The comparison suite for Unblock should retain equivalent cases for:

- small text messages (64 and 256 bytes);
- 1 KiB messages;
- 16 KiB messages;
- binary traffic;
- mixed Unicode text;
- 20, 100, 500, and 1000 connections where applicable;
- broadcast fan-out;
- request windows of 1, 4, and 16.

## Three integration levels

### Portable Perl path

    transport bytes -> input() -> protocol engine
    output() -> transport write

This is the stable public contract and the correctness baseline.

### Efficient framework adapter

Framework adapters can minimize copying and drain output in useful chunks while
still using the public Perl API.

### Native adapter

XS-capable transports can drive the same native engine through the private
versioned adapter ABI:

    borrowed native input buffer
        -> native WebSocket parser
        -> completed message callback

Raw input does not need to become a temporary Perl scalar.

Native output similarly should be available as a borrowed buffer or through a
host output submission callback so an adapter can avoid:

    native frame buffer -> Perl SV -> native transport buffer

## Required measurements

Development should record at least four checkpoints:

1. current Linux::Event::WebSocket native baseline;
2. standalone Unblock portable engine;
3. Linux::Event adapter using the portable byte API;
4. Linux::Event adapter using the private native ABI.

The difference between checkpoints 3 and 4 measures recoverable adapter cost.
The difference between checkpoints 1 and 4 measures whether extraction changed
the optimized architecture.

## Optimization rule

Do not optimize by leaking Linux::Event objects into Unblock::WebSocket.
Optimize the generic native boundary instead. If another XS transport can use
the same facility, it belongs in Unblock. If it requires Linux::Event Stream
state, it belongs in the Linux::Event adapter.


## Standalone message-path benchmark

The repository-only bench/message-path.pl benchmark compares the same public
client-to-server application message path across four engine configurations:

- Perl framing;
- native bq framing;
- Perl framing plus permessage-deflate;
- native bq framing plus the same shared permessage-deflate codec.

It measures steady-state established traffic after a short warmup. The
compression comparison keeps the DEFLATE implementation constant so the
difference between the compressed Perl/native cases primarily exposes framing,
masking, parsing, and boundary overhead.

The default application payload sizes are 64 B, 256 B, 1 KiB, and 16 KiB.
These results should be used as same-run relative measurements. Absolute
GitHub-hosted runner numbers are not release claims.


## Current benchmark result

A GitHub-hosted Linux runner was used for one same-run comparison on
2026-10-04. These numbers are development measurements, not hardware-independent
release claims.

    path                      bytes     messages/s payload MiB/s
    perl                         64          21759         1.33
    native                       64         108907         6.65
    perl+deflate                 64          37302         2.28
    native+deflate               64          66067         4.03

    perl                        256           8118         1.98
    native                      256         108952        26.60
    perl+deflate                256          35374         8.64
    native+deflate              256          59939        14.63

    perl                       1024           2341         2.29
    native                     1024         105801       103.32
    perl+deflate               1024          26996        26.36
    native+deflate             1024          42779        41.78

    perl                      16384            153         2.40
    native                    16384          68236      1066.19
    perl+deflate              16384           5629        87.95
    native+deflate            16384           6502       101.60

The important comparison is same-run relative behavior. Native framing provides
a large improvement for uncompressed traffic and remains beneficial when the
shared permessage-deflate codec is enabled. The native-compression gain becomes
smaller as payload size grows because DEFLATE itself accounts for more of the
total work.


## Attached output versus manual output

The repository-only bench/attached-path.pl runs a paired same-process comparison
of the manual output() drain and the optional transport => $host path.

It uses a minimal host accepting complete buffers immediately, payloads of
64 bytes and 1024 bytes, and both Perl and native protocol backends when XS
is available. The workload deliberately isolates outgoing message framing and
buffer handoff; it is not an end-to-end network latency test.

Run it from a built repository checkout (bench/ is not shipped to CPAN):

    perl -Mblib bench/attached-path.pl 10000

The Linux CI test workflow records same-run results using 5000 measured
messages after a 1000-message warmup for each case.

Attached output has an additional host-method call and a transport-mode branch.
Its value is simpler adapter code and automatic output from delayed callbacks,
not an inherent speed improvement over direct native buffer ownership.

The existing private native adapter ABI remains the lower-overhead path for
native consumers that cannot afford Perl object and byte-buffer round trips.
It was not modified by the attached-transport feature.


### First attached-path measurement (2026-10-11)

Measured on the same GitHub-hosted Linux job (5000 iterations each, same
process, no network or compression). Numbers are development observations,
not stable promises or a replacement for full native-adapter benchmarking.

    backend  size    manual msg/s   attached msg/s   difference
    perl      64 B       172426           150757       -12.6%
    perl    1024 B       167853           148809       -11.3%
    native    64 B       260280           221867       -14.8%
    native  1024 B       254803           216328       -15.1%

Attached mode does introduce measurable extra Perl dispatch and state work
versus the shortest manual output loop. It is intended for easy host
integrations; latency-sensitive native adapters should use the existing
private native ABI. More runs and a workload with real network scheduling
are needed before treating these ratios as general performance results.
