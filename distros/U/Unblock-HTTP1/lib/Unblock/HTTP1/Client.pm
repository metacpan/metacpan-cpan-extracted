package Unblock::HTTP1::Client;

use strict;
use warnings;
use Carp qw(croak);
use parent 'Unblock::HTTP1::_Engine';

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::_Native ();
use Unblock::HTTP1::_Wire ();
use Unblock::HTTP1::Transaction;

our $VERSION = '0.13';

sub new {
    my ($class, %option) = @_;
    my $self = bless {
        queue  => [],
        active => undef,
        rx     => undef,
    }, $class;
    $self->_init_engine(%option);
    return $self;
}

sub request {
    my ($self, @arg) = @_;
    croak 'request(): connection is closed' if $self->{closed};
    croak 'request(): connection has switched protocols' if $self->{switched};
    croak 'request(): read side is at EOF' if $self->{eof};

    my ($request, %option);
    if (@arg && ref($arg[0])) {
        $request = shift @arg;
        croak 'request(): options must be key/value pairs' if @arg % 2;
        %option = @arg;
    } else {
        croak 'request(): request fields must be key/value pairs' if @arg % 2;
        my %field = @arg;
        for my $name (qw(
            stream_body
            on_informational
            on_response
            on_body
            on_data
            on_finish
            on_complete
            on_error
            on_switch
            on_drain
        )) {
            $option{$name} = delete $field{$name} if exists $field{$name};
        }
        $request = Uniform::HTTP::Request->new(%field);
    }

    croak 'request(): requires a Uniform HTTP request object'
        unless ref($request) && $request->can('method') && $request->can('target')
            && $request->can('header_count') && $request->can('has_buffered_body');

    my $stream_body = delete($option{stream_body}) ? 1 : 0;
    my %callbacks;
    for my $name (qw(on_informational on_response on_body on_data on_finish on_complete on_error on_switch on_drain)) {
        next unless exists $option{$name};
        my $cb = delete $option{$name};
        croak "request(): $name must be a coderef" unless ref($cb) eq 'CODE';
        $callbacks{$name} = $cb;
    }
    croak 'request(): on_drain requires stream_body'
        if $callbacks{on_drain} && !$stream_body;
    croak 'request(): unknown options: ' . join(', ', sort keys %option) if %option;

    my $tx = Unblock::HTTP1::Transaction->_new(
        $self, $request,
        callbacks  => \%callbacks,
        local_done => 0,
    );
    $tx->{stream_body} = $stream_body;
    push @{ $self->{queue} }, $tx;
    $self->_start_next unless $self->{active};
    return $tx;
}

sub transaction { $_[0]{active} }

sub _start_next {
    my ($self) = @_;
    return if $self->{active} || $self->{closed} || $self->{switched};
    my $tx = shift @{ $self->{queue} } or return;
    my $plan;
    my $ok = eval {
        $plan = Unblock::HTTP1::_Wire::request_plan(
            $tx->request,
            stream_body => $tx->{stream_body},
        );
        1;
    };
    if (!$ok) {
        $tx->_fail("$@");
        $tx->_invoke('on_error', $tx->error);
        $tx->_notify_finish;
        return $self->_start_next;
    }
    $tx->{send_plan} = $plan;
    $tx->{local_done} = $plan->{body_finalized} ? 1 : 0;
    $self->{active} = $tx;
    # Keep framing state, but transfer serialized bytes to the output queue.
    $self->_queue_output(delete $plan->{wire});
    return;
}

sub _input_native_head {
    my ($self, $head, $response) = @_;
    croak '_input_native_head(): cannot be called recursively from an engine callback'
        if $self->{driving};
    return (4, 0) if $self->{switched};
    return (3, 0) if $self->{closed};
    croak '_input_native_head(): cannot mix native head input with buffered portable input'
        if length $self->{input};
    croak '_input_native_head(): response received with no outstanding request'
        unless $self->{active};
    croak '_input_native_head(): response body is already active'
        if $self->{rx};

    my ($status, $ready);
    {
        local $self->{borrowed_head} = $head;
        local $self->{borrowed_message} = $response;
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

    if (!$self->{closed} && !$self->{switched}
        && !$self->{active} && $self->_input_length) {
        if ($self->_input_remaining =~ /\A(?:\r\n)+\z/) {
            $self->_input_clear;
            return;
        }
        return $self->_connection_error(
            'HTTP/1 response bytes received with no outstanding request'
        );
    }

    while (!$self->{closed} && !$self->{switched} && $self->{active}) {
        my $tx = $self->{active};
        my $rx = $self->{rx};

        if (!$rx) {
            my $head = delete $self->{borrowed_head};
            my $response = delete $self->{borrowed_message};
            my $native_response = $response ? 1 : 0;
            if (!$head) {
                my ($input, $offset) = $self->_input_window;
                $head = Unblock::HTTP1::_Native->parse_response_head(
                    $input, 0, $self->{max_headers}, $offset,
                );
            }
            if (!$head) {
                return $self->_connection_error('HTTP/1 response head exceeds configured limit')
                    if $self->_input_length > $self->{max_head_size};
                return;
            }
            return $self->_connection_error($head->{error}) unless $head->{ok};
            return $self->_connection_error('HTTP/1 response head exceeds configured limit')
                if $head->{consumed} > $self->{max_head_size};
            $self->_input_discard($head->{consumed})
                unless $self->{native_head_preconsumed};

            my $informational =
                $head->{status} >= 100 && $head->{status} < 200
                && $head->{status} != 101 ? 1 : 0;
            if (!$response) {
                $response =
                    Unblock::HTTP1::_Wire::_response_from_validated_head(
                        $head, $informational,
                    );
            }

            my $plan;
            my $ok = eval {
                $plan = Unblock::HTTP1::_Wire::response_receive_plan(
                    $tx->request,
                    $head,
                    $native_response ? $response : undef,
                );
                1;
            };
            return $self->_connection_error("$@") unless $ok;

            if ($informational) {
                my $cb = $tx->_invoke('on_informational', $response);
                return $self->_connection_error($cb) unless $cb eq '1';
                next;
            }

            $tx->_set_response($response);

            my $fixed_ready = !$plan->{switch}
                && $plan->{mode} eq 'content-length'
                && defined($plan->{remaining})
                && $self->_input_length >= $plan->{remaining};
            my $immediate = !$plan->{switch}
                && ($plan->{mode} eq 'none' || $fixed_ready);

            if (!$immediate) {
                $self->{rx} = $rx = {
                    response       => $response,
                    mode           => $plan->{mode},
                    remaining      => $plan->{remaining},
                    keep_alive     => $plan->{keep_alive},
                    switch         => $plan->{switch},
                    forbid_content => $plan->{forbid_content} ? 1 : 0,
                };
                if ($rx->{mode} eq 'chunked') {
                    $rx->{decoder} = Unblock::HTTP1::_Native::Chunked->new($self->{max_chunk_extension_size});
                }
            }

            my $cb = $tx->_invoke('on_response', $response);
            return $self->_connection_error($cb) unless $cb eq '1';
            return if $self->{closed};

            if ($plan->{switch}) {
                return $self->_connection_error(
                    'protocol switch received before streaming request body completed'
                ) if $tx->{stream_body} && !$tx->{local_done};
                $tx->_finish_receive($response);
                $response->mark_complete->freeze;
                $tx->_mark_remote_done;
                $tx->_mark_complete;
                $self->{rx} = undef;
                $self->_mark_switched;
                $self->_fail_queued('HTTP/1 connection switched protocols');
                $self->{active} = undef;
                if ($self->{transport_attached}) {
                    $self->{switch_notice} = [ $tx, $response ];
                    $self->_transport_sync if $self->{transport_attached};
                    return;
                }
                return $self->_deliver_switch_notice($tx, $response);
            }

            if ($plan->{mode} eq 'none') {
                $self->_complete_response(
                    $tx, $response, $plan->{keep_alive},
                );
                next;
            }

            if ($fixed_ready) {
                my $length = $plan->{remaining};
                if ($length) {
                    my $bytes = $self->_input_take($length);
                    return $self->_connection_error(
                        '205 response must not contain content'
                    ) if $plan->{forbid_content} && length $bytes;
                    my $body_cb = $tx->_receive_data($response, $bytes);
                    return $self->_connection_error($body_cb)
                        unless $body_cb eq '1';
                    return if $self->{closed};
                }
                $self->_complete_response(
                    $tx, $response, $plan->{keep_alive},
                );
                next;
            }
        }

        $rx = $self->{rx} or next;
        if ($rx->{mode} eq 'content-length') {
            return unless $self->_input_length;
            my $available = $self->_input_length;
            my $take = $available < $rx->{remaining}
                ? $available : $rx->{remaining};
            my $bytes = $self->_input_take($take);
            $rx->{remaining} -= $take;
            return $self->_connection_error('205 response must not contain content')
                if $rx->{forbid_content} && length $bytes;
            my $cb = $tx->_receive_data($rx->{response}, $bytes);
            return $self->_connection_error($cb) unless $cb eq '1';
            return if $tx->is_terminal;
            if ($rx->{remaining} == 0) {
                $self->_finish_response;
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
            return $self->_connection_error("$@") unless $ok;
            $self->_input_discard($available - length($leftover));
            if (defined($decoded) && length($decoded)) {
                return $self->_connection_error('205 response must not contain content')
                    if $rx->{forbid_content};
                my $cb = $tx->_receive_data($rx->{response}, $decoded);
                return $self->_connection_error($cb) unless $cb eq '1';
            }
            return if $tx->is_terminal;
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
                return $self->_connection_error('HTTP/1 trailer section exceeds configured limit')
                    if $self->_input_length > $self->{max_head_size};
                return;
            }
            return $self->_connection_error($trailers->{error}) unless $trailers->{ok};
            return $self->_connection_error('HTTP/1 trailer section exceeds configured limit')
                if $trailers->{consumed} > $self->{max_head_size};
            for my $field (@{ $trailers->{headers} }) {
                my $name = lc $field->[0];
                return $self->_connection_error('forbidden framing field in HTTP/1 trailers')
                    if $name eq 'content-length' || $name eq 'transfer-encoding'
                        || $name eq 'host' || $name eq 'connection' || $name eq 'trailer';
                $rx->{response}->add_trailer(@$field);
            }
            $self->_input_discard($trailers->{consumed});
            $self->_finish_response;
            next;
        }

        if ($rx->{mode} eq 'close') {
            return unless $self->_input_length;
            my $bytes = $self->_input_take($self->_input_length);
            return $self->_connection_error('205 response must not contain content')
                if $rx->{forbid_content} && length $bytes;
            my $cb = $tx->_receive_data($rx->{response}, $bytes);
            return $self->_connection_error($cb) unless $cb eq '1';
            return;
        }

        return $self->_connection_error('invalid HTTP/1 client receive state');
    }
    return;
}

sub _borrowed_native_head_ready {
    my ($self) = @_;
    return 0 if $self->{closed} || $self->{switched};
    return 0 unless $self->{active};
    return 0 if $self->{rx};
    return 0 if length $self->{input};
    return 1;
}

sub _finish_response {
    my ($self) = @_;
    my $tx = $self->{active} or return;
    my $rx = delete $self->{rx} or return;
    return $self->_complete_response(
        $tx, $rx->{response}, $rx->{keep_alive},
    );
}

sub _complete_response {
    my ($self, $tx, $response, $keep_alive) = @_;
    return if $tx->is_terminal;
    $tx->_finish_receive($response);
    $response->mark_complete->freeze;
    $tx->_mark_remote_done;
    $tx->{keep_alive} = $keep_alive ? 1 : 0;

    # A final response can arrive before an incremental request body has
    # finished. The peer has already ended this HTTP exchange, so no further
    # request-body bytes may be sent and the connection cannot be reused.
    if ($tx->{stream_body} && !$tx->{local_done}) {
        $tx->{request_body_cancelled} = 1;
        $tx->_mark_local_done;
        $tx->{keep_alive} = 0;
        $self->{output} = '';
    }

    $self->_retire_if_done;
    return;
}

sub _retire_if_done {
    my ($self) = @_;
    my $tx = $self->{active} or return;
    return unless $tx->{local_done} && $tx->{remote_done};
    $tx->_mark_complete unless $tx->is_terminal;
    my $cb = $tx->_invoke('on_complete');
    $tx->_notify_finish;
    return $self->_connection_error($cb) unless $cb eq '1';

    my $keep = $tx->{keep_alive} && $tx->{send_plan}{keep_alive};
    my $extra = $self->_input_length ? 1 : 0;
    $self->{active} = undef;

    # This client serializes requests and never pipelines them. Therefore,
    # bytes already received beyond a final response boundary cannot belong to
    # a later response. Do not retain them for a future request: doing so would
    # allow an unsolicited response to poison the response queue.
    if ($extra) {
        $self->_input_clear;
        $self->{closed} = 1;
        $self->_fail_queued('unexpected bytes after final HTTP/1 response');
        $self->_transport_sync if $self->{transport_attached};
        return;
    }

    if (!$keep) {
        $self->{closed} = 1;
        $self->_fail_queued('HTTP/1 connection is not reusable');
        $self->_transport_sync if $self->{transport_attached};
        return;
    }
    $self->_start_next;
    return;
}

sub _transaction_write {
    my ($self, $tx, $bytes, $final) = @_;
    croak 'write(): Transaction is not active on this HTTP/1 connection'
        unless $self->{active} && $self->{active} == $tx;
    my $plan = $tx->{send_plan};
    croak 'write(): request does not have a streaming body' unless $tx->{stream_body};
    croak 'write(): streaming request body is already complete' if $tx->{local_done};
    $bytes = Unblock::HTTP1::_Wire::_bytes('request body chunk', $bytes);

    if ($plan->{mode} eq 'chunked') {
        $self->_queue_output(Unblock::HTTP1::_Wire::chunk($bytes));
        if ($final) {
            my $trailers = Unblock::HTTP1::_Wire::_fields($tx->request, 'trailer');
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
    } else {
        croak 'write(): invalid streaming request framing mode';
    }

    $self->_retire_if_done if $tx->{local_done};
    $self->_transport_sync if $self->{transport_attached};
    my $ok = $self->_stream_ok;
    $tx->{blocked} = 1 unless $ok;
    return $ok;
}

sub _deliver_switch_notice {
    my ($self, $tx, $response) = @_;
    my $result = $tx->_invoke('on_switch', $response);
    $tx->_notify_finish;
    $self->_connection_error($result) unless $result eq '1';
    return;
}

sub _transaction_respond { croak 'respond(): client Transactions cannot send responses' }
sub _transaction_informational { croak 'send_informational(): client Transactions cannot send responses' }

sub _transaction_cancel {
    my ($self, $tx) = @_;
    return if $tx->is_terminal;
    $tx->_mark_cancelled;
    $self->{rx} = undef;
    $self->{active} = undef if $self->{active} && $self->{active} == $tx;
    $self->{closed} = 1;
    $self->_fail_all('HTTP/1 connection closed after cancellation');
    $self->_transport_abort('HTTP/1 transaction cancelled')
        if $self->{transport_attached};
    $tx->_notify_finish;
    return;
}

sub _maybe_drain {
    my ($self) = @_;
    my $tx = $self->{active} or return;
    return unless $tx->{blocked};
    $tx->{blocked} = 0;
    my $cb = $tx->_invoke('on_drain');
    $self->_connection_error($cb) unless $cb eq '1';
    return;
}

sub _on_eof {
    my ($self) = @_;
    return if $self->{switched};
    my $tx = $self->{active};
    if (!$tx) {
        $self->{closed} = 1;
        return;
    }
    my $rx = $self->{rx};
    if ($rx && $rx->{mode} eq 'close') {
        if (length $self->{input}) {
            my $bytes = substr($self->{input}, 0, length($self->{input}), '');
            my $cb = $tx->_receive_data($rx->{response}, $bytes);
            return $self->_connection_error($cb) unless $cb eq '1';
        }
        $rx->{keep_alive} = 0;
        $self->_finish_response;
        $self->{closed} = 1;
        return;
    }
    $self->_connection_error('unexpected EOF in HTTP/1 response');
    return;
}

sub _connection_error {
    my ($self, $error) = @_;
    $error = 'HTTP/1 client protocol error' unless defined($error) && length($error);
    my $tx = delete $self->{active};
    $self->{rx} = undef;
    $self->{closed} = 1;
    $self->_input_clear;
    if ($tx && !$tx->is_terminal) {
        $tx->_fail($error);
        $tx->_invoke('on_error', $error);
        $tx->_notify_finish;
    }
    $self->_fail_queued($error);
    $self->_transport_abort($error) if $self->{transport_attached};
    return;
}

sub _fail_queued {
    my ($self, $error) = @_;
    for my $tx (@{ delete($self->{queue}) || [] }) {
        next if $tx->is_terminal;
        $tx->_fail($error);
        eval { $tx->_invoke('on_error', $error) };
        $tx->_notify_finish;
    }
    $self->{queue} = [];
    return;
}

sub _fail_all {
    my ($self, $error) = @_;
    if (my $tx = delete $self->{active}) {
        if (!$tx->is_terminal) {
            $tx->_fail($error);
            eval { $tx->_invoke('on_error', $error) };
            $tx->_notify_finish;
        }
    }
    $self->{rx} = undef;
    $self->_fail_queued($error);
    return;
}

1;

__END__

=head1 NAME

Unblock::HTTP1::Client - One non-blocking HTTP/1 client connection

=head1 SYNOPSIS

    use Unblock::HTTP1::Client;

    my $client = Unblock::HTTP1::Client->new(
        transport => $transport,
    );

    my $tx = $client->request(
        method    => 'GET',
        target    => '/',
        authority => 'example.com',

        on_response => sub {
            my ($tx, $response) = @_;
            print $response->status, "\n";
        },

        on_body => sub {
            my ($tx, $response, $bytes) = @_;
            consume($bytes);
        },

        on_complete => sub {
            my ($tx) = @_;
            print "done\n";
        },
    );

=head1 DESCRIPTION

C<Unblock::HTTP1::Client> owns the HTTP/1 protocol state for one client
connection.

It does not open a socket, perform DNS, negotiate TLS, or run an event loop.
Those jobs belong to the host framework.

Supply C<transport =E<gt> $host> to C<new()> to deliver outgoing wire
bytes automatically through the host. The host owns its socket and implements
C<unblock_send()>, C<unblock_finish()>, and C<unblock_abort()>.
See L<Unblock::HTTP1::Integration> for a complete example and the contract.

The lower-level form is:

    my $client = Unblock::HTTP1::Client->new;

In that mode the caller feeds input with C<input()> and drains output with
C<output()>.

One Client object represents one HTTP/1 connection. Requests may be queued, but
this implementation sends them serially. It does not enable HTTP/1 pipelining.

=head1 RECEIVE BODY OPTIONS

C<receive_body> accepts C<buffered> or C<stream>. Streaming remains the default.
C<max_buffered_body_bytes> is a positive byte limit, defaulting to 64 MiB.
Zero does not mean unlimited. Buffered reception installs the body on the
same Uniform message before freezing it and invoking the body-completion
callback. Empty completed bodies have an empty string representation.
The engine releases retained chunks on failure or cancellation.

Select streaming per transaction with C<$tx-E<gt>on_data(...)> during the
header callback. Do not combine buffered mode with legacy C<on_body>.
Do not combine C<on_data> and C<on_body>. See
L<Unblock::HTTP1::Transaction/RECEIVE AND FINISH CALLBACKS>.

A buffer limit failure closes the HTTP/1 connection.
It does not call successful body completion.

=head1 CONSTRUCTOR

=head2 new

    my $client = Unblock::HTTP1::Client->new(%options);

Creates one client protocol engine.

Common options are:

=over 4

=item C<transport>

Optional framework-owned object implementing C<unblock_send($bytes)>,
C<unblock_finish()>, and C<unblock_abort($reason)>.
The engine holds a weak reference to it. See L<Unblock::HTTP1::Integration>.

=item C<max_head_size>

Maximum response head size in bytes. Default: 65536.

=item C<max_headers>

Maximum number of header or trailer fields. Default: 100.

=item C<max_chunk_extension_size>

Maximum total chunk-extension bytes allowed for one chunked message.
Default: 16384.

=item C<high_water>

High-water mark for the HTTP output queue. Default: 65536.

=item C<low_water>

Low-water mark used to resume a blocked streaming producer. Default: 32768.

=back

=head1 REQUESTS

=head2 request

    my $tx = $client->request(
        method    => 'GET',
        target    => '/',
        authority => 'example.com',
        on_response => sub { ... },
    );

Queues one HTTP request and returns an L<Unblock::HTTP1::Transaction>.

The normal form accepts request fields directly. C<request()> constructs the
canonical L<Uniform::HTTP::Request> internally.

If the caller already has a Uniform request object it can be passed directly:

    my $tx = $client->request(
        $request,
        on_response => sub { ... },
    );

Request fields and transaction options are intentionally separate. In the
concise form these names are consumed by the HTTP transaction rather than
passed to C<Uniform::HTTP::Request-E<gt>new()>:

    stream_body
    on_informational
    on_response
    on_body
    on_data
    on_complete
    on_error
    on_finish
    on_switch
    on_drain

All other fields are request-construction fields.

Requests are queued in call order. The next request starts only after the
current transaction completes and the connection is reusable.

=head2 transaction

    my $tx = $client->transaction;

Returns the currently active transaction, or undef when no request is active.

Queued transactions are not returned by this method.

=head1 REQUEST CALLBACKS

Callbacks belong to the transaction returned by C<request()>.

=head2 on_informational

    on_informational => sub {
        my ($tx, $response) = @_;
    }

Called for each informational response from 100 through 199, except 101.

The C<$response> is a canonical L<Uniform::HTTP::Response>. A 101 response is
handled as a protocol switch and goes to C<on_switch> instead.

=head2 on_response

    on_response => sub {
        my ($tx, $response) = @_;
    }

Called once when the final response head has been parsed.

The response body may not have arrived yet. Body bytes are delivered later
through C<on_body>.

=head2 on_body

    on_body => sub {
        my ($tx, $response, $bytes) = @_;
    }

Called zero or more times with response body bytes.

HTTP transfer framing such as chunk boundaries has already been removed.
Unblock does not automatically decode content codings such as gzip.

=head2 on_data

    on_data => sub {
        my ($tx, $bytes) = @_;
    }

Receives decoded response body chunks without buffering the full body.
Supplying C<on_data> to C<request()> selects streaming for that transaction.
Do not combine C<on_data> with C<on_body>.

=head2 on_complete

    on_complete => sub {
        my ($tx) = @_;
    }

Called when the complete request/response exchange is finished.

For a streaming request body, completion requires the local request body to be
finished as well as the final response to be complete.

=head2 on_error

    on_error => sub {
        my ($tx, $error) = @_;
    }

Called when the transaction fails.

Protocol errors, unexpected EOF, callback failures, transport failure, or a
non-reusable connection that invalidates queued work can lead here.

The transaction state is C<error> when this callback is invoked.

=head2 on_finish

    on_finish => sub {
        my ($tx) = @_;
    }

Called once after the transaction becomes complete, cancelled, or errored.
Unlike C<on_complete>, it also covers unsuccessful terminal outcomes.
See L<Unblock::HTTP1::Transaction/RECEIVE AND FINISH CALLBACKS>.

=head2 on_switch

    on_switch => sub {
        my ($tx, $response) = @_;
    }

Called when a 101 response or successful CONNECT transfers ownership of the
connection away from HTTP.

After this callback, C<is_switched()> is true. Any bytes already read beyond
the HTTP boundary can be obtained with C<take_remainder()>.

Queued HTTP requests cannot continue after a switch.

=head2 on_drain

    on_drain => sub {
        my ($tx) = @_;
    }

Used only with C<stream_body =E<gt> 1>.

If C<$tx-E<gt>write()> returns false, the supplied bytes were accepted but the
producer should pause. C<on_drain> runs when the HTTP output path becomes
writable again.

=head1 STREAMING REQUEST BODIES

Use C<stream_body> when the request body is produced incrementally:

    my $tx = $client->request(
        method      => 'POST',
        target      => '/upload',
        authority   => 'example.com',
        stream_body => 1,
        on_drain    => sub { produce_more() },
    );

    $tx->write($chunk);
    $tx->end($last_chunk);

C<write()> and C<end()> are methods on the Transaction.

For HTTP/1.1, chunked transfer framing is used when required. An explicit
Content-Length is honored and enforced.

A false return from C<write()> means the bytes were accepted but the producer
should wait for C<on_drain> before producing more.

=head1 CONNECTION INPUT

=head2 input

    my $accepted = $client->input($bytes);

Feeds received response bytes into the engine.

The portable input path copies the supplied bytes into engine-owned storage as
needed. The return value is the number of supplied bytes accepted by the
engine.

Do not call C<input()> recursively from an HTTP callback.

=head2 input_eof

    $client->input_eof;

Reports a clean read-side EOF. It completes a close-delimited response body
when allowed by HTTP framing; premature EOF fails an incomplete exchange.
Do not use C<input('')> as EOF or report ordinary EOF as transport failure.

=head2 transport_error

    $client->transport_error($reason);

Reports a broken socket, TLS failure, or other unusable transport. Unsent
HTTP output is discarded; outstanding work fails and C<unblock_abort()> is
called. Do not call this on ordinary read-side EOF.

=head1 CONNECTION OUTPUT

=head2 want_write

    if ($client->want_write) {
        ...
    }

True when the engine has bytes buffered for output.

Normally unnecessary when a transport is attached because output is forwarded
automatically.

=head2 output

    my $bytes = $client->output;
    my $bytes = $client->output($maximum);

Removes and returns queued wire bytes in manual integration mode.
C<output()> throws when a transport is attached to prevent mixed ownership.

C<$maximum>, when supplied, must be a positive integer.

Draining the queue below the low-water mark may trigger transaction
C<on_drain>.

Do not call C<output()> recursively from an HTTP callback.

=head2 resume_output

    $client->resume_output;

Called by an attached host after C<unblock_send()> returned a defined false
value (meaning complete acceptance followed by congestion). The host must
call this again when it can accept more output. It can trigger a streaming
Transaction's C<on_drain> callback.

An output-queueing host that always returns undef does not need it.

=head1 CONNECTION STATE

=head2 want_read

    $client->want_read;

True while the engine is still accepting HTTP input.

It becomes false after read EOF, close, or protocol switch.

=head2 is_closed

    $client->is_closed;

True when the HTTP connection is closed.

=head2 is_switched

    $client->is_switched;

True after HTTP ownership ended because of 101 or successful CONNECT.

=head2 take_remainder

    my $bytes = $client->take_remainder;

Returns bytes already received after the HTTP protocol boundary.

This method is valid only after C<is_switched()> becomes true.

=head2 close

    $client->close;
    $client->close($reason);

Closes the HTTP engine and fails unfinished transactions.

With an attached transport, already queued HTTP output is handed to the
transport before graceful close when possible.

Use C<transport_error()> instead when the transport itself has failed.

=head1 TRANSACTION OBJECTS

C<request()> returns L<Unblock::HTTP1::Transaction>.

Use that object for:

    request
    response
    write
    end
    cancel
    state
    error
    is_complete
    is_cancelled
    is_error
    is_terminal

=head1 NATIVE INPUT

XS-backed transports can use L<Unblock::HTTP1::NativeABI> to feed borrowed
native buffers without changing the Client object or application API.

The normal C<input()> method remains the portable correctness path.

=head1 SEE ALSO

L<Unblock::HTTP1::Integration>,
L<Unblock::HTTP1>,
L<Unblock::HTTP1::Transaction>,
L<Unblock::HTTP1::NativeABI>,
L<Uniform::HTTP::Request>,
L<Uniform::HTTP::Response>

=cut
