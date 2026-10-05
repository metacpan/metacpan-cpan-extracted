package Unblock::HTTP3::Body::Stream;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed weaken);

use Unblock::HTTP3 ();
use Unblock::HTTP3::_Bytes ();

our $VERSION = '0.03';

sub _new {
    my ($class, $transaction, $kind, %option) = @_;

    croak 'body stream kind must be request or response'
        if $kind ne 'request' && $kind ne 'response';
    croak 'body stream requires a Unblock::HTTP3::Transaction'
        unless blessed($transaction)
            && $transaction->isa('Unblock::HTTP3::Transaction');

    my $on_drain  = delete $option{on_drain};
    my $on_cancel = delete $option{on_cancel};
    my $operation = $kind . '_body';

    croak "$operation(): on_drain must be a coderef"
        if defined($on_drain) && ref($on_drain) ne 'CODE';
    croak "$operation(): on_cancel must be a coderef"
        if defined($on_cancel) && ref($on_cancel) ne 'CODE';
    croak "$operation(): unknown option: " . join(', ', sort keys %option)
        if %option;

    my $self = bless {
        transaction  => $transaction,
        kind         => $kind,
        on_drain     => $on_drain,
        on_cancel    => $on_cancel,
        complete     => 0,
        cancelled    => 0,
        flow_blocked => 0,
    }, $class;

    weaken($self->{transaction});

    return $self;
}

sub is_complete {
    my ($self) = @_;
    return $self->{complete} ? 1 : 0;
}

sub is_cancelled {
    my ($self) = @_;
    return $self->{cancelled} ? 1 : 0;
}

sub _assert_writable {
    my ($self, $operation) = @_;

    croak "$operation(): streaming body is already complete"
        if $self->{complete};
    croak "$operation(): streaming body was cancelled"
        if $self->{cancelled};

    my $transaction = $self->{transaction}
        or croak "$operation(): HTTP/3 Transaction is no longer available";

    return $transaction;
}

sub write {
    my ($self, $bytes) = @_;

    my $operation = $self->{kind} . '_body->write';
    my $transaction = $self->_assert_writable($operation);

    $bytes = Unblock::HTTP3::_Bytes::byte_string('body', $bytes);

    $self->{flow_blocked} = 1;

    my ($can_continue, $ok, $error);

    {
        local $@;
        $ok = eval {
            $can_continue = $transaction->_write_body(
                $self->{kind},
                $bytes,
                0,
                $operation,
            );
            1;
        };
        $error = $@;
    }

    if (!$ok) {
        $self->{flow_blocked} = 0;
        die $error;
    }

    $self->{flow_blocked} = 0 if $can_continue;
    return $can_continue;
}

sub complete {
    my ($self, $bytes) = @_;
    $bytes = '' unless defined $bytes;

    my $operation = $self->{kind} . '_body->complete';
    my $transaction = $self->_assert_writable($operation);

    $bytes = Unblock::HTTP3::_Bytes::byte_string('body', $bytes);

    $transaction->_write_body(
        $self->{kind},
        $bytes,
        1,
        $operation,
    );

    $self->{complete} = 1;
    $self->{flow_blocked} = 0;

    return $self;
}

sub _drain {
    my ($self) = @_;

    return if $self->{complete} || $self->{cancelled};
    return unless $self->{flow_blocked};

    $self->{flow_blocked} = 0;

    my $callback = $self->{on_drain} or return;
    $callback->($self);

    return;
}

sub _cancel {
    my ($self) = @_;

    return if $self->{complete} || $self->{cancelled};

    $self->{cancelled} = 1;
    $self->{flow_blocked} = 0;

    my $callback = $self->{on_cancel} or return;
    $callback->($self);

    return;
}

1;

__END__

=head1 NAME

Unblock::HTTP3::Body::Stream - writable outgoing HTTP/3 body stream

=head1 SYNOPSIS

    my $body = $tx->response_body(
        on_drain  => sub { ... },
        on_cancel => sub { ... },
    );

    if (!$body->write($bytes)) {
        # Pause production until on_drain runs.
    }

    $body->complete;

=head1 DESCRIPTION

A Body::Stream sends an HTTP/3 request or response body incrementally.

Body::Stream objects are created by L<Unblock::HTTP3::Transaction>. Applications
do not construct them directly.

C<write> uses bounded buffering. A false return means the bytes were accepted,
but the producer should pause until C<on_drain> runs.

C<on_cancel> runs if the Transaction ends before body production completes.

=head1 METHODS

=head2 write

    my $can_continue = $body->write($bytes);

Queues body bytes.

Returns true when the producer may continue immediately. Returns false when the
bytes were accepted but production should pause for backpressure.

=head2 complete

    $body->complete;
    $body->complete($final_bytes);

Finishes the outgoing body. Optional final bytes are queued before the clean
end.

Returns the Body::Stream.

=head2 is_complete

True after the producer has completed the body.

=head2 is_cancelled

True if the Transaction cancelled the body before normal completion.

=head1 SEE ALSO

L<Unblock::HTTP3::Transaction>, L<Unblock::HTTP3::Body::Reader>

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

This software is available under the MIT License.

=cut
