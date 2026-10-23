# WebSocket cookbook

Unblock::HTTP 0.02 implements the same application-facing
WebSocket callback model on HTTP/1.1, HTTP/2 and HTTP/3. The protocol engines,
WebSocket codec, QUIC transport and host event loop stay separate.

The examples in this cookbook have two distinct parts:

- APPLICATION CODE configures one Server and its HTTP/WebSocket callbacks.
- ADAPTER CODE owns sockets, TLS/ALPN, UDP, timers and ordered output queues.

The Server definition is reusable across connections. Its callbacks receive
real engine Transactions. No extra HTTP protocol parser is needed.

## 1. Run an HTTP/1.1 WebSocket echo server

Working example: [examples/linux-event-websocket-server.pl](../examples/linux-event-websocket-server.pl).

After installing Unblock::HTTP1 0.12+, Unblock::HTTP2 0.12+,
Unblock::HTTP3 0.13+, Unblock::WebSocket and Linux::Event, run:

    perl -Iblib/lib examples/linux-event-websocket-server.pl 8080

Ordinary HTTP:

    curl http://127.0.0.1:8080/

A client supporting HTTP/1.1 WebSocket Upgrade can connect to:

    ws://127.0.0.1:8080/ws

The application callback receives each text/binary frame and echoes it.
Other HTTP paths continue to receive regular HTTP 200 responses; a WebSocket
attempt to a path other than /ws receives HTTP 403.

The adapter is a tiny Linux::Event Stream subclass. It calls the unified
Server's attach_stream once, forwards TCP input, and switches the existing
socket's input consumer after the HTTP1 101 response is queued. No second
socket or independent HTTP response queue is created.

## 2. Serve WebSocket over HTTP/2

Use the SAME example on a cleartext, H2 prior-knowledge port:

    UNBLOCK_HTTP_PROTOCOL=h2 perl -Iblib/lib examples/linux-event-websocket-server.pl 8081

Check ordinary HTTP/2 traffic:

    curl --http2-prior-knowledge http://127.0.0.1:8081/

A WebSocket over H2 needs a client with RFC 8441 Extended CONNECT support.
An ordinary HTTP/1.1 Upgrade client cannot connect to this H2 port. This
example's cleartext listener is for local prior-knowledge integration, not
a production secure WebSocket endpoint. For production, configure TLS and
advertise h2 with the Server's alpn_protocols via the host framework.

When the Server has http2 => { websocket => 1 }, it advertises
SETTINGS_ENABLE_CONNECT_PROTOCOL. Successful WebSocket CONNECT returns HTTP
200, not 101. Only that H2 stream becomes a WebSocket. Other streams on the
same TCP/TLS connection remain regular HTTP requests. Output frames are
written through the existing H2 Transaction after the framework's defer
callback schedules a later event-loop turn. Do not call defer callbacks
synchronously from the parser.

A real H2 Client+Server regression is in t/33-client-websocket-h2.t;
t/34-client-websocket-h2-lifecycle.t covers rejected handshakes, resets
and shutdown. They use actual HTTP2 and WebSocket engines.

### Verify authenticated HTTP/2 with TLS/ALPN

The real Linux::Event integration test
`xt/linux-event-websocket-tls.t` also covers **encrypted** HTTP/2,
rather than only the cleartext prior-knowledge listener above. After installing the released engines and Linux::Event, run:

    prove -v -b xt/linux-event-websocket-tls.t

The test creates a temporary OpenSSL localhost certificate, verifies
its chain and hostname on the Client, checks negotiated `h2` ALPN
on BOTH TLS peers, then performs an HTTP/2 WebSocket echo and an
ordinary HTTP request on the same pooled encrypted connection.
The temporary certificate is for test-local trust only. This
validates the project's HTTP/2 peers over secure sockets; it does
not demonstrate interoperability with an independent third-party
Extended CONNECT implementation.

## 3. Serve WebSocket over HTTP/3 and QUIC

Working example:
[examples/linux-event-quic-websocket-server.pl](../examples/linux-event-quic-websocket-server.pl).

Create a short-lived LOCAL testing certificate:

    openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
        -subj /CN=localhost \
        -addext subjectAltName=DNS:localhost,IP:127.0.0.1 \
        -keyout /tmp/unblock-local.key -out /tmp/unblock-local.crt

Run the QUIC/TLS endpoint:

    perl -Iblib/lib examples/linux-event-quic-websocket-server.pl \
        127.0.0.1 4433 /tmp/unblock-local.crt /tmp/unblock-local.key

It serves ordinary HTTP/3 on / and WebSocket Extended CONNECT on /ws.
Use an HTTP/3 WebSocket client that supports RFC 9220, authenticates the
hostname and trusts this development certificate. The URI is:

    wss://localhost:4433/ws

Do not disable TLS certificate verification in real applications. The
example binds the concrete loopback address deliberately.

The application code is the same on HTTP/3 as on HTTP/2. The adapter
code holds ONE UDP socket and a replaceable timeout. Net::QUIC::Driver
handles datagrams and QUIC timers; Unblock::HTTP::QUIC attaches ready
connections to the shared Server. No application callback manually
manipulates QUIC streams or forwards WebSocket frames.

The full real-QUIC Client+Server regression is
t/36-client-websocket-h3.t. It verifies peer SETTINGS, multiple WebSockets,
concurrent normal H3 requests, denial, Close and shutdown. The separate
t/37-client-h3-websocket-admission.t tests unsupported peer SETTINGS
and QUIC stream-credit exhaustion without extra connections.

## 4. Run an application-facing WebSocket Client

Working example:
[examples/linux-event-websocket-client.pl](../examples/linux-event-websocket-client.pl).

Against the H1 server from section 1:

    perl -Iblib/lib examples/linux-event-websocket-client.pl 127.0.0.1 8080 1.1

Against the H2 prior-knowledge server from section 2:

    perl -Iblib/lib examples/linux-event-websocket-client.pl 127.0.0.1 8081 2

This example separates its application callbacks from the Linux::Event
TCP transport factory and per-socket consumer. It sends one text message,
prints the echo, and closes the WebSocket. These two commands are
CLEAR-TEXT local test examples; for production WSS the framework
must establish authenticated TLS and select the negotiated ALPN.
The H3 path uses a separate QUIC factory, as in the real-QUIC
t/36-client-websocket-h3.t integration test.

The same method works for all three protocols. Choose only a protocol
you enabled on the Client constructor:

    my $operation = $client->connect_websocket(
        url => 'wss://example.com/chat',
        http_version => '3',
        on_open => sub {
            my ($ws, $http_tx) = @_;
            $ws->send_text('hello');
        },
        on_message => sub {
            my ($ws, $payload, $type) = @_;
            print "$payload\n" if $type eq 'text';
        },
        on_error => sub {
            my ($object, $reason) = @_;
            warn "$reason\n";
        },
        on_finish => sub {
            my ($http_tx) = @_;
            # The H2/H3 HTTP transaction has now become terminal.
        },
    );

The constructor requires event-loop connection factories, not independent
per-protocol Client objects. For HTTP/1 and HTTP/2, connect_stream creates
a TCP/TLS host and calls its ready callback with transport and ALPN. For
HTTP/3, connect_quic creates an authenticated QUIC connection and calls
ready with connection. The framework must keep those transports/engines
alive, feed the original network input to the proper engine, and provide
an asynchronous defer callback. The factory contracts are fully described
in perldoc Unblock::HTTP::Integration and perldoc Unblock::HTTP::Client.

For H2 and H3 the Client waits for the CURRENT peer Extended CONNECT
SETTINGS before submitting WebSocket CONNECT. It never downgrades an
explicit http_version selection. The WebSocket and ordinary requests
can share one multiplexed connection; closing one WebSocket does not
close unrelated streams. H3 QUIC stream-credit starvation requeues the
same unsent operation without reconnecting or replaying bytes.

The return value is an operation handle. transaction() is the actual HTTP
Transaction after dispatch, websocket() is the actual established
Unblock::WebSocket::Client after a successful handshake, and state(),
error() and cancel() work throughout its lifecycle.

## 5. Adapter ownership checklist

- HTTP/1: ensure the original HTTP 101 is accepted into the ordered
  socket output queue BEFORE transferring the input consumer. Transfer
  native borrowed input leftovers exactly once.
- H2/H3: do not replace or detach the socket/QUIC connection after
  Extended CONNECT. One WebSocket session uses one request stream.
- Queue all outgoing WebSocket frames via the stream-local deferred
  bridge; never reenter the protocol parser from an input callback.
- A false unblock_send/write result indicates the COMPLETE buffer was
  accepted but output is congested, not that zero bytes were accepted.
- Propagate transport errors, EOF, and stream cancellation to the correct
  owner; do not manufacture a protocol failure for an intentional reset.
- If a handshake is denied, discard its ordinary HTTP error-response
  body and do not call the ordinary HTTP request-end responder again.
- Client shutdown retires H2/H3 pool entries only after their active
  request streams complete. HTTP1 upgraded sockets are no longer owned
  by the HTTP pool.

All working examples use Linux::Event as an OPTIONAL host. Core Unblock::HTTP
has no Linux::Event dependency and can use other event loops implementing
the same transport callbacks.
