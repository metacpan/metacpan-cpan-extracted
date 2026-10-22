# HTTP/3 native payload boundary audit

This is a **static source audit** of the unreleased HTTP3 0.13 feature and
released Net::QUIC 0.05. It identifies byte-copy operations and borrowed
windows; it does **not** claim measured allocation counts or copies per
request. No production API or hot-path instrumentation was added.

## Incoming HTTP/3

1. `Net::QUIC` receives/decrypts UDP packets and exposes stream data to the
   HTTP3 engine. The exact native allocations and copies made by ngtcp2,
   TLS and its receive buffering have **not** been counted by this audit.
2. In `Unblock::HTTP3::Native`, `HTTP3.xs::read_stream` uses
   `SvPVbyte(bytes, len)` and passes its pointer directly to
   `nghttp3_conn_read_stream2`. This is a borrowed Perl byte pointer at
   that call boundary, *not* an explicit `memcpy` there. The lifetime
   and downstream nghttp3 processing still need to be respected.
3. `HTTP3.xs::unblock_http3_recv_data_cb` creates a Perl scalar using
   `newSVpvn(data, datalen)`. This **copies** the delivered DATA
   callback bytes into a Perl-owned scalar event. The number of callbacks
   per application body is not constant.
4. `Body::Reader::_push_owned` queues its existing Perl `$bytes` scalar
   without an explicit byte-buffer copy in that method.
   `next_chunk` shifts the queued scalar and returns flow-control
   credit. `_Bytes::byte_string` stringifies and validates input
   when that helper is called; Perl copy-on-write and encoding state
   make its real allocation cost an open question.

## Outgoing HTTP/3

1. `HTTP3.xs::unblock_http3_body_append` makes a Perl scalar with
   `newSVsv(body_sv)` and retains that scalar for a native body chunk.
   The underlying bytes may be shared by Perl copy-on-write; **do not**
   count this function as an unconditional full-body copy.
2. `HTTP3.xs::next_write` obtains up to 16 `nghttp3_vec` elements per
   call from `nghttp3_conn_writev_stream` and appends every element to
   a Perl scalar with `sv_catpvn`. Each element's bytes are copied into
   that output scalar. Concatenation may also cause capacity growth,
   which is not separately measured here.
3. `Connection::_drain_output` passes the scalar to
   `Net::QUIC::Stream->send_some($bytes, limit_to_credit => 1)`.
   Released Net::QUIC 0.05 uses
   `xs/net_quic_stream.h::net_quic_stream_queue_data` to allocate native
   transmit chunks and `memcpy` every accepted prefix into retained
   chunk buffers. Partial admissions, retries and flow credit determine
   how many calls occur. An already accepted prefix is never replayed
   by HTTP3.

At a minimum, the **named explicit copy operations** on the ordinary
outgoing path are nghttp3-vectors-to-Perl `sv_catpvn` and
Perl-to-QUIC-native `memcpy`, for the bytes that travel through those
boundaries. This is **not** a total-copy count: QUIC packet generation,
TLS, socket syscalls, canonical message construction and allocations
inside either C library are outside these observations.

## Measurements we already have

The upper feature's `bench/h3-workload-profile.pl` measures one live,
authenticated QUIC connection per isolated trial and can compare
direct-vs-unified buffered response handling. RSS, PSS and private
memory are observed at warmup and completion; opt-in checkpoints
(`UNBLOCK_H3_PROFILE_CHECKPOINT_EVERY`) expose trends during thousands
of validated responses without changing the production engines.
`UNBLOCK_H3_PROFILE_WIRE=1` counts datagrams and bytes crossing the
client UDP transport. An optional `Devel::MAT::Dumper` captures retained
Perl heap snapshots, **not** allocation rate or native buffers.

## Next controlled native instrumentation experiment

If exact payload copy volume becomes necessary, instrument **each known
copy site**, with separate counters for event `newSVpvn`, outgoing
`sv_catpvn`, and QUIC transmit `memcpy`, gated by an explicit
profile-only build mode. Report both *calls* and *bytes*, and distinguish
native allocations from copies. Verify with two-body-size test vectors,
partial accepts, streaming Readers and one empty-body control.

Such instrumentation is **not present** in the release candidate. It
would require coordinated build/test changes to independent Net::QUIC;
do not insert an HTTP-specific dependency into Net::QUIC, permanent
branches into its receive/send hot paths, or a public debugging ABI
solely for this experiment.

Documented against:
- Unblock::HTTP3 0.13 feature `HTTP3.xs`,
  `lib/Unblock/HTTP3/Connection.pm`,
  `lib/Unblock/HTTP3/Body/Reader.pm`.
- Published Net::QUIC 0.05 `xs/net_quic_stream.h` and `QUIC.xs`.

