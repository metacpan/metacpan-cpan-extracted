package Unblock::HTTP1::Client;

use strict;
use warnings;
use Carp qw(croak);
use parent 'Unblock::HTTP1::_Engine';

use Uniform::HTTP::Response;
use Unblock::HTTP1::_Native ();
use Unblock::HTTP1::_Wire ();
use Unblock::HTTP1::Transaction;

our $VERSION = '0.10';

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
    my ($self, $request, %option) = @_;
    croak 'request(): connection is closed' if $self->{closed};
    croak 'request(): connection has switched protocols' if $self->{switched};
    croak 'request(): requires a Uniform HTTP request object'
        unless ref($request) && $request->can('method') && $request->can('target')
            && $request->can('header_count') && $request->can('has_buffered_body');

    my $stream_body = delete($option{stream_body}) ? 1 : 0;
    my %callbacks;
    for my $name (qw(on_informational on_response on_body on_complete on_error on_switch on_drain)) {
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
        $tx->_invoke('on_error', "$@");
        return $self->_start_next;
    }
    $tx->{send_plan} = $plan;
    $tx->{local_done} = $plan->{body_finalized} ? 1 : 0;
    $self->{active} = $tx;
    $self->_queue_output($plan->{wire});
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

    local $self->{borrowed_head} = $head;
    local $self->{borrowed_message} = $response;
    local $self->{native_head_preconsumed} = 1;
    local $self->{driving} = 1;
    $self->_drive;

    my $status = $self->{closed} ? 3 : $self->{switched} ? 4 : 0;
    return ($status, $self->_borrowed_native_head_ready);
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
                $response->mark_complete->freeze;
                $tx->_mark_remote_done;
                $tx->_mark_complete;
                $self->{rx} = undef;
                $self->_mark_switched;
                $self->_fail_queued('HTTP/1 connection switched protocols');
                my $switch_cb = $tx->_invoke('on_switch', $response);
                $self->{active} = undef;
                return $self->_connection_error($switch_cb) unless $switch_cb eq '1';
                return;
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
                    my $body_cb = $tx->_invoke('on_body', $response, $bytes);
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
            my $cb = $tx->_invoke('on_body', $rx->{response}, $bytes);
            return $self->_connection_error($cb) unless $cb eq '1';
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
                my $cb = $tx->_invoke('on_body', $rx->{response}, $decoded);
                return $self->_connection_error($cb) unless $cb eq '1';
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
            my $cb = $tx->_invoke('on_body', $rx->{response}, $bytes);
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
        return;
    }

    if (!$keep) {
        $self->{closed} = 1;
        $self->_fail_queued('HTTP/1 connection is not reusable');
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

    my $ok = $self->_stream_ok;
    $tx->{blocked} = 1 unless $ok;
    $self->_retire_if_done if $tx->{local_done};
    return $ok;
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
    $self->_fail_queued('HTTP/1 connection closed after cancellation');
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
            my $cb = $tx->_invoke('on_body', $rx->{response}, $bytes);
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
    my $tx = $self->{active};
    if ($tx && !$tx->is_terminal) {
        $tx->_fail($error);
        eval { $tx->_invoke('on_error', $error) };
    }
    $self->{active} = undef;
    $self->{rx} = undef;
    $self->{closed} = 1;
    $self->_fail_queued($error);
    return;
}

sub _fail_queued {
    my ($self, $error) = @_;
    for my $tx (@{ delete($self->{queue}) || [] }) {
        next if $tx->is_terminal;
        $tx->_fail($error);
        eval { $tx->_invoke('on_error', $error) };
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
        }
    }
    $self->{rx} = undef;
    $self->_fail_queued($error);
    return;
}

1;

__END__

=head1 NAME

Unblock::HTTP1::Client - Standalone HTTP/1 client protocol engine

=head1 DESCRIPTION

This object owns one HTTP/1 client connection's protocol state. It does not
open a socket or run an event loop. Feed received bytes with C<input()>, signal
transport EOF with C<input_eof()>, and drain generated wire bytes with
C<output()>.

Requests are queued serially. This Client API intentionally does not pipeline
requests on one connection. Callers that need parallel HTTP/1 work can use
multiple connections without changing the protocol engine.

=head1 REQUEST CALLBACKS

C<request()> accepts these callbacks:

    on_informational => sub { my ($transaction, $response) = @_ }
    on_response      => sub { my ($transaction, $response) = @_ }
    on_body          => sub { my ($transaction, $response, $bytes) = @_ }
    on_complete      => sub { my ($transaction) = @_ }
    on_error         => sub { my ($transaction, $error) = @_ }
    on_switch        => sub { my ($transaction, $response) = @_ }
    on_drain         => sub { my ($transaction) = @_ }

C<on_drain> is used with C<stream_body =E<gt> 1>.

When a 101 response or successful CONNECT switches away from HTTP, the engine
stops HTTP parsing. C<take_remainder()> returns bytes that followed the HTTP
head in the same transport read.

=cut
