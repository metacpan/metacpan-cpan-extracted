use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;

my $request_body = '';
my $server = Unblock::HTTP1::Server->new(
    on_request => sub { },
    on_body => sub { $request_body .= $_[2] },
    on_request_end => sub {
        my ($tx) = @_;
        $tx->respond(
            Uniform::HTTP::Response->new(status => 200),
            stream_body => 1,
        );
        $tx->write('abc');
        $tx->end('def');
    },
);

my $response_body = '';
my $client = Unblock::HTTP1::Client->new;
my $tx = $client->request(
    Uniform::HTTP::Request->new(
        method => 'POST', target => '/', authority => 'example.test',
    ),
    stream_body => 1,
    on_body => sub { $response_body .= $_[2] },
    on_error => sub { die "client error: $_[1]" },
);
$server->input($client->output);
$tx->write('one');
$server->input($client->output);
$tx->end('two');
$server->input($client->output);
$client->input($server->output);

is($request_body, 'onetwo', 'streaming request crosses chunked framing');
is($response_body, 'abcdef', 'streaming response crosses chunked framing');
ok($tx->is_complete, 'streaming exchange completes');

done_testing;
