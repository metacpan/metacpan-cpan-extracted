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

our $VERSION = '0.10';

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

    local $self->{borrowed_head} = $head;
    local $self->{borrowed_message} = $request;
    local $self->{native_head_preconsumed} = 1;
    local $self->{driving} = 1;
    $self->_drive;

    my $status = $self->{closed} ? 3 : $self->{switched} ? 4 : 0;
    return ($status, $self->_borrowed_native_head_ready);
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
        my $cb = $self->_invoke_server('on_switch', $tx, $response);
        $self->{active} = undef;
        return $self->_application_error($cb) unless $cb eq '1';
        return;
    }
    $tx->_mark_complete unless $tx->is_terminal;
    my $keep = $tx->{keep_alive};
    $keep = $tx->{request_keep_alive} unless defined $keep;
    $self->{active} = undef;
    if (!$keep) {
        $self->{closed} = 1;
        return;
    }
    return if $self->{driving};
    local $self->{driving} = 1;
    $self->_drive if $self->_input_length;
    return;
}

sub _transaction_cancel {
    my ($self, $tx) = @_;
    return if $tx->is_terminal;
    $tx->_mark_cancelled;
    $self->{active} = undef if $self->{active} && $self->{active} == $tx;
    $self->{rx} = undef;
    $self->{closed} = 1;
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

Unblock::HTTP1::Server - Standalone HTTP/1 server protocol engine

=head1 SYNOPSIS

    use Uniform::HTTP::Response;
    use Unblock::HTTP1::Server;

    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx, $request) = @_;
            $tx->respond(Uniform::HTTP::Response->new(
                status => 200,
                body   => "hello\n",
            ));
        },
    );

=head1 DESCRIPTION

This object owns one HTTP/1 server connection's protocol state. It does not
create a listener, socket, TLS session, or event loop.

Incoming request bodies are delivered with C<on_body>. C<on_request_end> runs
after the full request, including trailers, is complete. Informational
responses can be sent with C<send_informational()> on the Transaction.

=head1 CALLBACKS

C<new()> accepts these callbacks:

    on_request     => sub { my ($transaction, $request) = @_ }
    on_body        => sub { my ($transaction, $request, $bytes) = @_ }
    on_request_end => sub { my ($transaction, $request) = @_ }
    on_error       => sub { my ($transaction, $error) = @_ }
    on_switch      => sub { my ($transaction, $response) = @_ }

C<on_request> is required.

A 101 response or successful CONNECT switches the engine out of HTTP mode.
Bytes already read after the HTTP request are preserved by C<take_remainder()>.

=cut
