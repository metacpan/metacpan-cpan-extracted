package Unblock::HTTP3::Extension::Stream;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed weaken);

use Unblock::HTTP3 ();
use Unblock::HTTP3::_Bytes ();

our $VERSION = '0.01';

sub _new {
    my ($class, %args) = @_;

    my $connection = delete $args{connection};
    my $stream = delete $args{stream};
    my $type = delete $args{type};
    my $header_length = delete $args{header_length};
    my $incoming = delete $args{incoming};
    my $initial = delete $args{initial};
    my $initial_fin = delete $args{initial_fin};

    croak 'extension stream requires a Unblock::HTTP3::Connection'
        unless blessed($connection)
            && $connection->isa('Unblock::HTTP3::Connection');
    croak 'extension stream requires a Net::QUIC::Stream'
        unless blessed($stream)
            && $stream->isa('Net::QUIC::Stream');
    croak 'extension stream type is required'
        unless defined $type;
    croak 'unknown extension stream option: ' . join(', ', sort keys %args)
        if %args;

    $header_length = 0 unless defined $header_length;
    $initial = '' unless defined $initial;
    $initial_fin = $initial_fin ? 1 : 0;

    my $self = bless {
        connection    => $connection,
        stream        => $stream,
        type          => "$type",
        header_length => 0 + $header_length,
        incoming      => $incoming ? 1 : 0,
        initial       => length($initial) || $initial_fin
            ? [ $initial, $initial_fin ]
            : undef,
        on_data       => undef,
        on_end        => undef,
        on_reset      => undef,
        on_stop       => undef,
        on_drain      => undef,
        ended         => 0,
        reset_code    => undef,
        stop_code     => undef,
        flow_blocked  => 0,
    }, $class;

    weaken($self->{connection});

    return $self;
}

sub type {
    my ($self, @args) = @_;
    croak 'type() does not accept arguments' if @args;
    return $self->{type};
}

sub id {
    my ($self, @args) = @_;
    croak 'id() does not accept arguments' if @args;
    return $self->{stream}->id;
}

sub incoming {
    my ($self, @args) = @_;
    croak 'incoming() does not accept arguments' if @args;
    return $self->{incoming} ? 1 : 0;
}

sub can_send {
    my ($self, @args) = @_;
    croak 'can_send() does not accept arguments' if @args;
    return $self->{stream}->can_send ? 1 : 0;
}

sub can_receive {
    my ($self, @args) = @_;
    croak 'can_receive() does not accept arguments' if @args;
    return $self->{stream}->can_receive ? 1 : 0;
}

sub configure {
    my ($self, %option) = @_;

    for my $name (qw(on_data on_end on_reset on_stop on_drain)) {
        next unless exists $option{$name};

        my $callback = delete $option{$name};

        croak "configure(): $name must be a code reference"
            if defined($callback) && ref($callback) ne 'CODE';
        croak "configure(): $name is already configured"
            if defined($self->{$name});

        if ($name eq 'on_drain') {
            croak 'configure(): on_drain requires an outgoing stream'
                unless $self->{stream}->can_send;
        } else {
            croak "configure(): $name requires an incoming stream"
                unless $self->{stream}->can_receive;
        }

        $self->{$name} = $callback;
    }

    croak 'configure(): unknown option: ' . join(', ', sort keys %option)
        if %option;

    if (defined($self->{reset_code}) && defined($self->{on_reset})) {
        $self->{on_reset}->($self, $self->{reset_code});
    } elsif (defined($self->{stop_code}) && defined($self->{on_stop})) {
        $self->{on_stop}->($self, $self->{stop_code});
    } elsif ($self->{ended} && defined($self->{on_end})) {
        $self->{on_end}->($self);
    } elsif (defined $self->{on_data}) {
        $self->_drain_receive;
    }

    return $self;
}

sub next_chunk {
    my ($self, @args) = @_;

    croak 'next_chunk() does not accept arguments' if @args;
    croak 'next_chunk() cannot be used with on_data'
        if defined $self->{on_data};
    croak 'cannot receive on this extension stream'
        unless $self->{stream}->can_receive;
    return if defined $self->{reset_code};

    my ($bytes, $fin);

    if (defined $self->{initial}) {
        ($bytes, $fin) = @{ delete $self->{initial} };
    } else {
        my $chunk = $self->{stream}->next_data_chunk;
        return unless defined $chunk;
        ($bytes, $fin) = @$chunk;
    }

    $self->{stream}->consume(length($bytes))
        if length($bytes);

    $self->_mark_end if $fin;

    return $bytes;
}

sub send {
    my ($self, $bytes) = @_;

    croak 'cannot send on this extension stream'
        unless $self->{stream}->can_send;
    croak 'extension stream send side is already finished'
        if $self->{ended};
    croak 'peer stopped the extension stream send side'
        if defined $self->{stop_code};

    $bytes = Unblock::HTTP3::_Bytes::byte_string(
        'extension stream data',
        $bytes,
    );

    $self->{stream}->send($bytes);
    return $self;
}

sub send_some {
    my ($self, $bytes) = @_;

    croak 'cannot send on this extension stream'
        unless $self->{stream}->can_send;
    croak 'extension stream send side is already finished'
        if $self->{ended};
    croak 'peer stopped the extension stream send side'
        if defined $self->{stop_code};

    $bytes = Unblock::HTTP3::_Bytes::byte_string(
        'extension stream data',
        $bytes,
    );

    my $accepted = $self->{stream}->send_some($bytes);
    $self->{flow_blocked} = $accepted < length($bytes) ? 1 : 0;

    return $accepted;
}

sub finish {
    my ($self, @args) = @_;

    croak 'finish() does not accept arguments' if @args;
    croak 'cannot finish this incoming extension stream'
        unless $self->{stream}->can_send;
    croak 'extension stream send side is already finished'
        if $self->{ended};

    $self->{stream}->finish;
    $self->{ended} = 1;
    $self->{flow_blocked} = 0;

    return $self;
}

sub stop_sending {
    my ($self, $code) = @_;
    $code = 0 unless defined $code;

    croak 'cannot stop this outgoing extension stream'
        unless $self->{stream}->can_receive;

    $self->{stream}->stop_sending($code);
    return $self;
}

sub reset {
    my ($self, $code) = @_;
    $code = 0 unless defined $code;

    croak 'cannot reset this incoming extension stream'
        unless $self->{stream}->can_send;

    $self->{stream}->reset($code);
    $self->{ended} = 1;
    $self->{flow_blocked} = 0;

    return $self;
}

sub acked_offset {
    my ($self, @args) = @_;

    croak 'acked_offset() does not accept arguments' if @args;
    croak 'acked_offset() is only available for outgoing extension streams'
        unless $self->{stream}->can_send;

    my $offset = $self->{stream}->acked_offset;
    my $header = $self->{header_length};

    return 0 if $offset <= $header;
    return $offset - $header;
}

sub is_complete {
    my ($self, @args) = @_;
    croak 'is_complete() does not accept arguments' if @args;
    return $self->{ended} ? 1 : 0;
}

sub is_reset {
    my ($self, @args) = @_;
    croak 'is_reset() does not accept arguments' if @args;
    return defined($self->{reset_code}) ? 1 : 0;
}

sub reset_code {
    my ($self, @args) = @_;
    croak 'reset_code() does not accept arguments' if @args;
    return $self->{reset_code};
}

sub is_stopped {
    my ($self, @args) = @_;
    croak 'is_stopped() does not accept arguments' if @args;
    return defined($self->{stop_code}) ? 1 : 0;
}

sub stop_code {
    my ($self, @args) = @_;
    croak 'stop_code() does not accept arguments' if @args;
    return $self->{stop_code};
}

sub _drain_receive {
    my ($self) = @_;

    my $callback = $self->{on_data} or return;
    return if $self->{ended} || defined($self->{reset_code});

    while (1) {
        my ($bytes, $fin);

        if (defined $self->{initial}) {
            ($bytes, $fin) = @{ delete $self->{initial} };
        } else {
            my $chunk = $self->{stream}->next_data_chunk;
            last unless defined $chunk;
            ($bytes, $fin) = @$chunk;
        }

        if (length $bytes) {
            $callback->($self, $bytes);
            $self->{stream}->consume(length($bytes));
        }

        if ($fin) {
            $self->_mark_end;
            last;
        }
    }

    return;
}

sub _drain_send {
    my ($self) = @_;

    return unless $self->{flow_blocked};
    return if $self->{ended};

    $self->{flow_blocked} = 0;

    my $callback = $self->{on_drain};
    $callback->($self) if defined $callback;

    return;
}

sub _mark_end {
    my ($self) = @_;

    return if $self->{ended};

    $self->{ended} = 1;

    my $callback = $self->{on_end};
    $callback->($self) if defined $callback;

    return;
}

sub _mark_reset {
    my ($self, $code) = @_;

    return if defined $self->{reset_code};

    $self->{reset_code} = 0 + $code;
    $self->{initial} = undef;
    $self->{flow_blocked} = 0;

    my $callback = $self->{on_reset};
    $callback->($self, $self->{reset_code})
        if defined $callback;

    return;
}

sub _mark_stop {
    my ($self, $code) = @_;

    return if defined $self->{stop_code};

    $self->{stop_code} = 0 + $code;
    $self->{flow_blocked} = 0;

    my $callback = $self->{on_stop};
    $callback->($self, $self->{stop_code})
        if defined $callback;

    return;
}

1;

__END__

=head1 NAME

Unblock::HTTP3::Extension::Stream - HTTP/3 extension unidirectional stream

=head1 SYNOPSIS

    $h3->extension_stream_handler(
        $type,
        sub {
            my ($h3, $stream) = @_;

            while (defined(my $chunk = $stream->next_chunk)) {
                ...
            }
        },
    );

    my $stream = $h3->open_extension_stream($type);
    $stream->send($bytes);
    $stream->finish;

=head1 DESCRIPTION

This object represents one generic HTTP/3 extension unidirectional stream.

Unblock::HTTP3 owns the stream-type prefix. The extension owns the bytes after
that prefix.

Incoming streams can be polled with C<next_chunk> or configured with callbacks.
Outgoing streams use C<send>, C<send_some>, and C<finish>.

=head1 METHODS

=head2 type

Returns the HTTP/3 extension stream type.

=head2 id

Returns the underlying QUIC stream ID.

=head2 incoming

True when the stream was opened by the peer.

=head2 can_send

True when this endpoint can send on the stream.

=head2 can_receive

True when this endpoint can receive on the stream.

=head2 configure

    $stream->configure(
        on_data  => sub { ... },
        on_end   => sub { ... },
        on_reset => sub { ... },
        on_stop  => sub { ... },
        on_drain => sub { ... },
    );

Configures optional callbacks and returns the Stream.

=head2 next_chunk

Returns the next received payload chunk, or undef.

Consuming a chunk returns its QUIC receive credit.

=head2 send

Queues payload bytes for reliable delivery.

=head2 send_some

Uses the bounded Net::QUIC transmit path and returns the number of payload bytes
accepted.

If fewer bytes are accepted, C<on_drain> runs when the producer can try again.

=head2 finish

Cleanly closes the outgoing stream.

=head2 stop_sending

Stops an incoming stream with an optional application error code.

=head2 reset

Resets an outgoing stream with an optional application error code.

=head2 acked_offset

Returns the acknowledged payload offset.

The HTTP/3 stream-type prefix is not included.

=head2 is_complete

True after a clean end in the available stream direction.

=head2 is_reset

True after the peer resets an incoming extension stream.

=head2 reset_code

Returns the peer reset code, or undef.

=head2 is_stopped

True after the peer sends STOP_SENDING for an outgoing extension stream.

=head2 stop_code

Returns the peer STOP_SENDING code, or undef.

=head1 SEE ALSO

L<Unblock::HTTP3::Connection>, L<Net::QUIC::Stream>

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

This software is available under the MIT License.

=cut
