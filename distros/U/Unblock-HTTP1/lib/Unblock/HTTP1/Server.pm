package Unblock::HTTP1::Server;

use strict;
use warnings;
use Carp qw(croak);
use parent 'Unblock::HTTP1::_Engine';

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::_Native ();
use Unblock::HTTP1::_Wire ();
use Unblock::HTTP1::Transaction;

our $VERSION = '0.11';

sub new {
    my ($class, %option) = @_;
    my %callbacks;
    for my $name (qw(on_request on_body on_request_end on_error on_switch)) {
        next unless exists $option{$name};
        my $cb = delete $option{$name};
        croak "new(): $name must be a coderef" unless ref($cb) eq 'CODE';
        $callbacks{$name} = $cb;
    }
    croak 'new(): on_request callback is required' unless $callbacks{on_request};
    my $self = bless {
        callbacks => \%callbacks,
        active    => undef,
        rx        => undef,
    }, $class;
    $self->_init_engine(%option);
    return $self;
}

sub transaction { $_[0]{active} }

sub _input_native_head {
    my ($self, $head, $request) = @_;
    croak '_input_native_head(): cannot be called recursively from an engine callback'
        if $self->{driving};
    return (4, 0) if $self->{switched};
    return (3, 0) if $self->{closed};
    croak '_input_native_head(): cannot mix native head input with buffered portable input'
        if length $self->{input};
    croak '_input_native_head(): request body is already active'
        if $self->{active} || $self->{rx};

    my ($status, $ready);
    {
        local $self->{borrowed_head} = $head;
        local $self->{borrowed_message} = $request;
        local $self->{native_head_preconsumed} = 1;
        local $self->{driving} = 1;
        $self->_drive;
        $status = $self->{closed} ? 3 : $self->{switched} ? 4 : 0;
        $ready = $self->_borrowed_native_head_ready;
    }
    $self->_transport_sync if $self->{transport_attached};
    return ($status, $ready);
}

sub _drive {
    my ($self) = @_;
    while (!$self->{closed} && !$self->{switched}) {
        my $tx = $self->{active};
        my $rx = $self->{rx};

        if (!$tx) {
            return unless $self->{borrowed_head} || $self->_input_length;
            my $head = delete $self->{borrowed_head};
            my $request = delete $self->{borrowed_message};
            if (!$head) {
                my ($input, $offset) = $self->_input_window;
                $head = Unblock::HTTP1::_Native->parse_request_head(
                    $input, 0, $self->{max_headers}, $offset,
                );
            }
            if (!$head) {
                if ($self->_input_length > $self->{max_head_size}) {
                    $self->_protocol_error(431, 'request head exceeds configured limit');
                }
                return;
            }
            if (!$head->{ok}) {
                $self->_protocol_error($head->{status} || 400, $head->{error});
                return;
            }
            if ($head->{consumed} > $self->{max_head_size}) {
                $self->_protocol_error(431, 'request head exceeds configured limit');
                return;
            }
            $self->_input_discard($head->{consumed})
                unless $self->{native_head_preconsumed};

            if ($head->{expect_continue} < 0) {
                $self->_protocol_error(417, 'unsupported Expect field');
                return;
            }

            if (!$request) {
                my %target_metadata = Unblock::HTTP1::_Wire::_received_request_metadata(
                    $head->{method}, $head->{target},
                );
                $request = Unblock::HTTP1::_Wire::_request_from_validated_head(
                    $head, %target_metadata,
                );
            }

            $tx = Unblock::HTTP1::Transaction->_new(
                $self, $request,
                callbacks   => {},
                local_done  => 0,
                remote_done => 0,
            );
            $tx->{request_keep_alive} = $head->{keep_alive} ? 1 : 0;
            $tx->{request_body_mode} = $head->{body_mode};
            $self->{active} = $tx;

            my $bodyless = $head->{body_mode} eq 'none' ? 1 : 0;
            my $fixed_ready = !$bodyless
                && $head->{body_mode} eq 'content-length'
                && defined($head->{content_length})
                && $self->_input_length >= $head->{content_length};

            if (!$bodyless && !$fixed_ready) {
                $self->{rx} = $rx = {
                    mode      => $head->{body_mode},
                    remaining => $head->{content_length},
                    request   => $request,
                };
                if ($rx->{mode} eq 'chunked') {
                    $rx->{decoder} = Unblock::HTTP1::_Native::Chunked->new($self->{max_chunk_extension_size});
                }
            }

            if ($head->{expect_continue} > 0
                && ($head->{body_mode} eq 'chunked'
                    || ($head->{body_mode} eq 'content-length'
                        && $head->{content_length}))) {
                $self->_queue_output("HTTP/1.1 100 Continue\r\n\r\n");
            }

            my $cb = $self->_invoke_server('on_request', $tx, $request);
            return $self->_application_error($cb) unless $cb eq '1';
            return if $self->{switched} || $self->{closed};

            if ($bodyless) {
                $tx->_mark_remote_done;
                my $end_cb = $self->_invoke_server('on_request_end', $tx, $request);
                return $self->_application_error($end_cb) unless $end_cb eq '1';
                $self->_retire_if_done;
                next;
            }

            if ($fixed_ready) {
                my $length = $head->{content_length};
                if ($length) {
                    my $bytes = $self->_input_take($length);
                    my $body_cb = $self->_invoke_server(
                        'on_body', $tx, $request, $bytes,
                    );
                    return $self->_application_error($body_cb)
                        unless $body_cb eq '1';
                    return if $self->{switched} || $self->{closed};
                }
                $self->_complete_request($tx, $request);
                next;
            }
        }

        $tx = $self->{active} or next;
        $rx = $self->{rx};
        return unless $rx;

        if ($rx->{mode} eq 'content-length') {
            return unless $self->_input_length;
            my $available = $self->_input_length;
            my $take = $available < $rx->{remaining}
                ? $available : $rx->{remaining};
            my $bytes = $self->_input_take($take);
            $rx->{remaining} -= $take;
            my $cb = $self->_invoke_server('on_body', $tx, $rx->{request}, $bytes);
            return $self->_application_error($cb) unless $cb eq '1';
            if ($rx->{remaining} == 0) {
                $self->_finish_request;
                next;
            }
            return;
        }

        if ($rx->{mode} eq 'chunked') {
            return unless $self->_input_length;
            my ($input, $offset) = $self->_input_window;
            my $available = $self->_input_length;
            my ($done, $decoded, $leftover);
            my $ok = eval {
                ($done, $decoded, $leftover) =
                    $rx->{decoder}->feed($input, 1, $offset);
                1;
            };
            if (!$ok) {
                $self->_protocol_error(400, "$@");
                return;
            }
            $self->_input_discard($available - length($leftover));
            if (defined($decoded) && length($decoded)) {
                my $cb = $self->_invoke_server('on_body', $tx, $rx->{request}, $decoded);
                return $self->_application_error($cb) unless $cb eq '1';
            }
            return unless $done;
            $rx->{mode} = 'trailers';
            delete $rx->{decoder};
            next;
        }

        if ($rx->{mode} eq 'trailers') {
            my ($input, $offset) = $self->_input_window;
            my $trailers = Unblock::HTTP1::_Native->parse_trailers(
                $input, 0, $self->{max_headers}, $offset,
            );
            if (!$trailers) {
                if ($self->_input_length > $self->{max_head_size}) {
                    $self->_protocol_error(431, 'trailer section exceeds configured limit');
                }
                return;
            }
            if (!$trailers->{ok}) {
                $self->_protocol_error(400, $trailers->{error});
                return;
            }
            if ($trailers->{consumed} > $self->{max_head_size}) {
                $self->_protocol_error(431, 'trailer section exceeds configured limit');
                return;
            }
            for my $field (@{ $trailers->{headers} }) {
                my $name = lc $field->[0];
                if ($name eq 'content-length' || $name eq 'transfer-encoding'
                    || $name eq 'host' || $name eq 'connection' || $name eq 'trailer') {
                    $self->_protocol_error(400, 'forbidden framing field in HTTP/1 trailers');
                    return;
                }
                $rx->{request}->add_trailer(@$field);
            }
            $self->_input_discard($trailers->{consumed});
            $self->_finish_request;
            next;
        }

        return $self->_protocol_error(400, 'invalid HTTP/1 server receive state');
    }
    return;
}

sub _finish_request {
    my ($self) = @_;
    my $tx = $self->{active} or return;
    my $rx = delete $self->{rx} or return;
    return $self->_complete_request($tx, $rx->{request});
}

sub _complete_request {
    my ($self, $tx, $request) = @_;
    $request->mark_complete->freeze;
    $tx->_mark_remote_done;
    my $cb = $self->_invoke_server('on_request_end', $tx, $request);
    return $self->_application_error($cb) unless $cb eq '1';
    $self->_retire_if_done;
    return;
}

sub _transaction_respond {
    my ($self, $tx, $response, %option) = @_;
    croak 'respond(): Transaction is not active on this HTTP/1 connection'
        unless $self->{active} && $self->{active} == $tx;
    croak 'respond(): Transaction already has a Response' if $tx->response;
    my $status = Unblock::HTTP1::_Wire::_status_code($response->status);
    croak 'respond(): informational status must use send_informational()'
        if $status < 200 && $status != 101;

    my $stream_body = delete($option{stream_body}) ? 1 : 0;
    my $on_drain = delete $option{on_drain};
    croak 'respond(): on_drain must be a coderef'
        if defined($on_drain) && ref($on_drain) ne 'CODE';
    croak 'respond(): on_drain requires stream_body' if $on_drain && !$stream_body;
    croak 'respond(): unknown options: ' . join(', ', sort keys %option) if %option;

    my $plan = Unblock::HTTP1::_Wire::response_plan(
        $tx->request, $response,
        stream_body => $stream_body,
    );
    $tx->_set_response($response);
    $tx->{send_plan} = $plan;
    $tx->{stream_body} = $stream_body;
    $tx->{callbacks}{on_drain} = $on_drain if $on_drain;
    $self->_queue_output($plan->{wire});

    if ($plan->{switch}) {
        $tx->_mark_local_done;
        $tx->{switch_pending} = 1;
        $self->_retire_if_done;
        return $tx;
    }

    if ($plan->{body_finalized}) {
        $tx->_mark_local_done;
        $tx->{keep_alive} = $plan->{keep_alive} ? 1 : 0;
        $self->_retire_if_done;
    }
    $self->_transport_sync if $self->{transport_attached};
    return $tx;
}

sub _transaction_informational {
    my ($self, $tx, $response) = @_;
    croak 'send_informational(): Transaction is not active on this HTTP/1 connection'
        unless $self->{active} && $self->{active} == $tx;
    my $status = $response->status;
    croak 'send_informational(): status must be 100 through 199 except 101'
        unless $status >= 100 && $status < 200 && $status != 101;
    croak 'send_informational(): HTTP/1.0 clients cannot receive 1xx responses'
        if ($tx->request->version || '1.1') eq '1.0';
    my $plan = Unblock::HTTP1::_Wire::response_plan($tx->request, $response);
    $self->_queue_output($plan->{wire});
    return $tx;
}

sub _transaction_write {
    my ($self, $tx, $bytes, $final) = @_;
    croak 'write(): Transaction is not active on this HTTP/1 connection'
        unless $self->{active} && $self->{active} == $tx;
    my $plan = $tx->{send_plan} or croak 'write(): respond() has not started a response';
    croak 'write(): response does not have a streaming body' unless $tx->{stream_body};
    croak 'write(): streaming response body is already complete' if $tx->{local_done};
    $bytes = Unblock::HTTP1::_Wire::_bytes('response body chunk', $bytes);

    if ($plan->{mode} eq 'chunked') {
        $self->_queue_output(Unblock::HTTP1::_Wire::chunk($bytes));
        if ($final) {
            my $trailers = Unblock::HTTP1::_Wire::_fields($tx->response, 'trailer');
            $self->_queue_output(Unblock::HTTP1::_Wire::final_chunk($trailers));
            $tx->_mark_local_done;
        }
    } elsif ($plan->{mode} eq 'content-length') {
        my $remaining = $plan->{remaining};
        croak 'write(): body exceeds declared Content-Length' if length($bytes) > $remaining;
        $self->_queue_output($bytes);
        $remaining -= length($bytes);
        $plan->{remaining} = $remaining;
        croak 'end(): body ended before declared Content-Length' if $final && $remaining;
        $tx->_mark_local_done if $remaining == 0;
    } elsif ($plan->{mode} eq 'close') {
        $self->_queue_output($bytes);
        $tx->_mark_local_done if $final;
    } else {
        croak 'write(): invalid streaming response framing mode';
    }

    if ($tx->{local_done}) {
        $tx->{keep_alive} = $plan->{keep_alive} ? 1 : 0;
        $self->_retire_if_done;
    }
    $self->_transport_sync if $self->{transport_attached};
    my $ok = $self->_stream_ok;
    $tx->{blocked} = 1 unless $ok;
    return $ok;
}

sub _retire_if_done {
    my ($self) = @_;
    my $tx = $self->{active} or return;
    return unless $tx->{local_done} && $tx->{remote_done};
    if ($tx->{switch_pending}) {
        $tx->_mark_complete unless $tx->is_terminal;
        my $response = $tx->response;
        $self->_mark_switched;
        $self->{active} = undef;
        if ($self->{transport_attached}) {
            $self->{switch_notice} = [ $tx, $response ];
            $self->_transport_sync if $self->{transport_attached};
            return;
        }
        return $self->_deliver_switch_notice($tx, $response);
    }
    $tx->_mark_complete unless $tx->is_terminal;
    my $keep = $tx->{keep_alive};
    $keep = $tx->{request_keep_alive} unless defined $keep;
    $self->{active} = undef;
    if (!$keep || $self->{eof}) {
        $self->{closed} = 1;
        $self->_transport_sync if $self->{transport_attached};
        return;
    }
    return if $self->{driving};
    local $self->{driving} = 1;
    $self->_drive if $self->_input_length;
    return;
}

sub _deliver_switch_notice {
    my ($self, $tx, $response) = @_;
    my $cb = $self->_invoke_server('on_switch', $tx, $response);
    if ($cb ne '1') {
        if ($self->{transport_attached}) {
            $self->_transport_abort($cb);
        } else {
            $self->_application_error($cb);
        }
    }
    return;
}

sub _transaction_cancel {
    my ($self, $tx) = @_;
    return if $tx->is_terminal;
    $tx->_mark_cancelled;
    $self->{active} = undef if $self->{active} && $self->{active} == $tx;
    $self->{rx} = undef;
    $self->{closed} = 1;
    $self->_transport_abort('HTTP/1 transaction cancelled')
        if $self->{transport_attached};
    return;
}

sub _maybe_drain {
    my ($self) = @_;
    my $tx = $self->{active} or return;
    return unless $tx->{blocked};
    $tx->{blocked} = 0;
    my $cb = $tx->_invoke('on_drain');
    $self->_application_error($cb) unless $cb eq '1';
    return;
}

sub _invoke_server {
    my ($self, $name, @args) = @_;
    my $cb = $self->{callbacks}{$name} or return 1;
    my $ok = eval { $cb->(@args); 1 };
    return $ok ? 1 : "$@";
}

sub _application_error {
    my ($self, $error) = @_;
    $error = 'HTTP/1 server callback failed' unless defined($error) && length($error);
    my $tx = $self->{active};
    if ($tx && !$tx->response && !$self->{switched}) {
        eval {
            my $response = Uniform::HTTP::Response->new(status => 500, body => '');
            $self->_transaction_respond($tx, $response);
            1;
        };
    }
    $self->{closed} = 1;
    $tx->_fail($error) if $tx && !$tx->is_terminal;
    if (my $cb = $self->{callbacks}{on_error}) {
        eval { $cb->($tx, $error) };
    }
    return;
}

sub _protocol_error {
    my ($self, $status, $detail) = @_;
    return if $self->{closed};
    my $reason = $status == 400 ? 'Bad Request'
        : $status == 417 ? 'Expectation Failed'
        : $status == 431 ? 'Request Header Fields Too Large'
        : $status == 501 ? 'Not Implemented'
        : $status == 505 ? 'HTTP Version Not Supported'
        : 'Bad Request';
    my $wire = 'HTTP/1.1 ' . $status . ' ' . $reason . "\r\n"
        . "Content-Length: 0\r\nConnection: close\r\n\r\n";
    $self->_queue_output($wire);
    $self->{closed} = 1;
    if (my $tx = $self->{active}) {
        $tx->_fail($detail || $reason) unless $tx->is_terminal;
    }
    if (my $cb = $self->{callbacks}{on_error}) {
        eval { $cb->($self->{active}, $detail || $reason) };
    }
    return;
}

sub _borrowed_should_buffer_tail {
    my ($self) = @_;
    return $self->{active} && !$self->{rx} ? 1 : 0;
}

sub _borrowed_native_head_ready {
    my ($self) = @_;
    return 0 if $self->{closed} || $self->{switched};
    return 0 if $self->{active} || $self->{rx};
    return 0 if length $self->{input};
    return 1;
}

sub _on_eof {
    my ($self) = @_;
    return if $self->{switched};
    if ($self->{active} && $self->{active}{remote_done}) {
        # A fully received request may still have a delayed application
        # response. Read EOF prevents reuse but does not cancel that reply.
        $self->{active}{request_keep_alive} = 0;
        return;
    }
    if ($self->{active} || length($self->{input})) {
        $self->_protocol_error(400, 'unexpected EOF in HTTP/1 request');
    } else {
        $self->{closed} = 1;
    }
    return;
}

sub _fail_all {
    my ($self, $error) = @_;
    if (my $tx = delete $self->{active}) {
        $tx->_fail($error) unless $tx->is_terminal;
    }
    $self->{rx} = undef;
    if (my $cb = $self->{callbacks}{on_error}) {
        eval { $cb->(undef, $error) };
    }
    return;
}

1;

__END__

=head1 NAME

Unblock::HTTP1::Server - One non-blocking HTTP/1 server connection

=head1 SYNOPSIS

    use Unblock::HTTP1::Server;

    my $server = Unblock::HTTP1::Server->new(
        transport => $transport,

        on_request => sub {
            my ($tx, $request) = @_;

            $tx->respond(
                status => 200,
                body   => "hello\n",
            );
        },
    );

    $server->input($bytes);

=head1 DESCRIPTION

C<Unblock::HTTP1::Server> owns the HTTP/1 protocol state for one accepted
server connection.

It is not a listener and it does not create sockets, perform TLS, or run an
event loop. A host framework accepts the connection and feeds its bytes into
this object.

Supply C<transport =E<gt> $host> to C<new()> to deliver outgoing wire
bytes automatically through the host. The host owns its socket and implements
C<unblock_send()>, C<unblock_finish()>, and C<unblock_abort()>.
See L<Unblock::HTTP1::Integration> for a complete example and the contract.

The lower-level form is:

    my $server = Unblock::HTTP1::Server->new(
        on_request => sub { ... },
    );

In that mode the caller feeds input with C<input()> and drains output with
C<output()>.

The Server supports persistent HTTP/1 connections and safely handles
pipelined request bytes. Only one transaction is active at a time; bytes for a
later request remain buffered until the prior transaction retires.

=head1 CONSTRUCTOR

=head2 new

    my $server = Unblock::HTTP1::Server->new(
        on_request => sub { ... },
        %options,
    );

Creates one server protocol engine.

C<on_request> is required.

Other callbacks are optional:

    on_body
    on_request_end
    on_error
    on_switch

Common options are:

=over 4

=item C<transport>

Optional framework-owned object implementing C<unblock_send($bytes)>,
C<unblock_finish()>, and C<unblock_abort($reason)>.
The engine holds a weak reference to it. See L<Unblock::HTTP1::Integration>.

=item C<max_head_size>

Maximum request head size in bytes. Default: 65536.

=item C<max_headers>

Maximum number of header or trailer fields. Default: 100.

=item C<max_chunk_extension_size>

Maximum total chunk-extension bytes allowed for one chunked message.
Default: 16384.

=item C<high_water>

High-water mark for the HTTP output queue. Default: 65536.

=item C<low_water>

Low-water mark used to resume a blocked streaming response producer.
Default: 32768.

=back

=head1 REQUEST CALLBACKS

=head2 on_request

    on_request => sub {
        my ($tx, $request) = @_;
    }

Required.

Called once after a complete request head has been parsed and validated.

C<$request> is a canonical L<Uniform::HTTP::Request>. Its method, target,
version, and headers are available at this point. The request body and trailers
may still be arriving.

The application may respond immediately from C<on_request>; it does not need to
wait for C<on_request_end> unless its response depends on the complete request
body.

For a valid C<Expect: 100-continue> request with a body, the engine emits
C<100 Continue> before delivering the request callback.

=head2 on_body

    on_body => sub {
        my ($tx, $request, $bytes) = @_;
    }

Called zero or more times as request body bytes arrive.

HTTP transfer framing such as chunk boundaries has already been removed.
Content codings such as gzip are not decoded automatically.

The same Transaction and Request objects are used for every body callback of
the request.

=head2 on_request_end

    on_request_end => sub {
        my ($tx, $request) = @_;
    }

Called once after the complete request body and any trailers have arrived.

Before this callback runs, the request is marked complete and frozen. Trailer
fields are available through the Uniform request object.

A request with no body reaches C<on_request_end> immediately after
C<on_request> returns.

=head2 on_error

    on_error => sub {
        my ($tx, $error) = @_;
    }

Called for a server-side HTTP or application failure.

C<$tx> may be undef when the failure happened before a transaction could be
created, or when a transport failure affects an otherwise idle connection.

Examples include malformed framing, head limits, unexpected EOF, callback
exceptions, and explicit transport failure.

When an application callback dies before a response has started, the engine
attempts to produce a 500 response and closes the HTTP connection.

Protocol errors produce an appropriate HTTP error response when possible and
close the connection.

=head2 on_switch

    on_switch => sub {
        my ($tx, $response) = @_;
    }

Called when a sent 101 response or successful CONNECT transfers ownership of
the connection away from HTTP.

At this point C<is_switched()> is true. Any bytes already read beyond the HTTP
boundary are available through C<take_remainder()>.

=head1 RESPONDING

C<on_request> receives an L<Unblock::HTTP1::Transaction>. Normal responses can
be created directly:

    $tx->respond(
        status  => 200,
        headers => [
            [ 'Content-Type' => 'text/plain' ],
        ],
        body => "hello\n",
    );

C<respond()> constructs the canonical L<Uniform::HTTP::Response> internally.

An existing response object is also accepted:

    $tx->respond($response);

Informational responses use:

    $tx->send_informational(
        status  => 103,
        headers => [
            [ Link => '</style.css>; rel=preload' ],
        ],
    );

Informational responses must be 100 through 199 except 101. HTTP/1.0 clients
cannot receive informational responses through this method.

=head1 STREAMING RESPONSES

To produce a response body incrementally:

    $tx->respond(
        status      => 200,
        stream_body => 1,
        on_drain    => sub {
            produce_more();
        },
    );

    my $ok = $tx->write($chunk);
    $tx->end($last_chunk);

For HTTP/1.1, chunked transfer framing is used when required. An explicit
Content-Length is honored and enforced. HTTP/1.0 streaming may require
close-delimited framing or an explicit length depending on the response.

A false return from C<write()> means the bytes were accepted but the producer
should pause. C<on_drain> runs when the output path becomes writable again.

Known response trailers are serialized with the final chunk. If trailer names
will only be known later, the application should predeclare allowed trailer
names in the response C<Trailer> field.

=head1 TRANSACTION

=head2 transaction

    my $tx = $server->transaction;

Returns the currently active transaction, or undef when the server is idle.

Because requests are processed serially on one HTTP/1 connection, this method
never returns a later pipelined transaction while an earlier one is active.

=head1 CONNECTION INPUT

=head2 input

    my $accepted = $server->input($bytes);

Feeds received request bytes into the engine.

The return value is the number of supplied bytes accepted by the portable
input path.

The engine may invoke request callbacks before C<input()> returns.

Do not call C<input()> recursively from an HTTP callback.

=head2 input_eof

    $server->input_eof;

Reports a clean read-side EOF. Unlike a transport error, a fully received
request may still receive a delayed response after EOF. An incomplete request
at EOF is handled as an HTTP framing error. Do not use C<input('')> as EOF.

=head2 transport_error

    $server->transport_error($reason);

Reports a broken socket, TLS failure, or other unusable transport. Unsent
HTTP output is discarded; outstanding work fails and C<unblock_abort()> is
called. Do not call this on ordinary read-side EOF.

=head1 CONNECTION OUTPUT

=head2 want_write

    $server->want_write;

True when the engine has bytes buffered for output.

Normally unnecessary when an attached transport is present.

=head2 output

    my $bytes = $server->output;
    my $bytes = $server->output($maximum);

Removes and returns queued wire bytes in manual integration mode.
C<output()> throws when a transport is attached to prevent mixed ownership.

C<$maximum>, when supplied, must be a positive integer.

Draining below the low-water mark can resume a blocked streaming response and
invoke its C<on_drain> callback.

Do not call C<output()> recursively from an HTTP callback.

=head2 resume_output

    $server->resume_output;

Called by an attached host after C<unblock_send()> returned a defined false
value (meaning complete acceptance followed by congestion). The host must
call this again when it can accept more output. It can trigger a streaming
Transaction's C<on_drain> callback.

An output-queueing host that always returns undef does not need it.

=head1 CONNECTION STATE

=head2 want_read

    $server->want_read;

True while the engine is still accepting HTTP bytes.

It becomes false after read EOF, close, or protocol switch.

=head2 is_closed

    $server->is_closed;

True when the HTTP connection is closed.

=head2 is_switched

    $server->is_switched;

True after a 101 response or successful CONNECT transfers ownership away from
HTTP.

=head2 take_remainder

    my $bytes = $server->take_remainder;

Returns bytes already received after the HTTP boundary.

Valid only after C<is_switched()> becomes true.

=head2 close

    $server->close;
    $server->close($reason);

Closes the HTTP engine and fails unfinished work.

With an attached transport, already queued HTTP output is handed to the
transport before graceful close when possible.

Use C<transport_error()> instead when the transport itself has failed.

=head1 KEEP-ALIVE AND PIPELINING

HTTP/1 persistence is managed by the engine from the request and response
framing rules.

If a connection is reusable, the server returns to idle state after the active
transaction retires.

If later request bytes were already received, they remain buffered and the next
request is parsed after the prior transaction completes. Application code does
not need to coordinate pipelined byte boundaries.

=head1 PROTOCOL SWITCH

A 101 response or successful CONNECT ends HTTP framing on this connection.

The Transaction completes first, then C<on_switch> runs. When a transport is attached, the switch callback runs only after the
outgoing handshake bytes have been accepted by the host. They may still
be waiting in the host's own write queue.

After the switch:

    $server->is_switched;

is true and:

    my $tail = $server->take_remainder;

returns bytes which belong to the next protocol.

Do not continue feeding those bytes to HTTP.

=head1 CALLBACK ERRORS AND REENTRANCY

Exceptions thrown by server callbacks are treated as connection/application
errors.

Application callbacks may call Transaction methods such as C<respond()>,
C<write()>, and C<end()>.

Do not recursively call C<input()>, C<input_eof()>, or C<output()> from an
engine callback.

=head1 TRANSACTION OBJECTS

The Transaction provides:

    request
    response
    respond
    send_informational
    write
    end
    cancel
    state
    error
    is_complete
    is_cancelled
    is_error
    is_terminal

See L<Unblock::HTTP1::Transaction> for details.

=head1 NATIVE INPUT

XS-backed transports can use L<Unblock::HTTP1::NativeABI> to feed borrowed
native buffers directly.

Native input uses the same Server object and HTTP callbacks.

=head1 SEE ALSO

L<Unblock::HTTP1::Integration>,
L<Unblock::HTTP1>,
L<Unblock::HTTP1::Transaction>,
L<Unblock::HTTP1::NativeABI>,
L<Uniform::HTTP::Request>,
L<Uniform::HTTP::Response>

=cut
