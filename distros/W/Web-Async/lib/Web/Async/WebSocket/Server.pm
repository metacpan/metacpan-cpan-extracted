package Web::Async::WebSocket::Server;
use Full::Class qw(:v1), extends => 'IO::Async::Notifier';

our $VERSION = '0.006'; ## VERSION
## AUTHORITY

=head1 NAME

Web::Async::WebSocket::Server - L<Future>-based web+HTTP handling

=head1 DESCRIPTION

Provides basic websocket server implementation.

=cut

use Ryu::Async;
use IO::Async::Listener;

use Web::Async::WebSocket::Server::Connection;

field $srv;
field $ryu : reader : param = undef;

=head1 METHODS

=head2 port

Returns the current listening port.

=cut

field $port : reader : param = undef;

=head2 incoming_client

A L<Ryu::Source> which emits an event every time a client connects.

=cut

field $incoming_client : reader : param = undef;

=head2 disconnecting_client

A L<Ryu::Source> which emits an event every time a client disconnects.

=cut

field $disconnecting_client : reader : param = undef;

=head2 closing_client

A L<Ryu::Source> which emits an event every time a client closes normally.

=cut

field $closing_client : reader : param = undef;
field $active_client : reader { +{ } }

field $handshake : reader : param = undef;
field $on_handshake_failure : reader : param = undef;

field $listening : reader = undef;

method configure (%args) {
    $port = delete $args{port} if exists $args{port};
    $on_handshake_failure = delete $args{on_handshake_failure} if exists $args{on_handshake_failure};
    $handshake = delete $args{handshake} if exists $args{handshake};
    $incoming_client = delete $args{incoming_client} if exists $args{incoming_client};
    $closing_client = delete $args{closing_client} if exists $args{closing_client};
    $disconnecting_client = delete $args{disconnecting_client} if exists $args{disconnecting_client};
    return $self->next::method(%args);
}

method _add_to_loop ($loop) {
    $self->add_child(
        $ryu = Ryu::Async->new
    ) unless $ryu;
    $incoming_client //= $self->ryu->source;
    $closing_client //= $self->ryu->source;
    $disconnecting_client //= $self->ryu->source;
    $self->add_child(
        $srv = IO::Async::Listener->new(
            on_stream => $self->curry::weak::on_stream,
        )
    );
    $self->adopt_future(
        $listening = $srv->listen(
            service  => $port,
            socktype => 'stream',
        )->on_ready(sub { undef $listening })
    );
}

method on_stream ($listener, $stream, @) {
    $log->tracef('Connection %s for listener %s', "$stream", "$listener");
    $stream->configure(
        on_read => sub { 0 }
    );
    my $client = Web::Async::WebSocket::Server::Connection->new(
        server               => $self,
        stream               => $stream,
        ryu                  => $ryu,
        handshake            => $handshake,
        on_handshake_failure => $on_handshake_failure,
    );
    $active_client->{$client} = $client;
    $log->infof('Client %s recorded', "$client");
    $self->add_child($client);
    $incoming_client->emit($client);
    $self->adopt_future(
        $client->handle_connection
    );
}

method on_client_close ($client, %args) {
    $closing_client->emit({
        client => $client,
        %args,
    });
    return;
}

method on_client_disconnect ($client, @) {
    $disconnecting_client->emit({
        client => $client
    });
    delete $active_client->{$client} or $log->errorf('Client %s was not recorded', "$client");
    return;
}

1;

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2024. Licensed under the same terms as Perl itself.

