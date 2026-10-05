use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;

my @server_events;
my $server = Unblock::HTTP1::Server->new(
    on_request => sub {
        my ($tx, $request) = @_;
        push @server_events, 'request';
        $tx->respond(Uniform::HTTP::Response->new(
            status => 101,
            headers => [
                [ 'Connection', 'Upgrade' ],
                [ 'Upgrade', 'test-proto' ],
            ],
        ));
    },
    on_request_end => sub { push @server_events, 'request_end' },
    on_switch => sub { push @server_events, 'switch' },
);

my @client_events;
my $client = Unblock::HTTP1::Client->new;
my $tx = $client->request(
    Uniform::HTTP::Request->new(
        method => 'GET',
        target => '/switch',
        authority => 'example.test',
        headers => [
            [ 'Connection', 'Upgrade' ],
            [ 'Upgrade', 'test-proto' ],
        ],
    ),
    on_response => sub { push @client_events, 'response' },
    on_switch => sub { push @client_events, 'switch' },
    on_error => sub { die "client error: $_[1]" },
);

$server->input($client->output . 'PING');
ok($server->is_switched, 'server stops HTTP parsing after 101');
is_deeply(\@server_events, [qw(request request_end switch)],
    'server finishes request lifecycle before switch callback');
is($server->take_remainder, 'PING', 'server preserves same-read post-request bytes');

$client->input($server->output . 'PONG');
ok($client->is_switched, 'client stops HTTP parsing after 101');
is_deeply(\@client_events, [qw(response switch)], 'client reports response then switch');
is($client->take_remainder, 'PONG', 'client preserves same-read post-response bytes');
ok($tx->is_complete, 'switch transaction completes');

done_testing;
