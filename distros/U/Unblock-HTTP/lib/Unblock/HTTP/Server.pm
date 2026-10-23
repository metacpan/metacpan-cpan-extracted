package Unblock::HTTP::Server;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed refaddr weaken);
use Unblock::HTTP::_Policy;
use Unblock::HTTP::_EngineFactory;

our $VERSION = '0.02';

sub new {
    my ($class, @args) = @_;
    croak 'new(): expected named arguments' if @args % 2;
    my %options = @args;
    my (%protocols, %callbacks);
    for my $name (qw(http1 http2 http3)) {
        $protocols{$name} = delete $options{$name} if exists $options{$name};
    }
    for my $name (qw(on_headers on_request on_error on_websocket)) {
        next unless exists $options{$name};
        my $callback = delete $options{$name};
        croak "new(): $name must be a coderef" unless ref($callback) eq 'CODE';
        $callbacks{$name} = $callback;
    }
    my $defer = delete $options{defer};
    croak 'new(): defer must be a coderef'
        if defined($defer) && ref($defer) ne 'CODE';
    croak 'new(): unknown option: ' . join(', ', sort keys %options) if %options;
    croak 'new(): on_request callback is required' unless $callbacks{on_request};
    my $policy = Unblock::HTTP::_Policy->new(%protocols, _websocket_role => 'server');
    my $websocket_enabled = $policy->websocket_enabled('http/1.1')
        || $policy->websocket_enabled('h2')
        || $policy->websocket_enabled('h3');
    croak 'new(): on_websocket callback is required for enabled WebSocket support'
        if $websocket_enabled && !$callbacks{on_websocket};
    croak 'new(): on_websocket requires an enabled websocket protocol'
        if !$websocket_enabled && $callbacks{on_websocket};
    croak 'new(): HTTP2/HTTP3 WebSocket requires a defer callback'
        if ($policy->websocket_enabled('h2')
            || $policy->websocket_enabled('h3')) && !$defer;
    return bless {
        policy => $policy,
        on_websocket => $callbacks{on_websocket},
        defer => $defer,
        # Map once at definition time; no transaction or body wrapper.
        callbacks => {
            on_request => $callbacks{on_headers} || \&_ignore_headers,
            on_request_end => $callbacks{on_request},
            ($callbacks{on_error} ? (on_error => $callbacks{on_error}) : ()),
        },
    }, $class;
}

sub _ignore_headers { return }

# Recognize even incomplete WebSocket attempts so a malformed upgrade is not
# silently treated as an ordinary application request.
sub _websocket_candidate {
    my ($request) = @_;
    for my $index (0 .. $request->header_count - 1) {
        my $name = lc $request->header_name($index);
        return 1 if $name =~ /\Asec-websocket-/;
        next unless $name eq 'upgrade';
        for my $token (split /,/, $request->header_value($index)) {
            return 1 if $token =~ /\A[ \t]*websocket[ \t]*\z/i;
        }
    }
    return 0;
}

# HTTP1 switches the complete byte stream, not an individual transaction.
# Keep the lower engine and transport as the only byte owners. Only this
# opted-in attachment gets a pair of per-connection transition callbacks.
sub _attach_websocket_stream {
    my ($self, $transport, $engine_options) = @_;
    croak 'attach_stream(): HTTP1 WebSocket transport must implement unblock_upgrade()'
        unless $transport->can('unblock_upgrade');

    my $host = $transport;
    weaken($host);
    my $engine;
    my $handler = $self->{on_websocket};
    my $on_http_request = $self->{callbacks}{on_request_end};
    my $pending;

    my $on_request_end = sub {
        my ($tx, $request) = @_;
        return $on_http_request->(@_) unless _websocket_candidate($request);

        my $selected = $handler->($tx, $request);
        unless (defined $selected) {
            $tx->respond(status => 403, body => 'WebSocket denied');
            return;
        }
        croak 'on_websocket must return a hash reference or undef'
            unless ref($selected) eq 'HASH';
        my %option = %$selected;
        my %handshake_option;
        for my $name (qw(subprotocols permessage_deflate)) {
            $handshake_option{$name} = delete $option{$name}
                if exists $option{$name};
        }
        my $on_open = delete $option{on_open};
        croak 'on_websocket on_open must be a coderef'
            if defined($on_open) && ref($on_open) ne 'CODE';
        croak 'on_websocket may not override the attached transport'
            if exists $option{transport};

        require Unblock::WebSocket::Handshake;
        require Unblock::WebSocket::Server;
        my $handshake;
        my $valid = eval {
            $handshake = Unblock::WebSocket::Handshake->server_accept(
                $request, %handshake_option,
            );
            1;
        };
        unless ($valid) {
            $tx->respond(status => 400, body => 'Invalid WebSocket handshake');
            return;
        }
        my $ws = Unblock::WebSocket::Server->new(
            %{ $handshake->connection_options },
            %option,
            transport => $host,
        );
        $pending = {
            transaction => refaddr($tx),
            websocket   => $ws,
            on_open     => $on_open,
            request     => $request,
        };
        # Even a failed host write must release the pending WebSocket state.
        $tx->on_finish(sub {
            $pending = undef
                if $pending && $pending->{transaction} == refaddr($_[0]);
        });
        my $ok = eval { $tx->respond($handshake->server_response); 1 };
        unless ($ok) {
            $pending = undef;
            die $@;
        }
        return;
    };

    my $on_switch = sub {
        my ($tx) = @_;
        # An ordinary CONNECT or unrelated protocol switch remains the
        # lower HTTP1 engine's responsibility, not an implicit WebSocket.
        return unless $pending;
        croak 'WebSocket switch transaction does not match the handshake'
            unless $pending->{transaction} == refaddr($tx);
        my $ready = $pending;
        $pending = undef;
        my $ws = $ready->{websocket};
        croak 'WebSocket transport was destroyed during handshake' unless $host;
        $host->unblock_upgrade($ws);
        $ready->{on_open}->($ws, $tx, $ready->{request})
            if $ready->{on_open};
        my $tail = $engine->take_remainder;
        $ws->input($tail) if length $tail;
        return;
    };

    my %callbacks = %{ $self->{callbacks} };
    $callbacks{on_request_end} = $on_request_end;
    $callbacks{on_switch} = $on_switch;
    my $attached = Unblock::HTTP::_EngineFactory->create(
        'Server', 'http/1.1', %$engine_options,
        %callbacks, transport => $transport,
    );
    $engine = $attached;
    weaken($engine);
    return $attached;
}

# Extended CONNECT belongs to one H2 transaction; the HTTP/2 connection
# remains able to serve independent ordinary HTTP and other WebSockets.
# Outgoing WebSocket frames must NEVER re-enter nghttp2 from input callbacks.
sub _attach_h2_websocket_stream {
    my ($self, $transport, $engine_options) = @_;
    require Unblock::HTTP::_WebSocketH2Body;
    my $handler = $self->{on_websocket};
    my $defer = $self->{defer};
    my $on_headers = $self->{callbacks}{on_request};
    my $on_request_end = $self->{callbacks}{on_request_end};
    my %sessions;

    my $on_request = sub {
        my ($tx, $request) = @_;
        my $protocol = $request->protocol;
        my $candidate = $request->method eq 'CONNECT'
            && ((defined($protocol) && $protocol eq 'websocket')
                || _websocket_candidate($request));
        return $on_headers->(@_) unless $candidate;

        my $selected = $handler->($tx, $request);
        unless (defined $selected) {
            $tx->respond(status => 403, body => 'WebSocket denied');
            return;
        }
        croak 'on_websocket must return a hash reference or undef'
            unless ref($selected) eq 'HASH';
        my %option = %$selected;
        my %handshake_option;
        for my $name (qw(subprotocols permessage_deflate)) {
            $handshake_option{$name} = delete $option{$name}
                if exists $option{$name};
        }
        my $on_open = delete $option{on_open};
        croak 'on_websocket on_open must be a coderef'
            if defined($on_open) && ref($on_open) ne 'CODE';
        croak 'on_websocket may not override the H2 stream transport'
            if exists $option{transport};

        require Unblock::WebSocket::Handshake;
        require Unblock::WebSocket::Server;
        my $handshake;
        my $valid = eval {
            $handshake = Unblock::WebSocket::Handshake->server_accept(
                $request, %handshake_option,
            );
            1;
        };
        unless ($valid) {
            $tx->respond(status => 400, body => 'Invalid WebSocket handshake');
            return;
        }
        my $bridge = Unblock::HTTP::_WebSocketH2Body->new(
            transaction => $tx, defer => $defer,
        );
        my $ws = Unblock::WebSocket::Server->new(
            %{ $handshake->connection_options },
            %option, transport => $bridge,
        );
        $bridge->websocket($ws);
        my $id = $tx->stream_id;
        $sessions{$id} = { bridge => $bridge, websocket => $ws };
        $tx->on_data(sub {
            $ws->input($_[1]);
        });
        $tx->on_finish(sub {
            $bridge->detach;
            delete $sessions{$id};
        });
        $tx->respond(
            $handshake->server_response,
            stream_body => 1,
            on_drain => sub { $bridge->resume },
        );
        $on_open->($ws, $tx, $request) if $on_open;
        return;
    };

    my $on_request_complete = sub {
        my ($tx) = @_;
        if (my $session = $sessions{$tx->stream_id}) {
            $session->{websocket}->input_eof;
            return;
        }
        return $on_request_end->(@_);
    };

    my %callbacks = %{ $self->{callbacks} };
    $callbacks{on_request} = $on_request;
    $callbacks{on_request_end} = $on_request_complete;
    return Unblock::HTTP::_EngineFactory->create(
        'Server', 'h2', %$engine_options,
        %callbacks, transport => $transport,
    );
}

# A WebSocket CONNECT occupies an H3 QUIC request stream, not the QUIC
# connection. The real Transaction owns both directions; the private body
# bridge only defers outgoing WebSocket writes past the H3 receive callback.
sub _attach_h3_websocket_connection {
    my ($self, $connection, $engine_options) = @_;
    require Unblock::HTTP::_WebSocketH2Body;
    my $handler = $self->{on_websocket};
    my $defer = $self->{defer};
    my $on_headers = $self->{callbacks}{on_request};
    my $on_request_end = $self->{callbacks}{on_request_end};
    my (%sessions, %websocket_attempts);

    my $on_request = sub {
        my ($tx, $request) = @_;
        my $protocol = $request->protocol;
        my $candidate = $request->method eq 'CONNECT'
            && ((defined($protocol) && $protocol eq 'websocket')
                || _websocket_candidate($request));
        return $on_headers->(@_) unless $candidate;

        my $id = $tx->stream_id;
        $websocket_attempts{$id} = 1;
        my $selected = $handler->($tx, $request);
        unless (defined $selected) {
            $tx->on_finish(sub { delete $websocket_attempts{$id} });
            $tx->respond(status => 403, body => 'WebSocket denied');
            return;
        }
        croak 'on_websocket must return a hash reference or undef'
            unless ref($selected) eq 'HASH';
        my %option = %$selected;
        my %handshake_option;
        for my $name (qw(subprotocols permessage_deflate)) {
            $handshake_option{$name} = delete $option{$name}
                if exists $option{$name};
        }
        my $on_open = delete $option{on_open};
        croak 'on_websocket on_open must be a coderef'
            if defined($on_open) && ref($on_open) ne 'CODE';
        croak 'on_websocket may not override the H3 stream transport'
            if exists $option{transport};

        require Unblock::WebSocket::Handshake;
        require Unblock::WebSocket::Server;
        my $handshake;
        my $valid = eval {
            $handshake = Unblock::WebSocket::Handshake->server_accept(
                $request, %handshake_option,
            );
            1;
        };
        unless ($valid) {
            $tx->on_finish(sub { delete $websocket_attempts{$id} });
            $tx->respond(status => 400, body => 'Invalid WebSocket handshake');
            return;
        }
        my $bridge = Unblock::HTTP::_WebSocketH2Body->new(
            transaction => $tx, defer => $defer,
        );
        my $ws = Unblock::WebSocket::Server->new(
            %{ $handshake->connection_options },
            %option, transport => $bridge,
        );
        $bridge->websocket($ws);
        $sessions{$id} = { bridge => $bridge, websocket => $ws };
        $tx->on_data(sub { $ws->input($_[1]) });
        $tx->on_finish(sub {
            $bridge->detach;
            delete $sessions{$id};
            delete $websocket_attempts{$id};
        });
        $tx->respond(
            $handshake->server_response,
            stream_body => 1,
            on_drain => sub { $bridge->resume },
        );
        $on_open->($ws, $tx, $request) if $on_open;
        return;
    };

    my $on_request_complete = sub {
        my ($tx) = @_;
        my $id = $tx->stream_id;
        if ($websocket_attempts{$id}) {
            if (my $session = $sessions{$id}) {
                $session->{websocket}->input_eof;
            }
            # Even a 400/403 CONNECT belongs to on_websocket, not to
            # the ordinary request-end responder. Do not respond twice.
            return;
        }
        return $on_request_end->(@_);
    };

    my %callbacks = %{ $self->{callbacks} };
    $callbacks{on_request} = $on_request;
    $callbacks{on_request_end} = $on_request_complete;
    my $engine = Unblock::HTTP::_EngineFactory->create(
        'Server', 'h3', %$engine_options,
        %callbacks, quic => $connection,
    );
    $engine->start;
    return $engine;
}

sub protocols { return $_[0]{policy}->protocols }
sub alpn_protocols { return $_[0]{policy}->alpn_protocols }
sub supports { return $_[0]{policy}->enabled($_[1]) }

sub attach_stream {
    my ($self, @args) = @_;
    croak 'attach_stream(): expected named arguments' if @args % 2;
    my %options = @args;
    croak 'attach_stream(): specify either protocol or alpn, not both'
        if exists($options{protocol}) && exists($options{alpn});
    my $transport = delete $options{transport};
    my $protocol = delete $options{protocol};
    my $alpn = delete $options{alpn};
    croak 'attach_stream(): unknown option: ' . join(', ', sort keys %options) if %options;
    croak 'attach_stream(): protocol and alpn must be scalars'
        if ref($protocol) || ref($alpn);
    $protocol = defined($alpn) && length($alpn) ? $alpn : 'http/1.1'
        unless defined $protocol;
    croak "attach_stream(): unsupported byte-stream protocol '$protocol'"
        unless $protocol eq 'http/1.1' || $protocol eq 'h2';
    my $engine_options = $self->{policy}->options($protocol);
    croak 'attach_stream(): transport must be an object' unless blessed($transport);
    for my $method (qw(unblock_send unblock_finish unblock_abort)) {
        croak "attach_stream(): transport must implement $method()"
            unless $transport->can($method);
    }
    return $self->_attach_websocket_stream($transport, $engine_options)
        if $protocol eq 'http/1.1' && $self->{policy}->websocket_enabled($protocol);
    return $self->_attach_h2_websocket_stream($transport, $engine_options)
        if $protocol eq 'h2' && $self->{policy}->websocket_enabled($protocol);
    return Unblock::HTTP::_EngineFactory->create(
        'Server', $protocol, %$engine_options,
        %{ $self->{callbacks} }, transport => $transport,
    );
}

sub attach_quic {
    my ($self, @args) = @_;
    croak 'attach_quic(): expected named arguments' if @args % 2;
    my %options = @args;
    my $connection = delete $options{connection};
    croak 'attach_quic(): unknown option: ' . join(', ', sort keys %options) if %options;
    my $engine_options = $self->{policy}->options('h3');
    croak 'attach_quic(): connection must be a QUIC connection object'
        unless blessed($connection) && $connection->can('ready') && $connection->can('closed');
    croak 'attach_quic(): connection is closed' if $connection->closed;
    croak 'attach_quic(): connection is not ready' unless $connection->ready;
    return $self->_attach_h3_websocket_connection($connection, $engine_options)
        if $self->{policy}->websocket_enabled('h3');
    my $engine = Unblock::HTTP::_EngineFactory->create(
        'Server', 'h3', %$engine_options,
        %{ $self->{callbacks} }, quic => $connection,
    );
    $engine->start;
    return $engine;
}

1;

__END__

=head1 NAME

Unblock::HTTP::Server - Shared HTTP server policy and connection attachment

=head1 SYNOPSIS

    my $server = Unblock::HTTP::Server->new(
        http1 => {},
        http2 => {},
        on_request => sub {
            my ($tx, $request) = @_;
            $tx->respond(status => 200, body => "hello\n");
        },
    );

    # For each accepted connection, in the framework adapter:
    my $engine = $server->attach_stream(
        transport => $stream,
        alpn => $negotiated_alpn,
    );
    $engine->input($bytes);

=head1 IMPLEMENTATION STATUS

This feature branch implements reusable attachment and ordinary buffered or
streamed requests. It requires the receive/lifecycle feature branches of the
three engines; released H1/H2 0.11 and H3 0.12 do not provide these methods.
HTTP/1.1 Server Upgrade and HTTP/2 Server Extended CONNECT are verified
opt-in paths using Unblock::WebSocket. HTTP/2 Client Extended CONNECT is
also verified and documented in Unblock::HTTP::Client. HTTP/3 Server
Extended CONNECT is verified by real QUIC/TLS loopback. HTTP/3 Client
Extended CONNECT is also implemented and verified over real QUIC/TLS,
including peer SETTINGS, stream-credit admission and cancellation.
Initial Client factories and bounded pooling are implemented there.
See docs/IMPLEMENTATION.md. This is not a release candidate.

=head1 CONSTRUCTOR

=head2 new

Enable each protocol with C<http1 =E<gt> {}>, C<http2 =E<gt> {}>, or
C<http3 =E<gt> {}>. An omitted protocol is disabled. At least one is required.
Each hash can contain engine tuning options. Policy copies hash and array
containers so changing a caller's settings does not change future connections.
Engine-specific object values retain their identity.

C<on_request> is required. C<on_headers> and C<on_error> are optional.
Connection and callback options may not be hidden inside a protocol's tuning hash.

Each protocol defaults to bounded buffered reception with a 1 MiB limit.
Set C<max_buffered_body_bytes> in its protocol hash to change the positive
byte limit. C<receive_body> is managed by this layer; select streaming with
C<$tx-E<gt>on_data(...)> during C<on_headers>. The engine owns the buffer.

=head2 Request callbacks

C<on_headers($tx, $request)> runs after headers, before body delivery.
The same real engine transaction and Uniform request are passed to
C<on_request($tx, $request)> once the body and trailers finish successfully.
In buffered mode, C<$request-E<gt>body> holds the complete body, including
an empty string for an empty body. The message is frozen before C<on_request>.
A failed or cancelled body does not call C<on_request>.

For streamed requests:

    on_headers => sub {
        my ($tx) = @_;
        $tx->on_data(sub {
            my ($tx, $bytes) = @_;
            consume_chunk($bytes);
        });
        $tx->on_finish(sub {
            my ($tx) = @_;
            record_outcome($tx->state);
        });
    },
    on_request => sub {
        my ($tx) = @_;
        $tx->respond(status => 204);
    },

C<on_data> selects streaming and suppresses full-body accumulation. It must
be registered before the first body byte. C<on_request> still runs after
successful streamed reception. C<on_finish> runs once after completion,
cancellation, or error; it waits for the response side too. Register it
before the transaction is terminal. Its exceptions do not undo cleanup.
C<on_error> retains the engine's arguments: transaction, error, and an
optional protocol error code. Cancellation alone is not an error.

C<websocket =E<gt> 1> enables server-side HTTP/1.1 WebSocket Upgrade,
HTTP/2 Extended CONNECT, and HTTP/3 Extended CONNECT
server path, only when C<on_websocket> is supplied. All default to
disabled. HTTP/2 and HTTP/3 WebSockets require C<defer>, which schedules
execution on a later event-loop turn. The relevant Extended CONNECT
setting is advertised only when that protocol's WebSocket policy is
enabled. HTTP/3 Client WebSocket is also supported. For H2/H3
WebSocket CONNECT transactions, C<on_websocket> replaces ordinary
C<on_headers>/C<on_request> delivery; other HTTP requests are unchanged.

=head2 HTTP/1.1 WebSocket Upgrade

The optional L<Unblock::WebSocket> distribution is loaded only for WebSocket
handshakes. The existing HTTP1 engine handles the opening HTTP request and
writes the 101 response. An established WebSocket uses the same framework
transport and write queue. No HTTP transaction or byte-stream wrapper is
introduced.

    my $server = Unblock::HTTP::Server->new(
        http1 => { websocket => 1 },
        on_request => sub {
            my ($tx) = @_;
            $tx->respond(status => 200, body => 'ordinary HTTP');
        },
        on_websocket => sub {
            my ($tx, $request) = @_;
            return {
                on_message => sub {
                    my ($ws, $message, $type) = @_;
                    $ws->send_text("echo:$message") if $type eq 'text';
                },
                on_open => sub {
                    my ($ws, $tx, $request) = @_;
                    # Invoked after the 101 response entered the host queue.
                },
            };
        },
    );

When an HTTP/1.1 request includes WebSocket handshake indicators,
C<on_websocket($tx, $request)> selects connection options. It must return a
hash reference of L<Unblock::WebSocket::Server> constructor callbacks/options,
or C<undef> to reject the upgrade with HTTP 403. C<subprotocols> and
C<permessage_deflate> are passed through the WebSocket handshake negotiator
and its negotiated options are applied to the established session. Invalid
handshakes receive HTTP 400, without switching the connection. Incorrect
application-provided options are application errors.

An attached HTTP1 transport with this policy must implement the usual
C<unblock_send>, C<unblock_finish> and C<unblock_abort> methods, plus:

    sub unblock_upgrade {
        my ($transport, $websocket) = @_;
        $transport->{consumer} = $websocket;
    }

The hook switches subsequent input, EOF, errors and output-resume calls to
the provided WebSocket engine; it must be synchronous. It runs once, only
after the HTTP1 engine has accepted the complete 101 response into the host
output queue. Unblock::HTTP transfers C<take_remainder()> from the HTTP1
engine into the new WebSocket engine after the hook (and after C<on_open>),
preserving buffered frames received in the same input call as the HTTP
request. The host must keep its existing ordered output queue and must
not send the same remainder again. HTTP1 retains its own transaction identity.

This first slice is regression-tested with the public C<input()> path.
For native borrowed-input integration, the provider may retain an unconsumed
window after C<INPUT_SWITCH>; that window is not in C<take_remainder()>.
The provider must hand the unconsumed native bytes to its successor consumer
as required by the HTTP1 NativeABI contract. This layer does not yet install
a native successor consumer on behalf of a framework.

Normal HTTP requests continue to reach C<on_request>, even with WebSocket
enabled. C<on_headers> continues to run for both HTTP and WebSocket requests.
One definition may serve many separate attached transports. For a WebSocket
Close handshake, the existing Unblock::WebSocket transport contract controls
graceful shutdown and C<unblock_finish>. The framework still owns sockets,
TLS, input dispatch and writable notifications.

=head1 METHODS

=head2 HTTP/2 Extended CONNECT WebSocket Server

Opt in with C<http2 =E<gt> { websocket =E<gt> 1 }> and the same
C<on_websocket($tx, $request)> callback used for HTTP/1.1. When HTTP/2
WebSocket support is enabled, provide a C<defer> coderef on the Server:

    my $server = Unblock::HTTP::Server->new(
        http2 => { websocket => 1 },
        defer => sub {
            my ($work) = @_;
            $framework->defer($work);   # Always a later event-loop turn
        },
        on_request => sub {
            my ($tx) = @_;
            $tx->respond(status => 200, body => 'normal HTTP2');
        },
        on_websocket => sub {
            my ($tx, $request) = @_;
            return {
                on_message => sub {
                    my ($ws, $payload, $type) = @_;
                    $ws->send_text("echo:$payload") if $type eq 'text';
                },
                on_open => sub {
                    my ($ws, $tx, $request) = @_;
                },
            };
        },
    );

This policy advertises HTTP/2 SETTINGS_ENABLE_CONNECT_PROTOCOL. Without
it, the unified Server explicitly disables advertising. Conflicting
manual SETTINGS value 8 or C<enable_connect_protocol =E<gt> 0> is rejected.
HTTP/2 WebSocket is an Extended CONNECT with C<:protocol> set to
C<websocket>, returning HTTP 200 (not 101). The upgrade affects one
stream, not the TCP/TLS connection. Other streams remain ordinary HTTP2.

Incoming stream DATA goes directly through the real Transaction's
C<on_data()> to its own Unblock::WebSocket::Server. A small internal
stream-specific bridge accepts outgoing WebSocket frames and queues
them into the existing Transaction's C<write()> on the provided
deferred event-loop turn. The bridge respects the Transaction's
C<on_drain()> and calls C<end()> only after all queued frames are
accepted. WebSocket errors reset their own stream, not the shared
HTTP/2 connection. No application or framework adapter needs to
manually ferry DATA to WebSocket. The callback can return undef to
reject the attempt with HTTP 403, and an invalid handshake gets HTTP 400.

C<defer> MUST schedule work after the current HTTP/2 parser callback
returns, never run it synchronously. Synchronous execution would reenter
nghttp2 and is unsupported. The framework continues to send and
receive ordinary HTTP2 bytes through its existing C<unblock_send>,
C<input>, C<input_eof>, C<transport_error>, and C<resume_output>.
It does not call C<unblock_upgrade> for HTTP/2. As a result, one
attached H2 engine can handle multiple WebSockets and ordinary
requests simultaneously. The transaction and socket remain owned by
the existing H2 engine and framework.

HTTP/2 Client WebSocket support and HTTP/3 Extended CONNECT remain
separate, unfinished milestones. This H2 Server slice does not make
any change to the lower HTTP2 or WebSocket distribution.

=head2 attach_stream

Accepts C<transport> and either C<alpn> or C<protocol>. The transport provides
C<unblock_send>, C<unblock_finish>, and C<unblock_abort>. It retains the
returned real HTTP1 or HTTP2 Server engine and feeds bytes directly to it.
There is no intermediate connection wrapper and no transaction wrapper.

Missing or empty ALPN selects HTTP/1.1 only if HTTP/1.1 is enabled. Unknown
or disabled protocols fail. Explicit C<protocol =E<gt> 'h2'> is for cleartext
prior knowledge. HTTP/3 cannot be attached to a byte stream.

=head2 HTTP/3 Extended CONNECT WebSocket Server

Opt in with C<http3 =E<gt> { websocket =E<gt> 1 }>, supply
C<on_websocket($tx, $request)> and C<defer($work)> as for HTTP/2,
and attach each ready Net::QUIC connection with C<attach_quic>.
The unified Server advertises SETTINGS_ENABLE_CONNECT_PROTOCOL
(HTTP/3 setting 8) only when explicitly enabled. A WebSocket CONNECT
uses a normal QUIC bidirectional request stream, not a separate UDP
socket or QUIC connection. The handshake is HTTP 200 (not HTTP 101).

Incoming WebSocket DATA uses the existing H3 Transaction C<on_data>.
An internal deferred per-stream writer queues outbound WebSocket frames
and hands them to the same Transaction through C<write()>, using
C<on_drain> to honor stream backpressure. The WebSocket Close
handshake ultimately ends the stream. Application denial returns
HTTP 403; invalid WebSocket handshake returns HTTP 400. Ordinary
HTTP/3 traffic continues to use its normal callbacks. C<defer>
must never invoke the scheduled callback inline from an H3 parser
callback. The framework remains responsible for QUIC UDP delivery,
timeout scheduling, writable readiness and connection lifecycle.

The actual Net::QUIC 0.05 loopback/TLS integration, WebSocket frames,
ordinary stream isolation, Close and HTTP 400/403 tests passed both
full upper integration workflows at source b43532e92917d5850b6abc78c16485e3e16acc37.
The separate H3 Client implementation has also passed full integration
at source a3f429edf66562a55ab23e0d5b55a8e3eb989b7c; see
Unblock::HTTP::Client for the Client-specific OPTIONS and callbacks.

=head2 attach_quic

Accepts C<connection> containing a ready, open QUIC connection negotiated
for HTTP/3. Returns a started real HTTP3 Server engine. The caller retains
it until the connection closes. UDP and timer events still go to the QUIC
Driver, never to an HTTP byte input method.

=head2 protocols

Returns enabled wire protocol names in list context: C<http/1.1>, C<h2>,
and/or C<h3>.

=head2 alpn_protocols

Returns enabled TCP/TLS ALPN choices, preferring C<h2> over C<http/1.1>.
The framework uses this list when configuring TLS. HTTP/3 uses a separate
QUIC listener and is not included in this list.

=head2 supports

C<supports($protocol)> reports whether a wire protocol name is enabled.

=head1 OWNERSHIP

One Server definition can serve many connections. It does not own listeners,
sockets, engine registries, or a network queue. The framework retains each
returned engine. Engine callbacks retain their original identity.

=head1 LICENSE

MIT License.

=cut
