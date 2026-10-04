package Unblock::HTTP3::Capsule::Stream;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed weaken);

use Unblock::HTTP3 ();
use Unblock::HTTP3::Capsule ();
use Unblock::HTTP3::Capsule::Parser ();

our $VERSION = '0.01';

sub _new {
    my ($class, $transaction, %option) = @_;

    croak 'Capsule stream requires a Unblock::HTTP3::Transaction'
        unless blessed($transaction)
            && $transaction->isa('Unblock::HTTP3::Transaction');
    croak 'Capsule Protocol requires Extended CONNECT'
        unless $transaction->is_extended_connect;

    my $on_capsule = delete $option{on_capsule};
    my $handlers_supplied = exists $option{handlers};
    my $handlers = delete $option{handlers};
    my $on_end = delete $option{on_end};
    my $on_cancel = delete $option{on_cancel};
    my $max_capsule_size = exists($option{max_capsule_size})
        ? delete($option{max_capsule_size})
        : 4 * 1024 * 1024;

    croak 'on_capsule must be a code reference'
        if defined($on_capsule) && ref($on_capsule) ne 'CODE';
    croak 'handlers must be a hash reference'
        if defined($handlers) && ref($handlers) ne 'HASH';
    croak 'on_end must be a code reference'
        if defined($on_end) && ref($on_end) ne 'CODE';
    croak 'on_cancel must be a code reference'
        if defined($on_cancel) && ref($on_cancel) ne 'CODE';
    croak 'unknown Capsule stream option: ' . join(', ', sort keys %option)
        if %option;

    my $self = bless {
        transaction => $transaction,
        parser      => undef,
        writer      => undef,
        reader      => undef,
        on_end      => $on_end,
        on_cancel   => $on_cancel,
        polling        => (!$handlers_supplied && !defined($on_capsule)) ? 1 : 0,
        callback_error => undef,
        ended          => 0,
        cancelled      => 0,
    }, $class;

    weaken($self->{transaction});

    my $weak_self = $self;
    weaken($weak_self);

    my %parser_option = (
        max_capsule_size => $max_capsule_size,
    );

    if (defined $handlers) {
        my %wrapped;

        for my $type (keys %$handlers) {
            my $callback = $handlers->{$type};

            croak "Capsule handler for type $type must be a code reference"
                unless ref($callback) eq 'CODE';

            $wrapped{$type} = sub {
                my ($parser, $capsule) = @_;
                my $stream = $weak_self or return;

                my $ok = eval {
                    $callback->($stream, $capsule);
                    1;
                };

                if (!$ok) {
                    my $error = $@ || 'Capsule handler failed';
                    $stream->{callback_error} = $error;
                    die $error;
                }

                return;
            };
        }

        $parser_option{handlers} = \%wrapped;
    }

    if (defined $on_capsule) {
        $parser_option{on_capsule} = sub {
            my ($parser, $capsule) = @_;
            my $stream = $weak_self or return;

            my $ok = eval {
                $on_capsule->($stream, $capsule);
                1;
            };

            if (!$ok) {
                my $error = $@ || 'Capsule callback failed';
                $stream->{callback_error} = $error;
                die $error;
            }

            return;
        };
    }

    $self->{parser} =
        Unblock::HTTP3::Capsule::Parser->new(%parser_option);

    my $connection = $transaction->{connection}
        or croak 'Capsule stream lost its HTTP/3 connection';

    $self->_assert_protocol_ready;

    if ($connection->role eq 'client') {
        $self->{writer} = $transaction->request_body;
        $self->{reader} = $transaction->response_body;
    } else {
        $self->{writer} = $transaction->response_body;
        $self->{reader} = $transaction->request_body;
    }

    my %reader_option = (
        on_end => sub {
            my $stream = $weak_self or return;
            return if $stream->{cancelled};

            my $ok = eval {
                $stream->_assert_protocol_ready;
                $stream->{parser}->finish;
                1;
            };

            if (!$ok) {
                my $error = $@ || 'Capsule Protocol truncated stream';
                my $tx = $stream->{transaction};
                $tx->_capsule_protocol_error($error)
                    if defined $tx;
                return;
            }

            $stream->{ended} = 1;

            my $callback = $stream->{on_end};
            $callback->($stream) if defined $callback;

            return;
        },
        on_cancel => sub {
            my $stream = $weak_self or return;
            return if $stream->{cancelled};

            $stream->{cancelled} = 1;

            my $callback = $stream->{on_cancel};
            $callback->($stream) if defined $callback;

            return;
        },
    );

    if (!$self->{polling}) {
        $reader_option{on_data} = sub {
            my ($reader, $bytes) = @_;
            my $stream = $weak_self or return;

            return if $stream->{cancelled};

            my $ok = eval {
                $stream->_assert_protocol_ready;
                $stream->{parser}->feed($bytes);
                1;
            };

            if (!$ok) {
                my $error = $@ || 'Capsule Protocol parse error';

                if (defined $stream->{callback_error}) {
                    my $callback_error = delete $stream->{callback_error};
                    die $callback_error;
                }

                my $tx = $stream->{transaction};
                $tx->_capsule_protocol_error($error)
                    if defined $tx;
            }

            return;
        };
    }

    $self->{reader}->_configure(%reader_option);

    return $self;
}

sub _has_forbidden_field {
    my ($message) = @_;

    for my $name (qw(content-length content-type transfer-encoding)) {
        my $values = $message->header_values($name);
        return $name if @$values;
    }

    return;
}

sub _assert_protocol_ready {
    my ($self) = @_;

    my $transaction = $self->{transaction}
        or croak 'Capsule Protocol Transaction is no longer available';

    my $request = $transaction->request;

    croak 'Capsule Protocol requires Extended CONNECT'
        unless $transaction->is_extended_connect;

    if (my $field = _has_forbidden_field($request)) {
        croak "Capsule Protocol request must not contain $field";
    }

    my $response = $transaction->response
        or croak 'Capsule Protocol requires a final response';

    my $status = $response->status;

    croak 'Capsule Protocol requires a successful response'
        unless $status >= 200 && $status < 300;
    croak "Capsule Protocol cannot use HTTP status $status"
        if $status == 204 || $status == 205 || $status == 206;

    if (my $field = _has_forbidden_field($response)) {
        croak "Capsule Protocol response must not contain $field";
    }

    return 1;
}

sub send {
    my ($self, $type, $value) = @_;

    croak 'send() cannot be used after Capsule stream cancellation'
        if $self->{cancelled};

    $self->_assert_protocol_ready;

    my $capsule = Unblock::HTTP3::Capsule->new(
        type  => $type,
        value => defined($value) ? $value : '',
    );

    return $self->{writer}->write($capsule->encode);
}

sub next_capsule {
    my ($self, @args) = @_;

    croak 'next_capsule() does not accept arguments' if @args;
    croak 'next_capsule() is only available in polling mode'
        unless $self->{polling};
    return if $self->{cancelled};

    my $capsule = $self->{parser}->next_capsule;
    return $capsule if defined $capsule;

    while (defined(my $bytes = $self->{reader}->next_chunk)) {
        $self->{parser}->feed($bytes);

        $capsule = $self->{parser}->next_capsule;
        return $capsule if defined $capsule;

        return if $self->{cancelled};
    }

    return $self->{parser}->next_capsule;
}

sub complete {
    my ($self, @args) = @_;
    croak 'complete() does not accept arguments' if @args;
    croak 'Capsule stream was cancelled'
        if $self->{cancelled};

    $self->_assert_protocol_ready;
    $self->{writer}->complete
        unless $self->{writer}->is_complete;

    return $self;
}

sub is_receive_complete {
    my ($self, @args) = @_;
    croak 'is_receive_complete() does not accept arguments' if @args;
    return $self->{ended} ? 1 : 0;
}

sub is_cancelled {
    my ($self, @args) = @_;
    croak 'is_cancelled() does not accept arguments' if @args;
    return $self->{cancelled} ? 1 : 0;
}

1;

__END__

=head1 NAME

Unblock::HTTP3::Capsule::Stream - Capsule Protocol over Extended CONNECT

=head1 SYNOPSIS

    my $capsules = $tx->capsules;

    $capsules->send(42, $bytes);

    while (my $capsule = $capsules->next_capsule) {
        ...
    }

    $capsules->complete;

=head1 DESCRIPTION

A Capsule::Stream runs RFC 9297 Capsule framing over the streaming body
directions of one Extended CONNECT Transaction.

On a client, create it after receiving a successful final response. On a
server, configure the successful Response before creating it.

The object handles Capsule framing and parsing. It does not define the meaning
of Capsule Types.

=head1 METHODS

=head2 send

    my $can_continue = $capsules->send($type, $bytes);

Sends one Capsule.

The return value follows normal HTTP/3 body backpressure semantics. A false
return means the bytes were accepted but the producer should pause.

=head2 next_capsule

Returns the next received L<Unblock::HTTP3::Capsule>, or undef.

Polling only consumes underlying body bytes as needed, so normal receive-credit
and buffering limits remain active.

=head2 complete

Half-closes the outgoing Capsule data stream.

=head2 is_receive_complete

True after the peer cleanly ends its Capsule data stream.

=head2 is_cancelled

True if the underlying Transaction was cancelled.

=head1 NOTES

Capsule Protocol negotiation belongs to the higher-level protocol.

Unblock::HTTP3 provides the generic RFC 9297 mechanism but does not invent
protocol-specific negotiation rules.

=head1 SEE ALSO

L<Unblock::HTTP3::Transaction>, L<Unblock::HTTP3::Capsule>,
L<Unblock::HTTP3::Capsule::Parser>

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

This software is available under the MIT License.

=cut
