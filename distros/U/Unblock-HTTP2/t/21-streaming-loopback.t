use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until);
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

my %seen = (
    request_body  => '',
    response_body => '',
    server_errors => [],
    client_errors => [],
);

my $server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($stream, $request) = @_;
        ok !$request->is_complete,
            'streaming request starts incomplete on server';
    },

    on_body => sub {
        my ($stream, $request, $bytes) = @_;
        $seen{request_body} .= $bytes;
    },

    on_request_end => sub {
        my ($stream, $request) = @_;

        ok $request->is_complete,
            'streaming request becomes complete at END_STREAM';
        is $request->trailer('x-request-end'), 'yes',
            'streaming request trailers arrive before request end';

        my $response = Uniform::HTTP::Response->new(
            status  => 200,
            headers => [ [ 'content-type', 'text/plain' ] ],
        );

        $stream->respond($response, stream_body => 1);
        ok $response->is_complete,
            'application response completeness is independent of stream production';

        is $stream->write('reply-one:'), 1,
            'first response chunk is accepted';
        $response->add_trailer('X-Response-End', 'yes');
        $stream->end('reply-two');
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @{ $seen{server_errors} }, $error;
    },
);

my $client = Unblock::HTTP2::Client->new;

my $request = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/stream',
    scheme    => 'https',
    authority => 'example.test',
);

my $complete = 0;
my $stream = $client->request(
    $request,
    stream_body => 1,

    on_response => sub {
        my ($stream, $response) = @_;
        is $response->status, 200, 'streaming response status arrives';
        ok !$response->is_complete,
            'streaming response starts incomplete on client';
    },

    on_body => sub {
        my ($stream, $response, $bytes) = @_;
        $seen{response_body} .= $bytes;
    },

    on_complete => sub {
        my ($stream) = @_;
        ok $stream->response->is_complete,
            'streaming response becomes complete at END_STREAM';
        is $stream->response->trailer('x-response-end'), 'yes',
            'streaming response trailers arrive before completion';
        $complete = 1;
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @{ $seen{client_errors} }, $error;
    },
);

ok $request->is_complete,
    'application request completeness is not repurposed for stream production';

is $stream->write('request-one:'), 1,
    'first request chunk is accepted';
$request->add_trailer('X-Request-End', 'yes');
$stream->end('request-two');

ok $request->is_complete,
    'ending the stream does not mutate application request completeness';

pump_until($client, $server, sub { $complete });

is $seen{request_body}, 'request-one:request-two',
    'server receives streaming request bytes in order';
is $seen{response_body}, 'reply-one:reply-two',
    'client receives streaming response bytes in order';
is_deeply $seen{server_errors}, [], 'server reports no streaming errors';
is_deeply $seen{client_errors}, [], 'client reports no streaming errors';
ok $stream->is_complete, 'full HTTP/2 stream reaches terminal completion';

done_testing;
