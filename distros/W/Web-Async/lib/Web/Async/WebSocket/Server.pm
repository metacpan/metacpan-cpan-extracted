package Web::Async::WebSocket::Server;
use Myriad::Class extends => 'IO::Async::Notifier';

our $VERSION = '0.004'; ## VERSION
## AUTHORITY

=head1 NAME

Web::Async::WebSocket::Server - L<Future>-based web+HTTP handling

=head1 DESCRIPTION

Although other HTTP-adjacent protocols are planned, currently this only contains L<Web::Async::WebSocket::Server>,
see documentation there for more details.

=cut

use Ryu::Async;
use IO::Async::Listener;

use Web::Async::WebSocket::Server::Connection;

field $srv;
field $ryu : reader : param = undef;
field $port : reader : param = undef;

field $incoming_client : reader : param = undef;
field $disconnecting_client : reader : param = undef;
field $closing_client : reader : param = undef;
field $active_client : reader { +{ } }

field $handshake : reader : param = undef;
field $on_handshake_failure : reader : param = undef;

field $listening : reader = undef;

method configure (%args) {
    $port = delete $args{port} if exists $args{port};
    $on_handshake_failure = delete $args{on_handshake_failure} if exists $args{on_handshake_failure};
    $handshake = delete $args{handshake} if exists $args{handshake};
    return $self->next::method(%args);
}

method _add_to_loop ($loop) {
    $self->add_child(
        $ryu = Ryu::Async->new
    ) unless $ryu;
    $incoming_client //= $self->ryu->source;
    $closing_client //= $self->ryu->source;
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
    $self->add_child(
        my $client = Web::Async::WebSocket::Server::Connection->new(
            stream               => $stream,
            ryu                  => $ryu,
            handshake            => $handshake,
            on_handshake_failure => $on_handshake_failure,
        )
    );
    $active_client->{$client} = $client;
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
    delete $active_client->{$client} or $log->errorf('Client %s was not recorded', "$client");
    return;
}

method on_client_disconnect ($client, @) {
    $disconnecting_client->emit($client);
    delete $active_client->{$client} or $log->errorf('Client %s was not recorded', "$client");
    return;
}

1;

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2024. Licensed under the same terms as Perl itself.

