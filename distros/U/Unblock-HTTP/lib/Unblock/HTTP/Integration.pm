package Unblock::HTTP::Integration;

use strict;
use warnings;

our $VERSION = '0.02';

1;

__END__

=head1 NAME

Unblock::HTTP::Integration - Attach framework transports to HTTP engines

=head1 IMPLEMENTATION STATUS

Unblock::HTTP 0.02 supplies reusable Server policy, direct engine
attachment, and the shared pooled Client with buffered or streamed callbacks.
It requires Unblock::HTTP1 0.12, Unblock::HTTP2 0.12, and Unblock::HTTP3 0.13
or newer. HTTP1 Upgrade and HTTP2/HTTP3 WebSocket Extended CONNECT are
implemented for Client and Server; H3 exchanges are tested over real QUIC/TLS.
Authenticated same-host Alt-Svc and unsent connection fallback are
implemented. Cross-host Alt-Svc, post-dispatch retries and generic
framework-managed connection factories remain outside this layer.
See docs/IMPLEMENTATION.md for current implementation status.

=head1 TCP AND TLS SERVERS

Create one L<Unblock::HTTP::Server> definition for the service. Configure the
framework listener's TLS ALPN choices using C<$server-E<gt>alpn_protocols>.
The framework owns listeners, sockets, TLS, timers, and network queues.

For each accepted connection, retain the actual returned engine:

    $self->{http} = $server->attach_stream(
        transport => $self,
        alpn => $negotiated_alpn,
    );

The adapter passes decrypted bytes directly to that engine. There is no
Server-definition call on the read path:

    $self->{http}->input($bytes);
    $self->{http}->input_eof;
    $self->{http}->transport_error($error);

Call C<input_eof> once when the peer's read side ends. The framework must not
continue feeding a closed engine. Constructor and attachment errors belong
to adapter setup; handle them before accepting further traffic.

For cleartext H2 prior knowledge, use C<protocol =E<gt> 'h2'> instead of
C<alpn>. Missing or empty ALPN selects H1 only when enabled. Unknown or
disallowed negotiation results fail. The selector does not sniff input bytes.

=head1 OUTPUT CONTRACT

The attached transport implements:

    unblock_send($bytes)
    unblock_finish()
    unblock_abort($reason)

C<unblock_send> accepts the entire buffer or throws. True or undef means it
can accept more output. A defined false value means it accepted every byte
but is congested. It must retain any bytes not yet written by the socket.
False never means partial acceptance, and the engine must not resend the
accepted buffer. When capacity returns, call:

    $self->{http}->resume_output;

C<unblock_finish> asks the framework to flush accepted output and then finish
normally. C<unblock_abort> reports failure and requests immediate teardown.
Do not implement another independent network queue in Unblock::HTTP.

The engine holds the transport weakly. The framework must retain both the
transport and its engine. The reusable Server does not retain attached
engines. Callbacks shared by a Server definition should not capture every
connection or create ownership cycles.

=head1 HTTP/3

Use a ready QUIC connection already negotiated for HTTP/3:

    my $engine = $server->attach_quic(connection => $ready_h3_connection);

The returned HTTP3 Server is already started. Keep it alive while the QUIC
connection is active. This attachment method does not negotiate ALPN; the
caller supplies an H3 connection. UDP packets never go to HTTP C<input>.

L<Unblock::HTTP::QUIC> can manage readiness and engine lifetime for all
connections on a server Driver:

    my $endpoint = Unblock::HTTP::QUIC->server(
        server => $server,
        certificate_file => $cert,
        private_key_file => $key,
        send => $send_datagram,
        set_timeout => $replace_timer,
    );
    $endpoint->start;

Forward UDP receive events to C<receive>, timer expiry to C<timeout>, and
recovered UDP capacity to C<writable>. Net::QUIC::Driver determines the next
timeout in seconds; the framework replaces its timer accordingly. The manager
sets H3 ALPN and uses the supplied reusable Server definition without overriding
its callbacks or policy. C<on_ready> receives the real HTTP3 Server engine.

=head1 SHARED CLIENT FACTORIES

The shared Client requires framework callbacks for connection establishment:

    my $client = Unblock::HTTP::Client->new(
        http1 => {}, http2 => {}, http3 => {},
        connect_stream => sub {
            my ($origin, $alpn_choices, $ready) = @_;
            # Use the framework to establish TCP/TLS.
            # In its connection callback:
            # my $engine = $ready->(
            #     transport => $framework_stream, alpn => $negotiated,
            # );
            # $framework_stream->{http_engine} = $engine;
        },
        connect_quic => sub {
            my ($origin, $ready) = @_;
            # Establish QUIC with the framework/Net::QUIC::Driver.
            # my $engine = $ready->(connection => $ready_quic);
        },
        defer => sub {
            my ($callback) = @_;
            # Schedule for a LATER event-loop turn, never inline.
        },
    );

The ready callback returns the actual H1, H2, or H3 Client engine after
successful attachment, so the framework can retain it. Every new
connect_stream invocation requires its OWN connected byte transport;
it must not attach a second HTTP engine to an already-owned socket. Feed TCP bytes,
EOF, errors and recovered output capacity directly to that engine. For
HTTP/3, preserve QUIC Driver UDP and timer operation and let HTTP/3 own
its stream callbacks. The pooled Client is not a byte-path forwarding object.

The TCP factory may report C<verified_origin =E<gt> 1> ONLY after
successfully validating the HTTPS TLS certificate against the original
origin hostname. This enables learning Alt-Svc from that connection.
The QUIC factory receives C<alternative_host> and C<alternative_port>
when an advertised alternative is selected, while retaining the original
origin authority and host. It MUST authenticate the QUIC peer for the
original HTTPS origin and report C<verified_origin =E<gt> 1> for the
request to be dispatched. A missing attestation rejects that alternative.

The framework should call C<$client-E<gt>network_changed> after a
meaningful route/interface/VPN transition. This explicitly clears
old Alt-Svc hints and idle sockets. Active requests retain their
transactions and finish or fail naturally without blind replay.
Connection factories that were still pending are abandoned safely.
C<$client-E<gt>pool_stats> exposes read-only counts for adapter
diagnostics without requiring access to engine internals.

A Client may enable C<idle_timeout> with its optional framework timer
factory and C<release_connection> hook. On the first completely idle
period after the last active transaction (and without waiting queued
requests), a timer runs. Reuse cancels the timer. When it expires, the
framework release hook receives the actual transport and engine to
perform its normal cleanup, with a reason string; it must not attach
another engine to the released transport. Active streams and pending
H2/H3 credit-blocked work are never expired.

A Client may also receive C<schedule_timer =E<gt> sub { ... }> for
application requests specifying C<timeout> in seconds. The callback
receives the delay and an expiry callback, schedules a future framework
timer and returns a coderef that cancels the timer. No additional socket
or network buffering layer is required. The timeout covers queueing,
connection establishment and the active transaction. The connection
factory may return an optional cancellation coderef that aborts unfinished
establishment; if a request is cancelled or expires while its factory is
pending, the pool discards any later readiness callback. The framework
must clean up late, unused connections rather than feeding them to HTTP.

C<defer> is necessary because the engine may invoke on_finish before its
own response-retirement bookkeeping has unwound. Deferring new dispatch
prevents re-entering an HTTP/1 engine from that callback.

A factory failure uses C<$ready-E<gt>(error =E<gt> $reason)>. A request that
never reached an engine calls on_error/on_finish with the request operation
handle rather than pretending that an engine transaction exists. Do not
automatically retry requests when connection outcome is ambiguous.

=head1 WEBSOCKET ATTACHMENT AND LIFECYCLE

For HTTP1 the host implements C<unblock_upgrade($websocket)> to switch
the input consumer on the same TCP/TLS stream after its ordered output
queue accepts the HTTP 101 response. A small illustrative Linux::Event
Stream subclass in F<examples/linux-event-websocket-server.pl>
demonstrates this hook without exporting an adapter module.
A native borrowed-buffer provider must hand its
unconsumed input window to the new consumer exactly once. The HTTP1
Client releases ownership of this socket to the WebSocket host; ordinary
HTTP pool shutdown does not close it.

For HTTP2 and HTTP3, no host-side socket or QUIC stream takeover is
required. Enable WebSocket on the Server definition for each protocol:

    http2 => { websocket => 1 },
    http3 => { websocket => 1 },
    defer => sub { $framework->defer($_[0]) },
    on_websocket => sub {
        my ($tx, $request) = @_;
        return {
            on_message => sub {
                my ($ws, $bytes, $type) = @_;
                $ws->send_text($bytes) if $type eq 'text';
            },
        };
    },

The framework's C<defer> hook MUST schedule on a later event-loop turn,
not execute inline while an H2/H3 parser or QUIC callback is active.
The Server processes HTTP Extended CONNECT and creates one WebSocket
session per request Transaction, with HTTP 200 on success. That session
receives DATA from the Transaction and sends its frames through a
stream-local deferred output bridge. Independent WebSocket and ordinary
HTTP streams continue on the same connection. Invalid/declined
handshakes return HTTP 400/403 without changing the transport.

The unified Client also accepts C<connect_websocket()> with explicit
C<http_version =E<gt> '1.1'>, C<'2'> or C<'3'>. H2/H3 wait for the
current peer SETTINGS_ENABLE_CONNECT_PROTOCOL setting before issuing
CONNECT; H3 additionally respects QUIC bidirectional request-stream
credit. An unsuccessful handshake reports an operation error, and the
framework keeps ownership of the pooled connection while that one
stream is closed. WebSocket Close and shutdown preserve ordinary
multiplexed transaction lifetimes.

Reference examples separate application callbacks from adapter setup:

=over 4

=item *

F<examples/linux-event-websocket-server.pl> serves H1 Upgrade or H2
prior-knowledge Extended CONNECT and ordinary HTTP on a TCP listener.
F<examples/linux-event-websocket-client.pl> supplies the matching
shared Client's TCP transport factory with cleartext local connections.

=item *

F<examples/linux-event-quic-websocket-server.pl> serves H3 Extended
CONNECT over QUIC/TLS with a Linux::Event UDP socket and one replaceable
timer.

=back

Neither example makes the core classes depend on Linux::Event. For
the exact Client transport factory requirements, see the Client POD
and this document's C<SHARED CLIENT FACTORIES> section.

=head1 FRAMEWORK INTEGRATION OWNERSHIP

Unblock::HTTP defines the framework-neutral transport and callback
contracts, but does not bundle or maintain framework adapters.
A framework adapter for Linux::Event belongs in the separate
Linux::Event::HTTP distribution when that project elects to provide one.
No Linux::Event dependency or adapter is installed by Unblock::HTTP.

F<examples/linux-event-server.pl> and
F<examples/linux-event-websocket-server.pl> each contain a complete,
illustrative Linux::Event Stream subclass locally in the program.
F<examples/linux-event-quic-websocket-server.pl> demonstrates a QUIC
UDP/timer integration. These examples do not establish a supported
adapter module API.

The repository retains a historical test-only adapter fixture in
F<xt/lib/Unblock/HTTP/Adapter/LinuxEvent.pm> and its unit tests in
F<xt/linux-event-adapter.t>. Both are excluded from the release tarball.
Their purpose is to exercise integration semantics without requiring
Unblock::HTTP to distribute or support an event-loop-specific adapter.

=head1 ADAPTER OWNERSHIP REQUIREMENTS

The receive-mode, terminal-notification and H1/H2/H3 WebSocket
transition paths are included in the released engine versions required
by Unblock::HTTP 0.02.
The whole-buffer transport contract remains in force. Adapter authors
must still handle hard buffer limits, borrowed-input ownership across
native H1 switches, and framework-specific shutdown semantics.
Cross-engine real-wire and QUIC/TLS coverage is in the test suite;
future adapter implementations should exercise those ownership rules
before claiming production support.

=head1 LICENSE

MIT License.

=cut
