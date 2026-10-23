use strict;
use warnings;
use Test::More;

use Unblock::WebSocket::Client;
use Unblock::WebSocket::Server;

my @server_message;
my @client_message;
my @server_ping;
my @client_pong;
my @server_close;
my @client_close;

my $server = Unblock::WebSocket::Server->new(
    on_message => sub {
        my ($ws, $payload, $type) = @_;
        push @server_message, [ $payload, $type ];
    },
    on_ping => sub {
        my ($ws, $payload) = @_;
        push @server_ping, $payload;
    },
    on_close => sub {
        my ($ws, $code, $reason) = @_;
        push @server_close, [ $code, $reason ];
    },
);

my $client = Unblock::WebSocket::Client->new(
    random_bytes => sub { return "\x01\x02\x03\x04"; },
    on_message => sub {
        my ($ws, $payload, $type) = @_;
        push @client_message, [ $payload, $type ];
    },
    on_pong => sub {
        my ($ws, $payload) = @_;
        push @client_pong, $payload;
    },
    on_close => sub {
        my ($ws, $code, $reason) = @_;
        push @client_close, [ $code, $reason ];
    },
);

$client->send_text("hello \x{263a}");
$server->input($client->output);
is_deeply $server_message[0], [ "hello \x{263a}", 'text' ],
    'client text reaches server';

$server->send_binary("\x00\x01\xff");
$client->input($server->output);
is_deeply $client_message[0], [ "\x00\x01\xff", 'binary' ],
    'server binary reaches client';

$client->ping('probe');
$server->input($client->output);
is $server_ping[0], 'probe', 'server observes ping';
$client->input($server->output);
is $client_pong[0], 'probe', 'automatic pong returns to client';

$client->close(code => 1000, reason => 'done');
$server->input($client->output);
is_deeply $server_close[0], [ 1000, 'done' ], 'server receives close';
ok $server->is_closing, 'server enters closing state';
ok !$server->want_end, 'server waits to flush close reply before transport end';
my $server_close_wire = $server->output;
ok $server->want_end, 'server may end transport after close reply is drained';
$client->input($server_close_wire);
is_deeply $client_close[0], [ 1000, 'done' ], 'client receives close reply';
ok $client->is_closing, 'client enters closing state';
ok $client->close_complete, 'client observed both close directions';
ok $client->want_end, 'client may end transport after completed close handshake';

done_testing;
