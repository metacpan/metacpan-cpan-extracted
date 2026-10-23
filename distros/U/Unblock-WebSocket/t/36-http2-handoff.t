use strict;
use warnings;
use Test::More;

BEGIN {
    eval {
        require Unblock::HTTP2::Client;
        require Unblock::HTTP2::Server;
        require Unblock::WebSocket::Handshake;
        1;
    } or plan skip_all => 'Unblock::HTTP2 is an optional integration dependency';
}

use Unblock::WebSocket::Client;
use Unblock::WebSocket::Server;

{
    package Local::H2WebSocketBody;

    sub new {
        my ($class, $tx) = @_;
        return bless {
            tx => $tx, pending => [], end_pending => 0,
            ended => 0, aborted => [],
        }, $class;
    }

    sub unblock_send {
        my ($self, $bytes) = @_;
        push @{ $self->{pending} }, $bytes;
        return;  # Queue first; never recurse into HTTP/2 from its callbacks.
    }

    sub unblock_finish {
        ++$_[0]{end_pending};
        return;
    }

    sub unblock_abort {
        push @{ $_[0]{aborted} }, $_[1];
        return;
    }

    sub flush {
        my ($self) = @_;
        my $moved = 0;
        while (@{ $self->{pending} }) {
            my $bytes = shift @{ $self->{pending} };
            $self->{tx}->write($bytes);
            $moved += length $bytes;
        }
        if ($self->{end_pending} && !$self->{ended}) {
            $self->{tx}->end;
            $self->{ended} = 1;
            ++$moved;
        }
        return $moved;
    }
}

my ($server_ws, $client_ws, $server_bridge, $client_bridge);
my (@bridges, @server_messages, @client_messages, @errors);
my ($server_handshake, $client_handshake, $ws_request) = (undef,
    Unblock::WebSocket::Handshake->client_request(
        'wss://example.test/chat',
        http_version => '2',
    ),
);

my $ordinary_seen = 0;
my $server = Unblock::HTTP2::Server->new(
    enable_connect_protocol => 1,
    on_request => sub {
        my ($tx, $request) = @_;
        if ($request->target eq '/ordinary') {
            $tx->respond(status => 200, body => 'ordinary-ok');
            return;
        }

        $server_handshake =
            Unblock::WebSocket::Handshake->server_accept($request);
        $tx->respond($server_handshake->server_response, stream_body => 1);
        $server_bridge = Local::H2WebSocketBody->new($tx);
        push @bridges, $server_bridge;
        $server_ws = Unblock::WebSocket::Server->new(
            %{ $server_handshake->connection_options },
            backend => 'perl',
            transport => $server_bridge,
            on_message => sub {
                my ($ws, $message, $type) = @_;
                push @server_messages, [$message, $type];
                $ws->send_text("reply:$message");
            },
        );
    },
    on_body => sub {
        my ($tx, $request, $bytes) = @_;
        $server_ws->input($bytes)
            if $request->target eq '/chat';
    },
    on_error => sub { push @errors, "server: $_[1]" },
);

my $client = Unblock::HTTP2::Client->new;

sub transfer {
    my ($from, $to) = @_;
    my $moved = 0;
    while ($from->want_write) {
        my $wire = $from->output;
        last unless length $wire;
        $to->input($wire);
        $moved += length $wire;
    }
    return $moved;
}

sub pump {
    for (1 .. 1000) {
        my $moved = 0;
        $moved += $_->flush for @bridges;
        $moved += transfer($client, $server);
        $moved += transfer($server, $client);
        return unless $moved;
    }
    die 'HTTP/2 WebSocket pump did not settle';
}

pump(); # Complete the SETTINGS exchange, including Extended CONNECT support.
is $client->peer_setting('enable_connect_protocol'), 1,
    'HTTP/2 peer enabled Extended CONNECT';

my $ws_tx = $client->request(
    $ws_request,
    stream_body => 1,
    on_response => sub {
        my ($tx, $response) = @_;
        $client_handshake->validate_client_response($response);
        $client_bridge = Local::H2WebSocketBody->new($tx);
        push @bridges, $client_bridge;
        $client_ws = Unblock::WebSocket::Client->new(
            %{ $client_handshake->connection_options },
            backend => 'perl',
            transport => $client_bridge,
            on_message => sub { push @client_messages, $_[1] },
        );
    },
    on_body => sub {
        my ($tx, $response, $bytes) = @_;
        $client_ws->input($bytes);
    },
    on_error => sub { push @errors, "client WS: $_[1]" },
);
pump();
ok $server_ws && $client_ws, 'both WebSocket engines opened on one H2 stream';
ok !$ws_tx->is_terminal, 'WebSocket HTTP/2 Transaction remains streaming';

$client_ws->send_text('hello-h2');
pump();
is_deeply \@server_messages, [['hello-h2', 'text']],
    'server received WebSocket message as H2 DATA';
is_deeply \@client_messages, ['reply:hello-h2'],
    'server responded on same H2 Transaction';

my $regular_body = '';
$client->request(
    method => 'GET', target => '/ordinary',
    scheme => 'https', authority => 'example.test',
    on_body => sub { $regular_body .= $_[2] },
    on_complete => sub { ++$ordinary_seen },
    on_error => sub { push @errors, "client ordinary: $_[1]" },
);
pump();
is $regular_body, 'ordinary-ok',
    'ordinary H2 transaction remains usable during WebSocket traffic';
is $ordinary_seen, 1, 'ordinary response completed';
ok !$ws_tx->is_terminal, 'ordinary transaction did not terminate WS stream';

$client_ws->close;
pump();
ok $server_ws->close_received, 'server received WebSocket Close frame';
ok $client_ws->close_received, 'client received WebSocket Close reply';
is scalar @{ $server_bridge->{aborted} }, 0,
    'WebSocket server bridge was not aborted';
is scalar @{ $client_bridge->{aborted} }, 0,
    'WebSocket client bridge was not aborted';
is_deeply \@errors, [], 'HTTP/2 integration reports no errors';

done_testing;
