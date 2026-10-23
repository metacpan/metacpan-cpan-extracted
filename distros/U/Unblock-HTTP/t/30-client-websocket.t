use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);

BEGIN {
    eval {
        require Unblock::HTTP1::Client;
        require Unblock::HTTP1::Server;
        require Unblock::WebSocket::Client;
        require Unblock::WebSocket::Handshake;
        1;
    } or plan skip_all => 'HTTP1 and WebSocket are required';
}

use Unblock::HTTP::Client;
use Unblock::HTTP::Server;

{
    package Local::WSWireHost;
    sub new { bless { outgoing => [], upgrades => 0, aborts => [] }, shift }
    sub unblock_send { push @{ $_[0]{outgoing} }, $_[1]; return 1 }
    sub unblock_finish { ++$_[0]{finished}; return }
    sub unblock_abort { push @{ $_[0]{aborts} }, $_[1]; return }
    sub unblock_upgrade {
        my ($self, $websocket) = @_;
        die "duplicate WebSocket consumer" if $self->{upgrades}++;
        $self->{consumer} = $websocket;
        return;
    }
    sub take { join '', splice @{ $_[0]{outgoing} } }
}

my (@pairs, @defers, @messages, @events, @releases, @ordinary);
my $server = Unblock::HTTP::Server->new(
    http1 => { websocket => 1 },
    on_request => sub {
        my ($tx, $req) = @_;
        push @ordinary, $req->target;
        $tx->respond(status => 200, body => 'normal');
    },
    on_websocket => sub {
        my ($tx, $req) = @_;
        return unless $req->target eq '/chat';
        return {
            backend => 'perl',
            on_message => sub {
                my ($ws, $payload, $type) = @_;
                $ws->send_text("reply:$payload");
            },
        };
    },
);
my $client = Unblock::HTTP::Client->new(
    http1 => { websocket => 1 },
    connect_stream => sub {
        my ($origin, $alpn, $ready) = @_;
        is_deeply($alpn, ['http/1.1'], 'WebSocket uses strict HTTP1 ALPN');
        my $client_host = Local::WSWireHost->new;
        my $server_host = Local::WSWireHost->new;
        my $server_engine = $server->attach_stream(transport => $server_host);
        $server_host->{consumer} = $server_engine;
        push @pairs, [$client_host, $server_host];
        my $engine = $ready->(transport => $client_host, alpn => 'http/1.1');
        $client_host->{consumer} = $engine;
        return;
    },
    defer => sub { push @defers, $_[0] },
    release_connection => sub {
        push @releases, [@_];
        return;
    },
    max_connections_per_origin => 1,
);

sub pump {
    for (1..30) {
        my $moved = 0;
        for my $pair (@pairs) {
            my ($from_client, $from_server) = @$pair;
            my $a = $from_client->take;
            if (length $a) {
                $from_server->{consumer}->input($a);
                $moved++;
            }
            my $b = $from_server->take;
            if (length $b) {
                $from_client->{consumer}->input($b);
                $moved++;
            }
        }
        while (@defers) {
            my $deferred = shift @defers;
            $deferred->();
            $moved++;
        }
        last unless $moved;
    }
}

my $operation = $client->connect_websocket(
    url => 'ws://example.test/chat',
    backend => 'perl',
    on_open => sub {
        my ($ws, $tx) = @_;
        push @events, 'open';
        isa_ok($ws, 'Unblock::WebSocket::Client');
        isa_ok($tx, 'Unblock::HTTP1::Transaction');
    },
    on_message => sub { push @messages, $_[1] },
    on_finish => sub { push @events, 'finish:' . $_[0]->state },
    on_error => sub { push @events, 'error' },
);
isa_ok($operation, 'Unblock::HTTP::_ClientOperation');
ok(!$operation->websocket, 'operation is not open before HTTP handshake');
pump();
is_deeply(\@events, ['open', 'finish:complete'], 'on_open precedes finished HTTP handshake');
ok($operation->is_terminal, 'HTTP handshake operation is complete');
is($operation->state, 'complete', 'upgrade completes original HTTP transaction');
isa_ok($operation->websocket, 'Unblock::WebSocket::Client');
is(refaddr($operation->websocket), refaddr($pairs[0][0]{consumer}),
    'client transport now dispatches to established WebSocket');
is($pairs[0][0]{upgrades}, 1, 'client input switched once');
is($pairs[0][1]{upgrades}, 1, 'server input switched once');
is($client->pool_stats->{connections}, 0,
    'upgraded socket has left the HTTP pool');
is($client->pool_stats->{active}, 0,
    'WebSocket does not consume an HTTP request slot');
is(scalar @releases, 0, 'pool does not close transferred WebSocket transport');

$operation->websocket->send_text('hello');
pump();
is_deeply(\@messages, ['reply:hello'],
    'WebSocket client and server exchange frames on transferred transport');

# A new ordinary request must open a different connection at the same
# origin; it may not try to reuse an HTTP engine that has switched.
my $http_finished;
my $ordinary_operation = $client->request(
    url => 'http://example.test/normal',
    on_response => sub { $http_finished = $_[1]->body },
);
pump();
is(scalar @pairs, 2, 'ordinary HTTP opens a fresh transport');
is($http_finished, 'normal', 'ordinary HTTP response remains functional');
is_deeply(\@ordinary, ['/normal'], 'server receives the ordinary HTTP request');
is(scalar @releases, 0, 'upgraded transport still not released by HTTP pool');
$client->shutdown;
is(scalar @releases, 1, 'only ordinary idle transport released at shutdown');
is(refaddr($operation->websocket), refaddr($pairs[0][0]{consumer}),
    'WebSocket survives HTTP Client shutdown');

# With WebSocket policy disabled, connect_websocket must fail before
# allocating a transport or starting a handshake.
my $plain = Unblock::HTTP::Client->new(
    http1 => {},
    connect_stream => sub { die 'must not connect' },
    defer => sub { },
);
ok(!eval { $plain->connect_websocket(url => 'ws://example.test/chat'); 1 },
    'connect_websocket requires explicit protocol permission');
like($@, qr/websocket support is disabled/, 'disabled mode has actionable error');
ok(!eval { $client->connect_websocket(url => 'ws://example.test/chat'); 1 },
    'Client shutdown also rejects new WebSocket operations');
like($@, qr/shut down/, 'WebSocket operations honor Client shutdown');

# An HTTP 403 response is a failed handshake, never a WebSocket.
# Validation happens before the HTTP1 parser can change protocol.
my $reject_definition = Unblock::HTTP::Server->new(
    http1 => { websocket => 1 },
    on_request => sub { die 'rejected upgrade is not ordinary HTTP' },
    on_websocket => sub { return undef },
);
my ($reject_host, @reject_errors, @reject_finished);
my $reject_client = Unblock::HTTP::Client->new(
    http1 => { websocket => 1 },
    connect_stream => sub {
        my ($origin, $alpn, $ready) = @_;
        my $ch = Local::WSWireHost->new;
        my $sh = Local::WSWireHost->new;
        $sh->{consumer} = $reject_definition->attach_stream(transport => $sh);
        push @pairs, [$ch, $sh];
        $reject_host = $ch;
        $ch->{consumer} = $ready->(transport => $ch, alpn => 'http/1.1');
    },
    defer => sub { push @defers, $_[0] },
);
my $denied = $reject_client->connect_websocket(
    url => 'ws://example.test/denied',
    on_open => sub { die 'denied WebSocket must not open' },
    on_error => sub { push @reject_errors, $_[1] },
    on_finish => sub { push @reject_finished, $_[0]->state },
);
pump();
is($denied->state, 'error', 'HTTP 403 results in a failed WebSocket handshake');
ok(!$denied->websocket, 'failed handshake creates no established WebSocket');
is($reject_host->{upgrades}, 0, 'rejected handshake does not change input owner');
is(scalar @reject_errors, 1, 'handshake error delivered once');
is_deeply(\@reject_finished, ['error'], 'rejected handshake has one terminal callback');

done_testing;
