package Unblock::HTTP::_WebSocketH2Body;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed weaken);

# Stream-specific adapter for HTTP2/HTTP3. WebSocket output is accepted
# into a bounded producer queue and flushed only after protocol callbacks
# unwind. The framework must schedule defer() on a later loop turn.
sub new {
    my ($class, %option) = @_;
    my $tx = delete $option{transaction};
    my $defer = delete $option{defer};
    croak 'H2 WebSocket bridge requires a streaming Transaction'
        unless blessed($tx) && $tx->can('write') && $tx->can('end');
    croak 'H2 WebSocket bridge requires a defer callback'
        unless ref($defer) eq 'CODE';
    croak 'H2 WebSocket bridge unknown options'
        if %option;
    my $self = bless {
        transaction => $tx,
        defer       => $defer,
        queue       => [],
        queued      => 0,
        scheduled   => 0,
        waiting     => 0,
        ending      => 0,
        ended       => 0,
        aborted     => undef,
        detached    => 0,
    }, $class;
    weaken($self->{transaction});
    return $self;
}

sub websocket {
    my ($self, $ws) = @_;
    $self->{websocket} = $ws;
    weaken($self->{websocket});
    return $self;
}

# Whole-buffer acceptance. Return false after acceptance to backpressure
# the WebSocket producer. A single frame may exceed the high-water mark.
sub unblock_send {
    my ($self, $bytes) = @_;
    croak 'H2 WebSocket body is no longer writable'
        if $self->{detached} || $self->{ending} || defined($self->{aborted});
    croak 'H2 WebSocket body requires byte strings'
        if !defined($bytes) || ref($bytes);
    if (length $bytes) {
        push @{ $self->{queue} }, "$bytes";
        $self->{queued} += length $bytes;
        $self->_schedule;
    }
    return $self->{queued} < 65_536 ? 1 : 0;
}

sub unblock_finish {
    my ($self) = @_;
    return if $self->{detached} || $self->{ending};
    $self->{ending} = 1;
    $self->_schedule;
    return;
}

sub unblock_abort {
    my ($self, $reason) = @_;
    return if $self->{detached} || defined($self->{aborted});
    $self->{aborted} = defined($reason) ? "$reason" : 'WebSocket failed';
    $self->{queue} = [];
    $self->{queued} = 0;
    $self->_schedule;
    return;
}

sub resume {
    my ($self) = @_;
    return if $self->{detached};
    $self->{waiting} = 0;
    $self->_schedule;
    return;
}

sub detach {
    my ($self) = @_;
    $self->{detached} = 1;
    $self->{queue} = [];
    $self->{queued} = 0;
    delete $self->{transaction};
    delete $self->{websocket};
    return;
}

sub _schedule {
    my ($self) = @_;
    return if $self->{detached} || $self->{scheduled};
    $self->{scheduled} = 1;
    my $ok = eval {
        $self->{defer}->(sub {
            $self->{scheduled} = 0;
            $self->_flush;
        });
        1;
    };
    unless ($ok) {
        $self->{scheduled} = 0;
        die $@;
    }
    return;
}

sub _flush {
    my ($self) = @_;
    return if $self->{detached};
    my $tx = $self->{transaction};
    return $self->detach unless $tx && !$tx->is_terminal;

    if (defined($self->{aborted})) {
        $tx->cancel;
        return;
    }
    return if $self->{waiting};

    while (@{ $self->{queue} }) {
        my $bytes = shift @{ $self->{queue} };
        $self->{queued} -= length $bytes;
        # A false write return means the full buffer was accepted into H2
        # but the producer must wait for on_drain before further writes.
        my $ready = $tx->write($bytes);
        unless ($ready) {
            $self->{waiting} = 1;
            last;
        }
    }

    if (!$self->{waiting} && !@{ $self->{queue} } && $self->{ending}
        && !$self->{ended}) {
        $self->{ended} = 1;
        $tx->end;
    }

    if (!$self->{waiting} && $self->{queued} < 32_768) {
        my $ws = $self->{websocket};
        $ws->resume_output if $ws && !$ws->is_closed;
    }
    return;
}

1;

__END__

=head1 NAME

Unblock::HTTP::_WebSocketH2Body - Deferred multiplexed HTTP2/HTTP3 WebSocket body transport

=head1 DESCRIPTION

Internal stream-specific bridge reused by HTTP2 and HTTP3. Incoming
DATA is passed to the WebSocket through Transaction C<on_data>.
Outgoing complete WebSocket frame buffers are queued and written to
the same HTTP Transaction on a framework-deferred turn. C<on_drain>
wakes a blocked producer. C<unblock_finish> sends END_STREAM after
queued frames. WebSocket errors cancel only their own transaction,
not the entire multiplexed connection.

The framework C<defer> callback must schedule a later loop turn,
never invoke the closure synchronously from a protocol callback.

=cut
