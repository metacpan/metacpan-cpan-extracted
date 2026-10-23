package Unblock::HTTP::_ClientOperation;

use strict;
use warnings;
use Scalar::Util qw(weaken);

sub new {
    my ($class, $client, $request, $callbacks, $version, $origin) = @_;
    my $self = bless {
        client      => $client,
        request     => $request,
        callbacks   => $callbacks,
        version     => $version,
        origin      => $origin,
        state       => 'queued',
        error       => undef,
        transaction => undef,
        timer_cancel => undef,
        timeout_error => undef,
    }, $class;
    weaken($self->{client});
    # The Client owns its pools and their active/queued work. A retained
    # completed handle must not keep the entire pool and unrelated
    # connections alive through its private origin bookkeeping.
    weaken($self->{origin});
    return $self;
}

sub state       { $_[0]{state} }
sub error       { $_[0]{error} }
sub transaction { $_[0]{transaction} }
sub websocket   { $_[0]{websocket} }
sub is_terminal { $_[0]{state} =~ /\A(?:complete|error|cancelled)\z/ ? 1 : 0 }

sub _cancel_timer {
    my ($self) = @_;
    my $cancel = delete $self->{timer_cancel} or return;
    eval { $cancel->(); 1 } or warn "request timer cancellation failed: $@";
    return;
}

sub cancel {
    my ($self) = @_;
    return 0 if $self->is_terminal;
    if (my $tx = $self->{transaction}) {
        $tx->cancel;
        return 1;
    }
    $self->{state} = 'cancelled';
    $self->_cancel_timer;
    my $client = $self->{client};
    $client->_cancel_queued($self) if $client;
    return 1;
}

1;

__END__

=head1 NAME

Unblock::HTTP::_ClientOperation - A pending outgoing HTTP request

=head1 DESCRIPTION

A Client request returns this handle immediately, including before its
transport has connected. C<transaction()> becomes the actual engine
Transaction once the request is issued, without an HTTP transaction wrapper.
For C<connect_websocket()>, C<websocket()> becomes the established
C<Unblock::WebSocket::Client> only after the protocol-specific handshake
has been validated. With HTTP/1.1 the entire transport changes its input
consumer and the HTTP transaction finishes at 101. With HTTP/2 or
HTTP/3 the WebSocket remains on one multiplexed H2/H3 transaction until
END_STREAM; C<on_finish> reflects that transaction's eventual terminal
state. HTTP/3 requires peer SETTINGS_ENABLE_CONNECT_PROTOCOL before
dispatch and retains the original pending operation while waiting for
QUIC bidirectional stream credit.

C<state()> is queued, connecting, active, complete, error, or cancelled.
C<error()> reports a connection or transaction error, if any.
C<is_terminal()> and C<cancel()> work before and after dispatch. An
optional per-request positive timeout uses the framework timer; it does
not create a blocking timer or another network queue.

Cancellation before dispatch never creates an engine Transaction. In that
case C<on_finish> is called with the operation handle, not a made-up
Transaction. After dispatch all application transaction callbacks receive
the actual engine Transaction.

=cut
