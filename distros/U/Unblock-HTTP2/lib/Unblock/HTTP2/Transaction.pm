package Unblock::HTTP2::Transaction;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed weaken);

our $VERSION = '0.10';

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
    my ($self, $response) = @_;
    croak 'send_informational(): Transaction is already terminal' if $self->is_terminal;

    my $connection = $self->{connection}
        or croak 'send_informational(): HTTP/2 connection is no longer available';

    $connection->_send_informational_stream($self, $response);
    return $self;
}

sub respond {
    my ($self, $response, %option) = @_;
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

    my $ok = eval {
        $callback->($self, @args);
        1;
    };

    return $ok ? 1 : $@;
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
high-water mark was reached. Wait for C<on_drain> before producing more.

Incoming body bytes are consumed automatically after the body callback returns.

For manual receive flow control:

    $transaction->auto_consume(0);
    $transaction->consume($bytes_processed);

C<unconsumed_bytes()> reports body bytes still waiting for stream-level credit.

=head1 SERVER RESPONSES

A server Transaction can send an informational response with:

    $transaction->send_informational($response);

The final response uses:

    $transaction->respond($response);

Pass C<stream_body =E<gt> 1> to C<respond()> to produce the response body with
C<write()> and C<end()>.

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

L<Unblock::HTTP2>, L<Unblock::HTTP2::Client>, L<Unblock::HTTP2::Server>

=head1 LICENSE

MIT License.

=cut
