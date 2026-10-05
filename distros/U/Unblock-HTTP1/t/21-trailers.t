use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;

my $request_body = '';
my $request_trailer;
my $server = Unblock::HTTP1::Server->new(
    on_request => sub { },
    on_body => sub {
        my ($tx, $request, $bytes) = @_;
        $request_body .= $bytes;
    },
    on_request_end => sub {
        my ($tx, $request) = @_;
        $request_trailer = $request->trailer('X-Request-End');
        $tx->respond(Uniform::HTTP::Response->new(
            status => 200,
            body => 'reply',
            trailers => [ [ 'X-Response-End', 'done' ] ],
        ));
    },
);

my $response_body = '';
my $response_trailer;
my $client = Unblock::HTTP1::Client->new;
$client->request(
    Uniform::HTTP::Request->new(
        method => 'POST',
        target => '/upload',
        authority => 'example.test',
        body => 'payload',
        trailers => [ [ 'X-Request-End', 'yes' ] ],
    ),
    on_body => sub { $response_body .= $_[2] },
    on_complete => sub {
        my ($tx) = @_;
        $response_trailer = $tx->response->trailer('X-Response-End');
    },
    on_error => sub { die "client error: $_[1]" },
);

my $request_wire = $client->output;
like(
    $request_wire,
    qr/\r\nTrailer: X-Request-End\r\n/,
    'known request trailer is announced before the body',
);
$server->input($request_wire);

my $response_wire = $server->output;
like(
    $response_wire,
    qr/\r\nTrailer: X-Response-End\r\n/,
    'known response trailer is announced before the body',
);
$client->input($response_wire);

is($request_body, 'payload', 'chunked request body decoded');
is($request_trailer, 'yes', 'request trailer preserved in Uniform request');
is($response_body, 'reply', 'chunked response body decoded');
is($response_trailer, 'done', 'response trailer preserved in Uniform response');

done_testing;
