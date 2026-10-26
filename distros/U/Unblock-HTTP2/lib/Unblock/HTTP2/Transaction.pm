package Unblock::HTTP2::Transaction;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed weaken);
use Uniform::HTTP::Response;

our $VERSION = '0.13';

my %TERMINAL = map { $_ => 1 } qw(complete cancelled error);

sub _new {
    my ($class, %args) = @_;

    my $connection = delete $args{connection};
    my $stream_id  = delete $args{stream_id};
    my $request    = delete $args{request};
    my $callbacks  = delete($args{callbacks}) || {};

    croak 'Transaction requires a connection object'
        unless blessed($connection);
    croak 'Transaction stream id must be a positive integer'
        unless defined($stream_id) && !ref($stream_id)
            && $stream_id =~ /\A[0-9]+\z/ && $stream_id > 0;
    croak 'Transaction callbacks must be a hash reference'
        unless ref($callbacks) eq 'HASH';
    croak 'unknown Transaction option: ' . join(', ', sort keys %args)
        if %args;

    my $self = bless {
        connection => $connection,
        stream_id  => 0 + $stream_id,
        request    => $request,
        response   => undef,
        callbacks        => { %$callbacks },
        state            => 'active',
        error            => undef,
        error_code       => undef,
        reset_by_peer    => undef,
        auto_consume     => 1,
        unconsumed_bytes => 0,
    }, $class;

    $self->{receive_body} = $connection->{receive_body};
    $self->{max_buffered_body_bytes} = $connection->{max_buffered_body_bytes};
    my $on_data = delete $self->{callbacks}{on_data};
    $self->on_data($on_data) if $on_data;
    croak 'buffered reception cannot be combined with on_body'
        if $self->{receive_body} eq 'buffered' && $self->{callbacks}{on_body};
    weaken($self->{connection});
    return $self;
}

sub stream_id    { return $_[0]{stream_id} }
sub request      { return $_[0]{request} }
sub response     { return $_[0]{response} }
sub state        { return $_[0]{state} }
sub error        { return $_[0]{error} }
sub error_code   { return $_[0]{error_code} }
sub reset_by_peer { return $_[0]{reset_by_peer} }
sub error_name {
    my ($self) = @_;
    return unless defined $self->{error_code};
    require Unblock::HTTP2;
    return Unblock::HTTP2->error_name($self->{error_code});
}
sub unconsumed_bytes { return $_[0]{unconsumed_bytes} }
sub is_complete  { return $_[0]{state} eq 'complete' ? 1 : 0 }
sub is_cancelled { return $_[0]{state} eq 'cancelled' ? 1 : 0 }
sub is_error     { return $_[0]{state} eq 'error' ? 1 : 0 }
sub is_terminal  { return $TERMINAL{$_[0]{state}} ? 1 : 0 }

sub on_data {
    my ($self, $cb) = @_;
    croak 'on_data(): callback must be a coderef' unless ref($cb) eq 'CODE';
    croak 'on_data(): receive body has already started or finished'
        if $self->{receive_started} || $self->{receive_done} || $self->is_terminal;
    my $owner = $self->{connection};
    croak 'on_data(): cannot be combined with on_body'
        if $self->{callbacks}{on_body} || ($owner && $owner->{callbacks}{on_body});
    croak 'on_data(): callback is already registered' if $self->{callbacks}{on_data};
    $self->{callbacks}{on_data} = $cb;
    $self->{receive_body} = 'stream';
    return $self;
}

sub on_finish {
    my ($self, $cb) = @_;
    croak 'on_finish(): callback must be a coderef' unless ref($cb) eq 'CODE';
    croak 'on_finish(): Transaction is terminal' if $self->is_terminal;
    croak 'on_finish(): callback is already registered' if $self->{callbacks}{on_finish};
    $self->{callbacks}{on_finish} = $cb;
    return $self;
}

sub _receive_data {
    my ($self, $message, $bytes) = @_;
    return 1 if $self->is_terminal;
    $self->{receive_started} = 1;
    if ($self->{receive_body} eq 'buffered') {
        my $size = ($self->{received_bytes} || 0) + length($bytes);
        if ($size > $self->{max_buffered_body_bytes}) {
            delete $self->{receive_chunks};
            delete $self->{received_bytes};
            return 'received body exceeds max_buffered_body_bytes';
        }
        push @{ $self->{receive_chunks} }, $bytes;
        $self->{received_bytes} = $size;
        return 1;
    }
    return $self->_invoke('on_data', $bytes) if $self->{callbacks}{on_data};
    my $owner = $self->{connection};
    return $owner->_invoke_callback('on_body', $self, $message, $bytes)
        if $owner && $owner->can('_invoke_callback');
    return $self->_invoke('on_body', $message, $bytes);
}

sub _finish_receive {
    my ($self, $message) = @_;
    $self->{receive_done} = 1;
    if ($self->{receive_body} eq 'buffered' && $message->body_is_mutable) {
        $message->body(join '', @{ delete($self->{receive_chunks}) || [] });
    }
    delete $self->{receive_chunks};
    delete $self->{received_bytes};
    return;
}

sub _notify_finish {
    my ($self) = @_;
    return unless $self->is_terminal && !$self->{finish_called};
    $self->{finish_pending} = 1;
    return if $self->{callback_depth};
    $self->{finish_called} = 1;
    delete $self->{finish_pending};
    # Terminal observers cannot undo cleanup or recursively report an error.
    $self->_invoke('on_finish');
    return;
}

sub write {
    my ($self, $bytes) = @_;
    croak 'write(): Transaction is already terminal' if $self->is_terminal;

    my $connection = $self->{connection}
        or croak 'write(): HTTP/2 connection is no longer available';

    return $connection->_write_stream_body($self, $bytes, 0, 'write');
}

sub end {
    my ($self, @args) = @_;
    croak 'end(): accepts at most one final byte string' if @args > 1;
    croak 'end(): Transaction is already terminal' if $self->is_terminal;

    my $connection = $self->{connection}
        or croak 'end(): HTTP/2 connection is no longer available';

    my $bytes = @args ? $args[0] : '';
    $connection->_write_stream_body($self, $bytes, 1, 'end');
    return $self;
}

sub send_informational {
    my ($self, @arg) = @_;
    my $response;
    if (@arg == 1 && ref($arg[0])) {
        $response = $arg[0];
    }
    else {
        croak 'send_informational(): fields must be key/value pairs' if @arg % 2;
        $response = Uniform::HTTP::Response->new(@arg);
    }
    croak 'send_informational(): Transaction is already terminal' if $self->is_terminal;

    my $connection = $self->{connection}
        or croak 'send_informational(): HTTP/2 connection is no longer available';

    $connection->_send_informational_stream($self, $response);
    return $self;
}

sub respond {
    my ($self, @arg) = @_;
    my ($response, %option);
    if (@arg && ref($arg[0])) {
        $response = shift @arg;
        croak 'respond(): options must be key/value pairs' if @arg % 2;
        %option = @arg;
    }
    else {
        croak 'respond(): fields must be key/value pairs' if @arg % 2;
        my %field = @arg;
        for my $name (qw(stream_body on_drain on_error)) {
            $option{$name} = delete $field{$name} if exists $field{$name};
        }
        $response = Uniform::HTTP::Response->new(%field);
    }
    croak 'respond(): Transaction is already terminal' if $self->is_terminal;

    my $connection = $self->{connection}
        or croak 'respond(): HTTP/2 connection is no longer available';

    $connection->_respond_stream($self, $response, %option);
    return $self;
}

sub update_priority {
    my ($self, $field_value) = @_;
    croak 'update_priority(): Transaction is already terminal' if $self->is_terminal;

    my $connection = $self->{connection}
        or croak 'update_priority(): HTTP/2 connection is no longer available';

    $connection->_update_stream_priority($self, $field_value);
    return $self;
}

sub reset {
    my ($self, $error_code) = @_;
    croak 'reset(): Transaction is already terminal' if $self->is_terminal;
    croak 'reset(): error code must be an unsigned 32-bit integer'
        unless defined($error_code) && !ref($error_code)
            && "$error_code" =~ /\A[0-9]+\z/
            && $error_code <= 4_294_967_295;

    my $connection = $self->{connection}
        or croak 'reset(): HTTP/2 connection is no longer available';

    $connection->_reset_stream($self, 0 + $error_code);
    return $self;
}

sub cancel {
    my ($self) = @_;
    return $self if $self->is_terminal;
    if (!$self->{connection}) {
        $self->_mark_cancelled(8, 0);
        $self->_notify_finish;
        return $self;
    }
    return $self->reset(8);
}

sub auto_consume {
    my ($self, @args) = @_;

    return $self->{auto_consume} ? 1 : 0 unless @args;

    croak 'auto_consume(): accepts exactly one zero-or-one value'
        unless @args == 1;
    croak 'auto_consume(): Transaction is already terminal'
        if $self->is_terminal;

    my $value = $args[0];
    croak 'auto_consume(): value must be zero or one'
        if !defined($value) || ref($value) || "$value" !~ /\A[01]\z/;
    $value = $value ? 1 : 0;

    if ($value && !$self->{auto_consume} && $self->{unconsumed_bytes}) {
        my $connection = $self->{connection}
            or croak 'auto_consume(): HTTP/2 connection is no longer available';

        my $bytes = $self->{unconsumed_bytes};
        $connection->_consume_stream_body($self, $bytes);
        $self->{unconsumed_bytes} -= $bytes;
    }

    $self->{auto_consume} = $value;
    return $self;
}

sub consume {
    my ($self, $bytes) = @_;

    croak 'consume(): Transaction is already terminal' if $self->is_terminal;
    croak 'consume(): bytes must be a non-negative integer'
        unless defined($bytes) && !ref($bytes) && "$bytes" =~ /\A[0-9]+\z/;

    $bytes = 0 + $bytes;
    croak 'consume(): cannot consume more bytes than have been delivered'
        if $bytes > $self->{unconsumed_bytes};
    return $self unless $bytes;

    my $connection = $self->{connection}
        or croak 'consume(): HTTP/2 connection is no longer available';

    $connection->_consume_stream_body($self, $bytes);
    $self->{unconsumed_bytes} -= $bytes;
    return $self;
}

sub _receive_body_bytes {
    my ($self, $bytes) = @_;
    $self->{unconsumed_bytes} += $bytes if $bytes;
    return $self;
}

sub _auto_consume_body {
    my ($self) = @_;
    return $self unless $self->{auto_consume};
    return $self unless $self->{unconsumed_bytes};
    return $self if $self->is_terminal;

    my $connection = $self->{connection} or return $self;
    my $bytes = $self->{unconsumed_bytes};
    $connection->_consume_stream_body($self, $bytes);
    $self->{unconsumed_bytes} -= $bytes;
    return $self;
}

sub _set_callback {
    my ($self, $name, $callback) = @_;
    croak "_set_callback(): callback must be a coderef"
        if defined($callback) && ref($callback) ne 'CODE';

    if ($callback) {
        $self->{callbacks}{$name} = $callback;
    }
    else {
        delete $self->{callbacks}{$name};
    }

    return $self;
}

sub _set_response {
    my ($self, $response) = @_;
    croak 'Transaction already has a Response' if $self->{response};
    $self->{response} = $response;
    return $response;
}

sub _mark_complete {
    my ($self) = @_;
    return $self if $self->is_terminal;
    $self->{state} = 'complete';
    return $self;
}

sub _mark_cancelled {
    my ($self, $error_code, $by_peer) = @_;
    return $self if $self->is_terminal;
    delete $self->{receive_chunks};
    delete $self->{received_bytes};
    $self->{state} = 'cancelled';
    if (defined $error_code) {
        $self->{error_code} = 0 + $error_code;
        $self->{reset_by_peer} = $by_peer ? 1 : 0;
    }
    return $self;
}

sub _fail {
    my ($self, $error, $error_code, $by_peer) = @_;
    return $self if $self->is_terminal;

    $error = 'HTTP/2 stream failed'
        unless defined($error) && length($error);

    delete $self->{receive_chunks};
    delete $self->{received_bytes};
    $self->{state} = 'error';
    $self->{error} = "$error";
    if (defined $error_code) {
        $self->{error_code} = 0 + $error_code;
        $self->{reset_by_peer} = $by_peer ? 1 : 0;
    }
    return $self;
}

sub _invoke {
    my ($self, $name, @args) = @_;
    my $callback = $self->{callbacks}{$name} or return 1;

    $self->{callback_depth}++;
    my $ok = eval {
        $callback->($self, @args);
        1;
    };

    my $error = "$@";
    $self->{callback_depth}--;
    $self->_notify_finish if $self->{finish_pending};
    return $ok ? 1 : $error;
}

sub _drain {
    my ($self) = @_;
    my $result = $self->_invoke('on_drain');
    return $result;
}

1;

__END__

=head1 NAME

Unblock::HTTP2::Transaction - one HTTP/2 request/response transaction

=head1 SYNOPSIS

    # Inside a Server on_request callback:
    my ($tx, $request) = @_;
    $tx->send_informational(status => 103);
    $tx->respond(status => 200, body => "hello\n");

    # Alternatively, to stream a different response:
    $tx->respond(status => 200, stream_body => 1);
    $tx->write($chunk);
    $tx->end($final_chunk);

The second example is an alternative to the first, not a second response
on the same Transaction. C<respond()>, C<send_informational()>, and
Client C<request()> accept named HTTP fields directly; creating a Uniform
message by hand is optional.

=head1 RECEIVE AND FINISH CALLBACKS

    $tx->on_data(sub {
        my ($tx, $bytes) = @_;
        consume_chunk($bytes);
    });

Register during the incoming-header callback (server C<on_request> or client
C<on_response>). This selects streaming for this transaction. Only decoded
HTTP body bytes are passed; content encodings such as gzip are not decoded.
No full body is accumulated. Registering after body delivery starts or ends,
registering twice, or combining this callback with C<on_body> is an error.
Client C<request()> also accepts C<on_data> before the request is dispatched.

    $tx->on_finish(sub {
        my ($tx) = @_;
        record_outcome($tx->state, $tx->error);
    });

Runs once after the applicable completion or error callbacks for a terminal
C<complete>, C<cancelled>, or C<error> transaction. The state is committed
before the callback. Cancellation alone does not call C<on_error>.
A completed incoming request can still have an unfinished response; it is
not terminal until both sides required by the engine have finished.

Client C<request()> also accepts C<on_finish>. Register it before the
transaction becomes terminal. Duplicate and late registration are errors.
An exception from this terminal observer is ignored so cleanup and other
transactions can continue. Earlier callbacks keep the engine's exception
policy, but cannot suppress this notification.

=head1 DESCRIPTION

A Transaction represents one HTTP request/response exchange carried by one
multiplexed HTTP/2 stream.

C<request()> returns the Uniform request. C<response()> returns the Uniform
response once one is available.

=head1 STREAMING BODIES

For a streaming local body:

    $transaction->write($chunk);
    $transaction->end($last_chunk);

C<write()> always accepts the bytes. A false return means the cooperative
high-water mark was reached, or an attached host has become congested.
Wait for C<on_drain> before producing more.

Incoming body bytes are consumed automatically after the body callback returns.

For manual receive flow control:

    $transaction->auto_consume(0);
    $transaction->consume($bytes_processed);

C<unconsumed_bytes()> reports body bytes still waiting for stream-level credit.

=head1 SERVER RESPONSES

A server Transaction can send an informational response with:

    $transaction->send_informational(status => 103);

The final response uses:

    $transaction->respond(status => 200, body => "hello\n");

Both calls accept a canonical Uniform::HTTP::Response object too.

Pass C<stream_body =E<gt> 1> to C<respond()> to produce the response body with
C<write()> and C<end()>. C<on_drain> and C<on_error> are response options,
not HTTP fields.

=head1 RESETS

C<cancel()> sends the standard HTTP/2 CANCEL reset.

C<reset($error_code)> sends an explicit RST_STREAM reason.

The Transaction preserves:

    error
    error_code
    error_name
    reset_by_peer

These facts are exposed for higher-level retry and policy decisions.

=head1 PRIORITY

Client Transactions can use C<update_priority($field_value)> to send an RFC 9218
PRIORITY_UPDATE after the peer has enabled modern priorities.

=head1 STATE

Useful state accessors include:

    stream_id
    state
    is_complete
    is_cancelled
    is_error
    is_terminal

HTTP/2 half-close is preserved. One direction may finish before the full
Transaction becomes terminal.

=head1 SEE ALSO

L<Unblock::HTTP2>, L<Unblock::HTTP2::Client>,
L<Unblock::HTTP2::Server>, L<Unblock::HTTP2::Integration>

=head1 LICENSE

MIT License.

=cut
