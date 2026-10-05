use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until);
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

my $request_bytes = 0;
my $request_drain = 0;
my $request_complete = 0;
my @errors;

my $server = Unblock::HTTP2::Server->new(
    on_body => sub {
        my ($stream, $request, $bytes) = @_;
        $request_bytes += length $bytes;
    },

    on_request_end => sub {
        my ($stream, $request) = @_;
        $stream->respond(
            Uniform::HTTP::Response->new(
                status => 200,
                body   => 'ok',
            ),
        );
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "server request: $error";
    },
);

my $client = Unblock::HTTP2::Client->new;

my $request_stream = $client->request(
    Uniform::HTTP::Request->new(
        method    => 'POST',
        target    => '/request-pressure',
        scheme    => 'https',
        authority => 'example.test',
    ),
    stream_body => 1,

    on_drain => sub {
        ++$request_drain;
    },

    on_complete => sub {
        $request_complete = 1;
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "client request: $error";
    },
);

my $request_payload = 'r' x 70_000;
is $request_stream->write($request_payload), 0,
    'large request write is accepted but applies producer backpressure';

pump_until($client, $server, sub { $request_drain });

is $request_drain, 1,
    'request producer receives one drain notification after queue falls below low water';

$request_stream->end('tail');

pump_until($client, $server, sub { $request_complete });

is $request_bytes, length($request_payload) + length('tail'),
    'all request bytes survive flow-control chunking';
is_deeply \@errors, [],
    'request backpressure path reports no errors';

my $response_bytes = 0;
my $response_drain = 0;
my $response_complete = 0;
my $response_write_result;

my $response_server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($stream, $request) = @_;

        my $response = Uniform::HTTP::Response->new(status => 200);
        $stream->respond(
            $response,
            stream_body => 1,

            on_drain => sub {
                my ($stream) = @_;
                ++$response_drain;
                $stream->end('tail');
            },

            on_error => sub {
                my ($stream, $error) = @_;
                push @errors, "server response stream: $error";
            },
        );

        $response_write_result = $stream->write('s' x 70_000);
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "server response: $error";
    },
);

my $response_client = Unblock::HTTP2::Client->new;

my $response_stream = $response_client->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/response-pressure',
        scheme    => 'https',
        authority => 'example.test',
    ),

    on_body => sub {
        my ($stream, $response, $bytes) = @_;
        $response_bytes += length $bytes;
    },

    on_complete => sub {
        $response_complete = 1;
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @errors, "client response: $error";
    },
);

pump_until(
    $response_client,
    $response_server,
    sub { $response_complete },
);

is $response_write_result, 0,
    'large response write is accepted but applies producer backpressure';
is $response_drain, 1,
    'response producer receives one drain notification';
is $response_bytes, 70_000 + length('tail'),
    'all response bytes survive flow-control chunking';
ok $response_stream->is_complete,
    'response stream completes after drain-driven final write';
is_deeply \@errors, [],
    'response backpressure path reports no errors';

done_testing;
