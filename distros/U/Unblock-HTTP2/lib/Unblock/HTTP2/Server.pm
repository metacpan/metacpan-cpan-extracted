package Unblock::HTTP2::Server;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(weaken);
use parent 'Unblock::HTTP2::_Connection';

use Unblock::HTTP2::_Headers;
use Unblock::HTTP2::Transaction;

our $VERSION = '0.11';

use constant {
    H2_DATA              => 0,
    H2_HEADERS           => 1,
    H2_GOAWAY            => 7,
    H2_END_STREAM        => 0x1,
    H2_INTERNAL_ERROR    => 2,
    H2_CANCEL            => 8,
    H2_ENHANCE_YOUR_CALM => 11,
};

my $BODY_HIGH_WATER = 65_536;
my $BODY_LOW_WATER  = 32_768;

sub new {
    my ($class, %option) = @_;
    my $transport = delete $option{transport};

    my %callbacks;
    for my $name (qw(
        on_request on_body on_request_end on_error
        on_settings on_settings_ack on_ping on_ping_ack on_priority
        on_invalid_frame
    )) {
        next unless exists $option{$name};
        my $callback = delete $option{$name};
        croak "new(): $name must be a coderef"
            if defined($callback) && ref($callback) ne 'CODE';
        $callbacks{$name} = $callback if $callback;
    }

    my $settings = exists($option{settings})
        ? delete($option{settings})
        : {};
    croak 'new(): settings must be a hash reference'
        unless ref($settings) eq 'HASH';

    my $max_concurrent_streams = exists($option{max_concurrent_streams})
        ? delete($option{max_concurrent_streams})
        : 100;
    my $max_header_list_size = exists($option{max_header_list_size})
        ? delete($option{max_header_list_size})
        : 65_536;
    my $enable_connect_protocol = exists($option{enable_connect_protocol})
        ? delete($option{enable_connect_protocol})
        : 1;

    croak 'new(): max_concurrent_streams must be a positive integer'
        unless defined($max_concurrent_streams)
            && !ref($max_concurrent_streams)
            && $max_concurrent_streams =~ /\A[0-9]+\z/
            && $max_concurrent_streams > 0;
    croak 'new(): max_header_list_size must be a positive integer'
        unless defined($max_header_list_size)
            && !ref($max_header_list_size)
            && $max_header_list_size =~ /\A[0-9]+\z/
            && $max_header_list_size > 0;
    croak 'new(): enable_connect_protocol must be zero or one'
        if !defined($enable_connect_protocol)
            || ref($enable_connect_protocol)
            || "$enable_connect_protocol" !~ /\A[01]\z/;
    $enable_connect_protocol = $enable_connect_protocol ? 1 : 0;

    croak 'new(): unknown options: ' . join(', ', sort keys %option)
        if %option;

    require Unblock::HTTP2::_nghttp2;
    croak 'new(): nghttp2 library is unavailable'
        unless Unblock::HTTP2::_nghttp2->available;

    my $self = bless {
        callbacks               => \%callbacks,
        draining                => 0,
        max_concurrent_streams  => 0 + $max_concurrent_streams,
        max_header_list_size    => 0 + $max_header_list_size,
        enable_connect_protocol => $enable_connect_protocol,
        last_peer_stream_id     => 0,
        receive                 => {},
        providers               => {},
        peer_goaway              => undef,
    }, $class;

    my $weak = $self;
    weaken($weak);

    my $session = Unblock::HTTP2::_nghttp2::Session->new_server(
        max_header_list_size => $self->{max_header_list_size},
        callbacks => {
            on_begin_headers => sub {
                my $self = $weak or return 0;
                return $self->_on_begin_headers(@_);
            },
            on_frame_recv => sub {
                my $self = $weak or return 0;
                return $self->_on_frame_recv(@_);
            },
            on_data_chunk_recv => sub {
                my $self = $weak or return 0;
                return $self->_on_data_chunk_recv(@_);
            },
            on_stream_close => sub {
                my $self = $weak or return 0;
                return $self->_on_stream_close(@_);
            },
            on_invalid_frame => sub {
                my $self = $weak or return 0;
                return $self->_on_invalid_frame(@_);
            },
        },
    );

    $self->_initialize_connection(
        $session,
        role      => 'server',
        callbacks => \%callbacks,
        transport => $transport,
    );

    my %initial_settings = (
        max_concurrent_streams  => $self->{max_concurrent_streams},
        max_header_list_size    => $self->{max_header_list_size},
        enable_connect_protocol => $self->{enable_connect_protocol},
        no_rfc7540_priorities   => 1,
        %$settings,
    );
    $self->_submit_settings('new()', \%initial_settings);
    $self->_transport_sync if $self->{transport_attached};

    return $self;
}
sub draining {
    return $_[0]{draining} ? 1 : 0;
}

sub peer_goaway {
    my ($self) = @_;
    return unless $self->{peer_goaway};
    return { %{ $self->{peer_goaway} } };
}

sub drain {
    my ($self) = @_;
    return $self if $self->is_closed || $self->{draining};
    return $self->goaway(error_code => 0);
}

sub _on_begin_headers {
    my ($self, $stream_id) = @_;

    $self->{last_peer_stream_id} = $stream_id
        if $stream_id > $self->{last_peer_stream_id};

    $self->{receive}{$stream_id} ||= {
        request_end_called => 0,
    };

    return 0;
}

sub _on_frame_recv {
    my ($self, $frame) = @_;

    return 0 if $self->_handle_settings_frame($frame);
    return 0 if $self->_handle_ping_frame($frame);
    return 0 if $self->_handle_priority_update_frame($frame);

    if (($frame->{type} // -1) == H2_GOAWAY) {
        $self->{draining} = 1;
        $self->{peer_goaway} = {
            last_stream_id => 0 + ($frame->{last_stream_id} // 0),
            error_code     => 0 + ($frame->{error_code} // 0),
            debug_data     => defined($frame->{debug_data})
                ? "$frame->{debug_data}"
                : '',
        };
        return 0;
    }

    my $stream_id = $frame->{stream_id} || 0;
    return 0 unless $stream_id;

    my $state = $self->{receive}{$stream_id} or return 0;

    if (($frame->{type} // -1) == H2_HEADERS) {
        if (defined $frame->{header_error}) {
            $self->_stream_failure(
                $stream_id,
                "$frame->{header_error}",
                $frame->{header_error_code},
            );
            return 0;
        }

        my $transaction = $self->transaction_for_stream_id($stream_id);

        if (!$transaction) {
            my $request = $frame->{uniform_message};
            if (!$request) {
                $self->_stream_failure(
                    $stream_id,
                    'HTTP/2 request header block did not produce a Uniform request',
                );
                return 0;
            }

            $transaction = Unblock::HTTP2::Transaction->_new(
                connection => $self,
                stream_id  => $stream_id,
                request    => $request,
                callbacks  => {},
            );
            $self->_register_transaction($transaction);

            my $result = $self->_invoke_callback(
                'on_request', $transaction, $request,
            );
            if ($result ne '1') {
                $self->_stream_failure($stream_id, "$result");
                return 0;
            }

            if (($frame->{flags} || 0) & H2_END_STREAM) {
                $self->_request_end($stream_id);
            }

            return 0;
        }

        if (!(($frame->{flags} || 0) & H2_END_STREAM)) {
            $self->_stream_failure(
                $stream_id,
                'HTTP/2 trailing HEADERS must end the stream',
            );
            return 0;
        }

        my $ok = eval {
            Unblock::HTTP2::_Headers->apply_trailers(
                $transaction->request,
                $frame->{native_headers} || [],
            );
            1;
        };
        if (!$ok) {
            $self->_stream_failure($stream_id, "$@");
            return 0;
        }

        $self->_request_end($stream_id);
        return 0;
    }

    if (($frame->{type} // -1) == H2_DATA
        && (($frame->{flags} || 0) & H2_END_STREAM)) {
        $self->_request_end($stream_id);
    }

    return 0;
}

sub _on_data_chunk_recv {
    my ($self, $stream_id, $data, $flags) = @_;
    my $transaction = $self->transaction_for_stream_id($stream_id) or return 0;

    $transaction->_receive_body_bytes(length $data);

    my $result = $self->_invoke_callback(
        'on_body', $transaction, $transaction->request, $data,
    );

    if ($result ne '1') {
        $self->_stream_failure($stream_id, "$result");
        return 0;
    }

    $transaction->_auto_consume_body;
    return 0;
}

sub _request_end {
    my ($self, $stream_id) = @_;
    my $state = $self->{receive}{$stream_id} or return;
    return if $state->{request_end_called}++;

    my $transaction = $self->transaction_for_stream_id($stream_id) or return;
    $transaction->request->mark_complete->freeze;

    my $result = $self->_invoke_callback(
        'on_request_end', $transaction, $transaction->request,
    );
    $self->_stream_failure($stream_id, "$result")
        unless $result eq '1';
    return;
}
sub _invoke_callback {
    my ($self, $name, @args) = @_;
    my $callback = $self->{callbacks}{$name} or return 1;

    my $ok = eval {
        $callback->(@args);
        1;
    };

    return $ok ? 1 : $@;
}

sub _on_invalid_frame {
    my ($self, $frame, $lib_error_code) = @_;

    my $copy = ref($frame) eq 'HASH' ? { %$frame } : {};
    $self->_invoke_control_callback(
        'on_invalid_frame',
        $copy,
        0 + ($lib_error_code || 0),
    );
    return 0;
}

sub _send_informational_stream {
    my ($self, $transaction, $response) = @_;

    my $native_message = Unblock::HTTP2::_Headers->native_message($response);
    croak 'send_informational(): requires the Uniform HTTP response contract'
        unless $native_message
            || Unblock::HTTP2::_Headers::_response_contract($response);
    croak 'send_informational(): final Response already submitted'
        if $transaction->response;

    my $status = $response->status;
    croak 'send_informational(): status must be informational (100-199, excluding 101)'
        unless defined($status) && !ref($status)
            && $status =~ /\A[0-9]+\z/
            && $status >= 100 && $status < 200 && $status != 101;
    croak 'send_informational(): informational Response must not have a buffered body'
        if $response->has_buffered_body;

    my $trailers = Unblock::HTTP2::_Headers->trailer_fields(
        'send_informational()', $response,
    );
    croak 'send_informational(): informational Response must not have trailers'
        if @$trailers;

    if ($native_message) {
        $self->{session}->submit_response_headers_uniform(
            $transaction->stream_id,
            $native_message,
        );
    }
    else {
        my $block = Unblock::HTTP2::_Headers->response_headers($response);
        $self->{session}->submit_headers(
            $transaction->stream_id,
            headers => $block,
        );
    }

    $self->_transport_sync if $self->{transport_attached};
    return $transaction;
}

sub _respond_stream {
    my ($self, $transaction, $response, %option) = @_;

    my $native_message = Unblock::HTTP2::_Headers->native_message($response);
    croak 'respond(): requires the Uniform HTTP response contract'
        unless $native_message
            || Unblock::HTTP2::_Headers::_response_contract($response);
    croak 'respond(): Transaction already has a Response'
        if $transaction->response;

    my $stream_body = exists($option{stream_body})
        ? delete($option{stream_body})
        : 0;
    croak 'respond(): stream_body must be zero or one'
        if !defined($stream_body) || ref($stream_body)
            || "$stream_body" !~ /\A[01]\z/;
    $stream_body = $stream_body ? 1 : 0;

    my $on_drain = delete $option{on_drain};
    my $on_error = delete $option{on_error};

    croak 'respond(): on_drain must be a coderef'
        if defined($on_drain) && ref($on_drain) ne 'CODE';
    croak 'respond(): on_error must be a coderef'
        if defined($on_error) && ref($on_error) ne 'CODE';
    croak 'respond(): unknown options: ' . join(', ', sort keys %option)
        if %option;
    croak 'respond(): on_drain requires stream_body'
        if $on_drain && !$stream_body;
    croak 'respond(): stream_body cannot be combined with a buffered body'
        if $stream_body && $response->has_buffered_body;

    my ($block, @headers);
    if (!$native_message) {
        $block = Unblock::HTTP2::_Headers->response_headers($response);
        @headers = @$block[1 .. $#$block];
    }
    my $trailers = Unblock::HTTP2::_Headers->trailer_fields(
        'respond()', $response,
    );

    my $provider;
    if ($stream_body || @$trailers) {
        $provider = {
            queue             => '',
            eof               => 0,
            blocked           => 0,
            stream_id         => $transaction->stream_id,
            trailers          => undef,
            trailer_submitted => 0,
        };

        if (!$stream_body) {
            $provider->{queue} = $response->has_buffered_body
                ? $response->body
                : '';
            $provider->{eof} = 1;
            $provider->{trailers} = $trailers if @$trailers;
        }

        my $weak_self = $self;
        weaken($weak_self);

        my $data_callback = sub {
            my $self = $weak_self or return ('', 1);
            return $self->_provide_body($provider, @_);
        };

        if ($native_message) {
            $self->{session}->submit_response_uniform(
                $transaction->stream_id,
                $native_message,
                data_callback => $data_callback,
            );
        }
        else {
            $self->{session}->submit_response(
                $transaction->stream_id,
                status        => $response->status,
                headers       => \@headers,
                data_callback => $data_callback,
            );
        }
    }
    elsif ($response->has_buffered_body) {
        if ($native_message) {
            $self->{session}->submit_response_uniform(
                $transaction->stream_id,
                $native_message,
                body => $response->body,
            );
        }
        else {
            $self->{session}->submit_response(
                $transaction->stream_id,
                status  => $response->status,
                headers => \@headers,
                body    => $response->body,
            );
        }
    }
    else {
        if ($native_message) {
            $self->{session}->submit_response_uniform(
                $transaction->stream_id,
                $native_message,
            );
        }
        else {
            $self->{session}->submit_response(
                $transaction->stream_id,
                status  => $response->status,
                headers => \@headers,
            );
        }
    }

    $transaction->_set_response($response);
    $transaction->_set_callback('on_drain', $on_drain) if $on_drain;
    $transaction->_set_callback('on_error', $on_error) if $on_error;

    if ($provider) {
        $self->{providers}{ $transaction->stream_id } = $provider;
    }

    $self->_transport_sync if $self->{transport_attached};
    return $transaction;
}
sub _provide_body {
    my ($self, $provider, $stream_id, $max_length) = @_;

    if (!length($provider->{queue})) {
        if ($provider->{eof}) {
            if ($provider->{trailers}
                && !$provider->{trailer_submitted}) {
                $self->_submit_provider_trailers($provider);
                return ('', 1, 1);
            }
            return ('', 1);
        }
        return;
    }

    my $take = length($provider->{queue}) < $max_length
        ? length($provider->{queue})
        : $max_length;
    my $chunk = substr($provider->{queue}, 0, $take, '');
    my $eof = $provider->{eof} && !length($provider->{queue}) ? 1 : 0;
    my $no_end_stream = 0;

    if ($eof && $provider->{trailers}
        && !$provider->{trailer_submitted}) {
        $self->_submit_provider_trailers($provider);
        $no_end_stream = 1;
    }

    if ($provider->{blocked}
        && length($provider->{queue}) < $BODY_LOW_WATER) {
        $provider->{blocked} = 0;
        $self->_queue_drain($provider->{stream_id});
    }

    return $no_end_stream
        ? ($chunk, $eof, 1)
        : ($chunk, $eof);
}

sub _submit_provider_trailers {
    my ($self, $provider) = @_;
    return if $provider->{trailer_submitted};

    $self->{session}->submit_trailer(
        $provider->{stream_id},
        headers => $provider->{trailers} || [],
    );
    $provider->{trailer_submitted} = 1;
    return;
}
sub _write_stream_body {
    my ($self, $transaction, $bytes, $final, $operation) = @_;

    my $provider = $self->{providers}{ $transaction->stream_id }
        or croak "$operation(): Transaction has no streaming Response body";

    $bytes = $self->_body_bytes("$operation()", $bytes);
    croak "$operation(): streaming Response body is already complete"
        if $provider->{eof};

    $provider->{queue} .= $bytes;

    if ($final) {
        my $trailers = Unblock::HTTP2::_Headers->trailer_fields(
            "$operation()", $transaction->response,
        );
        $provider->{trailers} = $trailers if @$trailers;
        $provider->{eof} = 1;
    }

    if ($self->{session}->is_stream_deferred($transaction->stream_id)) {
        $self->{session}->resume_stream($transaction->stream_id);
    }

    my $blocked = length($provider->{queue}) >= $BODY_HIGH_WATER;
    $provider->{blocked} = 1 if $blocked;
    $self->_transport_sync if $self->{transport_attached};
    if ($self->{transport_blocked}) {
        $provider->{blocked} = 1;
        return 0;
    }
    return $blocked ? 0 : 1;
}
sub _cancel_stream {
    my ($self, $transaction) = @_;
    return if $transaction->is_terminal;
    $self->_reset_stream($transaction, H2_CANCEL);
    return;
}

sub _stream_failure {
    my ($self, $stream_id, $error, $code) = @_;
    $code = H2_INTERNAL_ERROR unless defined $code;
    $error = 'HTTP/2 stream failure'
        unless defined($error) && length($error);

    my $transaction = $self->transaction_for_stream_id($stream_id);

    if ($transaction && !$transaction->is_terminal) {
        $transaction->_fail($error, $code, 0);
        $self->_invoke_stream_error($transaction, $error, $code);
    }
    elsif (my $callback = $self->{callbacks}{on_error}) {
        eval { $callback->(undef, $error, $code) };
    }

    eval { $self->{session}->submit_rst_stream($stream_id, $code) };
    return;
}

sub _invoke_stream_error {
    my ($self, $transaction, $error, $error_code) = @_;

    my $result = $transaction->_invoke('on_error', $error, $error_code);
    if ($result ne '1') {
        my $callback = $self->{callbacks}{on_error};
        eval { $callback->($transaction, "$result", $error_code) } if $callback;
        return;
    }

    my $callback = $self->{callbacks}{on_error};
    eval { $callback->($transaction, $error, $error_code) } if $callback;
    return;
}

sub _on_stream_close {
    my ($self, $stream_id, $error_code) = @_;
    delete $self->{receive}{$stream_id};
    delete $self->{providers}{$stream_id};

    my $transaction = $self->_remove_transaction($stream_id) or return 0;

    if (!$transaction->is_terminal) {
        if ($error_code) {
            my $error = "HTTP/2 stream closed with error $error_code";
            $transaction->_fail($error, $error_code, 1);
            $self->_invoke_stream_error($transaction, $error, $error_code);
        }
        else {
            if (!$transaction->request->is_complete) {
                $transaction->request->mark_complete->freeze;
            }
            $transaction->_mark_complete;
        }
    }

    return 0;
}
sub close {
    my ($self, @args) = @_;
    $self->SUPER::close(@args);
    $self->{receive} = {};
    $self->{providers} = {};
    return $self;
}

1;

__END__

=head1 NAME

Unblock::HTTP2::Server - one HTTP/2 server connection

=head1 SYNOPSIS

    use Unblock::HTTP2::Server;

    # $stream is an accepted connection owned by your event framework.
    my $server = Unblock::HTTP2::Server->new(
        transport  => $stream,
        on_request => sub {
            my ($tx, $request) = @_;
            $tx->respond(
                status => 200,
                body   => "Hello World!\n",
            );
        },
    );

    # In the framework's read callback:
    $server->input($received_http2_bytes);

The framework stream implements C<unblock_send()>, C<unblock_finish()>,
and C<unblock_abort()>. The Server automatically hands outgoing frames to
the framework. A separate Server is created for each accepted connection,
and each Server may handle many concurrent Transactions.

See L<Unblock::HTTP2::Integration> and F<examples/linux-event-server.pl>
for complete adapter examples.

=head1 DESCRIPTION

A Server owns one HTTP/2 server session.

It does not create a listening socket, own an accepted socket, perform TLS, or
run an event loop.

An optional attached framework host receives wire output automatically.
Without one, drain C<output()> while C<want_write()> is true. See
L<Unblock::HTTP2::Integration>.

=head1 CONSTRUCTOR

C<new()> accepts an initial C<settings> hash, C<max_concurrent_streams>,
C<max_header_list_size>, C<enable_connect_protocol>, and an optional
C<transport> object with C<unblock_send()>, C<unblock_finish()>, and
C<unblock_abort()> methods.

Connection callbacks are:

    on_settings($server, $peer_settings, $changed_settings)
    on_settings_ack($server, $acked_settings)
    on_ping($server, $opaque)
    on_ping_ack($server, $opaque)
    on_priority($server, $stream_id, $field_value)
    on_invalid_frame($server, $frame, $lib_error_code)

=head1 REQUEST CALLBACKS

Request callbacks are:

    on_request($transaction, $request)
    on_body($transaction, $request, $bytes)
    on_request_end($transaction, $request)
    on_error($transaction, $error, $error_code)

C<on_request> runs when the request headers have been accepted.
C<on_request_end> runs after the complete request and any trailers have
arrived. C<$error_code> can be undefined when there is no HTTP/2 reset code.
C<$transaction> can be undefined for an error that occurs before a Transaction
exists.

Use C<send_informational()> for informational responses and C<respond()> for
the final response. Both accept named response fields as well as canonical
Uniform::HTTP::Response objects.

=head1 CONNECTION CONTROL

The Server exposes the common connection methods:

    is_closed
    close_reason
    transaction_count
    transaction_for_stream_id
    local_settings
    local_setting
    peer_settings
    peer_setting
    update_settings
    settings_pending
    ping
    draining
    drain
    goaway
    local_goaway
    peer_goaway
    want_read
    want_write
    input
    output
    input_eof
    transport_error
    resume_output
    close

The server can also observe RFC 9218 priority updates with C<on_priority>.

=head1 SEE ALSO

L<Unblock::HTTP2>, L<Unblock::HTTP2::Integration>,
L<Unblock::HTTP2::Transaction>, L<Uniform::HTTP::Response>

=head1 LICENSE

MIT License.

=cut
