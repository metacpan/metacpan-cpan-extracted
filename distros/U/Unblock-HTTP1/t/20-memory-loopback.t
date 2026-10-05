use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;

my $seen = {};
my $server = Unblock::HTTP1::Server->new(
    on_request => sub {
        my ($tx, $request) = @_;
        $seen->{method} = $request->method;
        $seen->{target} = $request->target;
        $tx->respond(Uniform::HTTP::Response->new(
            status  => 200,
            headers => [ [ 'X-Test', 'yes' ] ],
            body    => 'world',
        ));
    },
);

my $body = '';
my $complete = 0;
my $client = Unblock::HTTP1::Client->new;
my $tx = $client->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/hello',
        authority => 'example.test',
    ),
    on_response => sub {
        my ($tx, $response) = @_;
        is($response->status, 200, 'client receives response status');
        is($response->header('X-Test'), 'yes', 'client receives response header');
        ok(!$response->is_complete, 'response incomplete at head callback');
    },
    on_body => sub {
        my ($tx, $response, $bytes) = @_;
        $body .= $bytes;
    },
    on_complete => sub { $complete++ },
    on_error => sub { die "client error: $_[1]" },
);

my $request_wire = $client->output;
like($request_wire, qr/^GET \/hello HTTP\/1\.1\r\n/s, 'client serializes request line');
like($request_wire, qr/\r\nHost: example\.test\r\n/i, 'authority can supply HTTP/1.1 Host on wire');
$server->input($request_wire);

is($seen->{method}, 'GET', 'server receives method');
is($seen->{target}, '/hello', 'server receives exact target');
my $response_wire = $server->output;
$client->input($response_wire);

is($body, 'world', 'response body crosses in-memory transport');
is($complete, 1, 'client transaction completes');
ok($tx->is_complete, 'Transaction reports complete');
ok($tx->response->is_complete, 'Uniform response completes and freezes');

done_testing;
