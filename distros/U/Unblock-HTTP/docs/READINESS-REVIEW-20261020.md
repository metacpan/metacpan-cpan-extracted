# Integration readiness review - October 20, 2026

Scope: haxmeister/perl-Unblock-HTTP on feature/high-level-client-server
and the existing read-only engine feature branches. This is a correctness
and developer-experience review, NOT a release audit or release plan.
Do not modify main, merge, tag, or bump versions as part of this review.

## Confirmed implementation coverage

| Application operation | HTTP/1.1 | HTTP/2 | HTTP/3 |
| --- | --- | --- | --- |
| Ordinary buffered/streamed Client and Server | Implemented | Implemented | Implemented |
| Server WebSocket | 101 Upgrade | 200 Extended CONNECT | 200 Extended CONNECT |
| Client connect_websocket | 101 Upgrade | 200 Extended CONNECT | 200 Extended CONNECT |
| Socket/stream ownership | Whole socket switches consumer | One H2 request stream | One QUIC H3 request stream |
| WebSocket output | Existing ordered socket queue | Per-stream deferred writer | Per-stream deferred writer |
| Peer Extended CONNECT setting | Not needed | Required before CONNECT | Current peer SETTINGS required |
| Peer stream-credit gate | One H1 operation per socket | H2 transaction credit | H3 QUIC bidi-stream credit |
| Request cancellation | H1 transaction / WebSocket | Stream-local cancellation | Stream-local cancellation |

Successful in-memory H1/H2 and real localhost QUIC/TLS H3 Client+Server
tests are in the distribution suite. The H3 Client milestone passed
both full integration workflows at source
a3f429edf66562a55ab23e0d5b55a8e3eb989b7c:
published Net::QUIC run 39516674510 and optional MAX_DATA
run 39516674529, 29 test files / 1,170 checks. No throughput
improvement is inferred from the diagnostic smokes.

The existing Linux::Event integration suite exercises live TCP and QUIC
sockets and output/backpressure semantics, but is not proof of
interoperability with external browsers or frameworks. A focused live H1 Upgrade/H2 prior-knowledge WebSocket regression
(xt/linux-event-websocket.t) is now fully CI VERIFIED in both
published Net::QUIC and optional MAX_DATA tracks at source
c3c1bc53122520134dea8c8319b6c7c19e6d6611:
https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39525139986
and https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39525139977.
The live Linux::Event integration step passed 14 test files and
702 checks, including 16 new H1/H2 WebSocket live-socket checks.

## TLS/ALPN H2 WebSocket milestone

New `xt/linux-event-websocket-tls.t` creates a short-lived localhost
certificate with OpenSSL, configures a Linux::Event TLS listener that
advertises h2 ALPN, and starts a real TLS Client with certificate
chain/hostname verification. It checks the negotiated h2 ALPN on both
ends, one pooled encrypted TCP socket, an RFC 8441 WebSocket echo over
HTTP2 DATA, an ordinary HTTP2 response, Close/END_STREAM and
transaction cleanup. This is a *live encrypted socket integration*,
not a standalone peer interoperability result.

BOTH full integration workflows PASSED the authenticated TLS/ALPN
test (15 Linux::Event files, 719 checks; 29 distribution files and
1,170 checks), along with example syntax checks and the established
live TCP/QUIC/resource/diagnostic smoke steps:
- Published Net::QUIC 0.05:
  https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39530067422
- Optional QUIC MAX_DATA:
  https://github.com/haxmeister/perl-Unblock-HTTP/actions/runs/39530067425

The exact verified production/test source is
afdb47d578995d56ba0b4d201a4b663714b61c99.
Neither run proves interoperability with external WebSocket peers.

## Application and adapter examples

- examples/linux-event-websocket-server.pl: one app definition, real
  Linux::Event adapter, H1 default or H2 prior knowledge by environment.
- examples/linux-event-quic-websocket-server.pl: one H3 app definition,
  QUIC/TLS server manager, one Linux::Event UDP socket and timer.
- examples/linux-event-websocket-client.pl: shared H1/H2 Client,
  event-loop TCP connection factory, socket-consumer handoff and
  application-only WebSocket callbacks; cleartext local demo.
- docs/WEBSOCKET-COOKBOOK.md: commands, app-versus-adapter separation,
  TLS caveats, Client invocation, ownership checklist.
- lib/Unblock/HTTP/Integration.pm: the event-loop-neutral contract.
- Both full CI workflows now compile-check all shipped example programs.
  This only verifies that imports and syntax work, not runtime behavior.

The application handlers see the original HTTP Transaction and the
actual WebSocket session. The adapter does not parse HTTP or WebSocket.
H2/H3 defer callbacks MUST schedule a later event-loop turn.

## Remaining integration/readiness gaps

1. **Coordinated branches are not a release set.** The upper module's
   Makefile.PL declares minimum released engine versions, but its
   receive/lifecycle and WebSocket integration use coordinated engine
   feature-branch APIs. Simply installing the minimum published versions
   does not establish the required feature contract. Current CI
   explicitly pins those branches. Do not present this feature branch
   as ready to install independently from CPAN.
2. **Native H1 input ownership remains framework-specific.** A
   borrowed-input provider that receives INPUT_SWITCH must feed the
   unconsumed suffix into the successor WebSocket consumer exactly once.
   The ordinary Perl input path and a native transition test exist,
   but the upper layer cannot access an external native provider's
   borrowed window without its cooperation.
3. **Independent peer interoperability remains unverified.** H2 now has
   Linux::Event real TLS + OpenSSL with server certificate/hostname
   validation and selected h2 ALPN, alongside the prior-knowledge
   cleartext WebSocket test. The TLS regression exercises the unified
   Client and Server against each other and has passed the optional
   QUIC CI workflow (published-Net::QUIC track also scheduled). H3
   likewise runs full QUIC/TLS with this project's engines. These
   successes are NOT evidence of WebSocket RFC 8441/9220 interoperation
   with an independent third-party HTTP implementation.
4. **Connection factories remain framework callbacks.** A runnable
   Linux::Event shared Client example now covers local H1/H2 TCP
   sockets. A generic framework-independent TCP/TLS connector and a
   standalone application H3 Client QUIC/TLS factory are still not
   shipped. Do not imply that `connect_websocket` creates sockets
   without adapter code.
5. **Deliberately absent features.** Cross-host Alt-Svc routing, DNS
   HTTPS record discovery, post-dispatch replay and automatic protocol
   downgrade for explicit WebSocket version selection are not supplied.
   They are not required for the currently approved callback-first API.

## Next small, useful steps

Example compilation and the live H1/H2 WebSocket regression
have now passed both full CI tracks. The shared-Client TCP factory
example has also been added and compile checked. Next,
test an independent RFC8441/9220 Extended CONNECT peer if a
compatible implementation is available. The remaining developer
experience opportunity is a standalone H3 QUIC/TLS shared Client
factory example, following the already verified t/36 harness. Do not start a broad profiling or release campaign.

Dependencies explicitly remain read-only: Unblock::HTTP1/2/3,
Unblock::WebSocket, Uniform::HTTP and Net::QUIC. All implementation
writes stay on the upper feature branch. Recheck Handoff.md and
CI results before further changes.
