# Unblock::HTTP3 0.14

This maintenance release fixes HTTP/3 CONNECT transaction completion when
the final outgoing body write finishes synchronously.

## What changed

- Recheck Transaction completion after the outgoing Body::Stream is marked
  complete, even when its final write flushes immediately.
- Ensure completed CONNECT exchanges deliver on_complete and on_finish
  exactly once without requiring another QUIC/network event.
- Preserve stream ownership, callback ordering, and the existing HTTP/3
  application and transport APIs.
- Add a real UDP/QUIC/TLS CONNECT completion regression test.

## Compatibility

- Perl 5.20 or newer.
- Alien::nghttp3 0.01, Net::QUIC 0.05, Uniform::HTTP 0.06 or newer.
- Native HTTP/3 consumer ABI remains version 1.
- No public API changes or framework-specific dependencies.

## Verification

The 0.14 release candidate passed standalone tests on Perl 5.20, 5.28,
5.36, and 5.44, including the real QUIC/TLS CONNECT regression.
Distribution and PAUSE-indexing checks, installed native-header tests,
independent HTTP/3 interoperability, and Linux::Event smoke tests also
passed.
