package Unblock::HTTP2::Client;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(weaken);
use parent 'Unblock::HTTP2::_Connection';

use Unblock::HTTP2::_Headers;
use Unblock::HTTP2::Transaction;
use Uniform::HTTP::Request;

our $VERSION = '0.11';

use constant {
    H2_DATA              => 0,
    H2_HEADERS           => 1,
    H2_GOAWAY            => 7,
    H2_END_STREAM        => 0x1,
    H2_PROTOCOL_ERROR    => 1,
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
        on_settings on_settings_ack on_ping on_ping_ack on_invalid_frame
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

    my $max_active_transactions = exists($option{max_active_transactions})
        ? delete($option{max_active_transactions})
        : 100;
    my $max_header_list_size = exists($option{max_header_list_size})
        ? delete($option{max_header_list_size})
        : 65_536;

    croak 'new(): max_active_transactions must be a positive integer'
        unless defined($max_active_transactions) && !ref($max_active_transactions)
            && $max_active_transactions =~ /\A[0-9]+\z/
            && $max_active_transactions > 0;
    croak 'new(): max_header_list_size must be a positive integer'
        unless defined($max_header_list_size) && !ref($max_header_list_size)
            && $max_header_list_size =~ /\A[0-9]+\z/
            && $max_header_list_size > 0;
    croak 'new(): unknown options: ' . join(', ', sort keys %option)
        if %option;

    require Unblock::HTTP2::_nghttp2;
    croak 'new(): nghttp2 library is unavailable'
        unless Unblock::HTTP2::_nghttp2->available;

    my $self = bless {
        draining             => 0,
        max_active_transactions => 0 + $max_active_transactions,
        max_header_list_size => 0 + $max_header_list_size,
        receive              => {},
        providers            => {},
        peer_goaway           => undef,
    }, $class;

    my $weak = $self;
    weaken($weak);

    my $session = Unblock::HTTP2::_nghttp2::Session->new_client(
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
        role      => 'client',
        callbacks => \%callbacks,
        transport => $transport,
    );

    my %initial_settings = (
        max_concurrent_streams => 100,
        max_header_list_size   => $self->{max_header_list_size},
        enable_push            => 0,
        no_rfc7540_priorities  => 1,
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

sub can_open_transaction {
    my ($self) = @_;
    return 0 if $self->is_closed || $self->{draining};

    my $limit = $self->{max_active_transactions};
    my $peer_limit = $self->peer_setting('max_concurrent_streams');
    $limit = $peer_limit if $peer_limit < $limit;

    return $self->transaction_count < $limit ? 1 : 0;
}

sub request {
    my ($self, @arg) = @_;

    my ($request, %option);
    if (@arg && ref($arg[0])) {
        $request = shift @arg;
        croak 'request(): options must be key/value pairs' if @arg % 2;
        %option = @arg;
    }
    else {
        croak 'request(): fields must be key/value pairs' if @arg % 2;
        my %field = @arg;
        for my $name (qw(
            stream_body on_response on_body on_complete on_error
            on_informational on_drain
        )) {
            $option{$name} = delete $field{$name} if exists $field{$name};
        }
        $request = Uniform::HTTP::Request->new(%field);
    }

    croak 'request(): connection is closed' if $self->is_closed;
    croak 'request(): connection cannot accept another transaction'
        unless $self->can_open_transaction;
    my $native_message = Unblock::HTTP2::_Headers->native_message($request);
    croak 'request(): requires the Uniform HTTP request contract'
        unless $native_message
            || Unblock::HTTP2::_Headers::_request_contract($request);

    if (defined($request->protocol) && length($request->protocol)) {
        my $enabled = $self->peer_setting('enable_connect_protocol');
        croak 'request(): peer has not enabled Extended CONNECT'
            unless $enabled == 1;
    }

    my $stream_body = exists($option{stream_body})
        ? delete($option{stream_body})
        : 0;
    croak 'request(): stream_body must be zero or one'
        if !defined($stream_body) || ref($stream_body)
            || "$stream_body" !~ /\A[01]\z/;
    $stream_body = $stream_body ? 1 : 0;

    my %callbacks;
    for my $name (qw(
        on_response on_body on_complete on_error on_informational on_drain
    )) {
        next unless exists $option{$name};
        my $callback = delete $option{$name};
        croak "request(): $name must be a coderef"
            if defined($callback) && ref($callback) ne 'CODE';
        $callbacks{$name} = $callback if $callback;
    }

    croak 'request(): unknown options: ' . join(', ', sort keys %option)
        if %option;
    croak 'request(): on_drain requires stream_body'
        if $callbacks{on_drain} && !$stream_body;
    croak 'request(): stream_body cannot be combined with a buffered body'
        if $stream_body && $request->has_buffered_body;

    my $block = $native_message
        ? undef
        : Unblock::HTTP2::_Headers->request_headers($request);
    my $trailers = Unblock::HTTP2::_Headers->trailer_fields(
        'request()', $request,
    );

    my ($provider, $body);
    if ($stream_body || @$trailers) {
        $provider = {
            queue             => '',
            eof               => 0,
            blocked           => 0,
            stream_id         => undef,
            trailers          => undef,
            trailer_submitted => 0,
        };

        if (!$stream_body) {
            $provider->{queue} = $request->has_buffered_body
                ? $request->body
                : '';
            $provider->{eof} = 1;
            $provider->{trailers} = $trailers if @$trailers;
        }

        my $weak_self = $self;
        weaken($weak_self);

        $body = sub {
            my $self = $weak_self or return ('', 1);
            return $self->_provide_body($provider, @_);
        };
    }
    elsif ($request->has_buffered_body) {
        $body = $request->body;
    }

    my $stream_id = $native_message
        ? $self->{session}->_submit_request_uniform_xs($native_message, $body)
        : $self->{session}->_submit_request_xs($block, $body);

    my $transaction = Unblock::HTTP2::Transaction->_new(
        connection => $self,
        stream_id  => $stream_id,
        request    => $request,
        callbacks  => \%callbacks,
    );

    $self->_register_transaction($transaction);
    $self->{receive}{$stream_id} = {
        response      => undef,
        response_done => 0,
    };

    if ($provider) {
        $provider->{stream_id} = $stream_id;
        $self->{providers}{$stream_id} = $provider;
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
sub _on_begin_headers {
    return 0;
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

sub _on_frame_recv {
    my ($self, $frame) = @_;

    return 0 if $self->_handle_settings_frame($frame);
    return 0 if $self->_handle_ping_frame($frame);

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
    my $transaction = $self->transaction_for_stream_id($stream_id) or return 0;

    if (($frame->{type} // -1) == H2_HEADERS) {
        if (defined $frame->{header_error}) {
            $self->_stream_failure(
                $stream_id,
                "$frame->{header_error}",
                $frame->{header_error_code},
            );
            return 0;
        }

        if (!$state->{response}) {
            my $response = $frame->{uniform_message};
            if (!$response) {
                $self->_stream_failure(
                    $stream_id,
                    'HTTP/2 response header block did not produce a Uniform response',
                );
                return 0;
            }

            my $status = $response->status;
            if ($status >= 100 && $status < 200) {
                my $result = $transaction->_invoke(
                    'on_informational', $response,
                );
                $self->_stream_failure($stream_id, "$result")
                    unless $result eq '1';
                return 0;
            }

            $state->{response} = $response;
            $transaction->_set_response($response);

            my $result = $transaction->_invoke('on_response', $response);
            if ($result ne '1') {
                $self->_stream_failure($stream_id, "$result");
                return 0;
            }

            if (($frame->{flags} || 0) & H2_END_STREAM) {
                $self->_finish_response($stream_id);
            }

            return 0;
        }

        if ($frame->{uniform_message}) {
            $self->_stream_failure(
                $stream_id,
                'HTTP/2 trailing HEADERS must not contain :status',
                H2_PROTOCOL_ERROR,
            );
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
                $state->{response},
                $frame->{native_headers} || [],
            );
            1;
        };
        if (!$ok) {
            $self->_stream_failure($stream_id, "$@");
            return 0;
        }

        $self->_finish_response($stream_id);
        return 0;
    }

    if (($frame->{type} // -1) == H2_DATA
        && (($frame->{flags} || 0) & H2_END_STREAM)) {
        $self->_finish_response($stream_id);
    }

    return 0;
}

sub _on_data_chunk_recv {
    my ($self, $stream_id, $data, $flags) = @_;
    my $state = $self->{receive}{$stream_id} or return 0;
    my $transaction = $self->transaction_for_stream_id($stream_id) or return 0;
    my $response = $state->{response};

    if (!$response) {
        $self->_stream_failure(
            $stream_id,
            'HTTP/2 DATA arrived before final Response headers',
        );
        return 0;
    }

    $transaction->_receive_body_bytes(length $data);

    my $result = $transaction->_invoke('on_body', $response, $data);
    if ($result ne '1') {
        $self->_stream_failure($stream_id, "$result");
        return 0;
    }

    $transaction->_auto_consume_body;
    return 0;
}

sub _finish_response {
    my ($self, $stream_id) = @_;
    my $state = $self->{receive}{$stream_id} or return;
    return if $state->{response_done}++;

    my $transaction = $self->transaction_for_stream_id($stream_id) or return;
    my $response = $state->{response};

    if (!$response) {
        $self->_stream_failure(
            $stream_id,
            'HTTP/2 stream ended before final Response headers',
        );
        return;
    }

    $response->mark_complete->freeze;

    my $result = $transaction->_invoke('on_complete');
    $self->_invoke_stream_error($transaction, "$result")
        unless $result eq '1';
    return;
}
sub _on_stream_close {
    my ($self, $stream_id, $error_code) = @_;
    my $state = delete $self->{receive}{$stream_id};
    delete $self->{providers}{$stream_id};

    my $transaction = $self->_remove_transaction($stream_id) or return 0;
    return 0 if $transaction->is_terminal;

    if ($error_code) {
        my $error = "HTTP/2 stream closed with error $error_code";
        $transaction->_fail($error, $error_code, 1);
        $self->_invoke_stream_error($transaction, $error, $error_code);
    }
    elsif ($state && $state->{response}) {
        $state->{response}->mark_complete->freeze;
        if (!$state->{response_done}) {
            my $result = $transaction->_invoke('on_complete');
            $self->_invoke_stream_error($transaction, "$result")
                unless $result eq '1';
        }
        $transaction->_mark_complete;
    }
    else {
        my $error = 'HTTP/2 stream closed before final Response';
        $transaction->_fail($error);
        $self->_invoke_stream_error($transaction, $error);
    }

    return 0;
}
sub _stream_failure {
    my ($self, $stream_id, $error, $code) = @_;
    $code = H2_INTERNAL_ERROR unless defined $code;
    $error = 'HTTP/2 stream failure'
        unless defined($error) && length($error);

    my $transaction = $self->transaction_for_stream_id($stream_id) or return;
    return if $transaction->is_terminal;

    $transaction->_fail($error, $code, 0);
    eval { $self->{session}->submit_rst_stream($stream_id, $code) };
    $self->_invoke_stream_error($transaction, $error, $code);
    return;
}

sub _write_stream_body {
    my ($self, $transaction, $bytes, $final, $operation) = @_;

    my $provider = $self->{providers}{ $transaction->stream_id }
        or croak "$operation(): Transaction has no streaming Request body";

    $bytes = $self->_body_bytes("$operation()", $bytes);
    croak "$operation(): streaming Request body is already complete"
        if $provider->{eof};

    $provider->{queue} .= $bytes;

    if ($final) {
        my $trailers = Unblock::HTTP2::_Headers->trailer_fields(
            "$operation()", $transaction->request,
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
sub _send_informational_stream {
    croak 'send_informational(): client-side streams cannot send Responses';
}

sub _respond_stream {
    croak 'respond(): client-side streams cannot send Responses';
}

sub _cancel_stream {
    my ($self, $transaction) = @_;
    return if $transaction->is_terminal;
    $self->_reset_stream($transaction, H2_CANCEL);
    return;
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

Unblock::HTTP2::Client - one HTTP/2 client connection

=head1 SYNOPSIS

    use Unblock::HTTP2::Client;

    # $stream is a connected socket or TLS stream owned by your framework.
    my $client = Unblock::HTTP2::Client->new(
        transport => $stream,
    );

    my $transaction = $client->request(
        method    => 'GET',
        target    => '/',
        scheme    => 'https',
        authority => 'example.com',

        on_response => sub {
            my ($tx, $response) = @_;
            print "Status: ", $response->status, "\n";
        },
        on_body => sub {
            my ($tx, $response, $bytes) = @_;
            print $bytes;
        },
        on_complete => sub {
            my ($tx) = @_;
            print "Response complete\n";
        },
    );

    # In the framework's read callback:
    $client->input($received_http2_bytes);

The framework stream implements C<unblock_send()>, C<unblock_finish()>,
and C<unblock_abort()>. The Client automatically sends its connection
preface, SETTINGS, requests, and other outgoing frames through the host.
The framework retains ownership of sockets, TLS, and its write queue.

See L<Unblock::HTTP2::Integration> and F<examples/io-async-client.pl>
for a complete connection example.

=head1 DESCRIPTION

A Client owns one HTTP/2 client session.

It does not create a socket, perform TLS, run an event loop, or own a transport
write queue.

With C<transport =E<gt> $host>, feed network bytes using C<input()>.
Generated output is automatically delivered to the host's
C<unblock_send()> method. Without an attached host, manually drain
C<output()> while C<want_write()> is true.

Many request transactions can be active at once.

=head1 CONSTRUCTOR

C<new()> accepts an initial C<settings> hash, C<max_active_transactions>,
C<max_header_list_size>, and an optional C<transport> object.

The attached transport implements C<unblock_send()>, C<unblock_finish()>,
and C<unblock_abort()>. See L<Unblock::HTTP2::Integration>.

Connection callbacks are:

    on_settings($client, $peer_settings, $changed_settings)
    on_settings_ack($client, $acked_settings)
    on_ping($client, $opaque)
    on_ping_ack($client, $opaque)
    on_invalid_frame($client, $frame, $lib_error_code)

=head1 REQUESTS

C<request($request, %options)> sends a L<Uniform::HTTP::Request> and returns a
L<Unblock::HTTP2::Transaction>. The simpler named-field form also works:

    $client->request(
        method => 'GET', target => '/',
        scheme => 'https', authority => 'example.test',
        on_response => sub { my ($tx, $response) = @_; },
    );

Callbacks and C<stream_body> are options, not Uniform message fields.

Useful callbacks are:

=over 4

=item C<on_response($transaction, $response)>

Final response headers arrived.

=item C<on_informational($transaction, $response)>

An informational response arrived.

=item C<on_body($transaction, $response, $bytes)>

A response body chunk arrived.

=item C<on_complete($transaction)>

The response completed.

=item C<on_error($transaction, $error, $error_code)>

The transaction failed or its HTTP/2 stream was reset. C<$error_code> can be
undefined when there is no HTTP/2 reset code.

=item C<on_drain($transaction)>

A streaming request body can produce more data.

=back

Set C<stream_body =E<gt> 1> to produce the request body with the Transaction
C<write()> and C<end()> methods.

=head1 CONNECTION CONTROL

The Client also exposes the common connection methods:

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

C<can_open_transaction()> reports whether another local request transaction can be
opened.

=head1 SEE ALSO

L<Unblock::HTTP2>, L<Unblock::HTTP2::Integration>,
L<Unblock::HTTP2::Transaction>, L<Uniform::HTTP::Request>

=head1 LICENSE

MIT License.

=cut
