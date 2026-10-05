use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until pump_until_idle);
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

my @server_errors;
my @client_errors;
my ($trailer_exchange_done, $connect_exchange_done);

my $server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($stream, $request) = @_;

        if ($request->target eq '/trailers') {
            is $request->protocol, undef,
                'ordinary request has no Extended CONNECT protocol';
            ok !$request->initial_is_mutable,
                'received request initial section is frozen';
            ok $request->trailers_are_mutable,
                'received request trailer section remains open';
            return;
        }

        if ($request->target eq '/chat') {
            is $request->method, 'CONNECT',
                'server receives Extended CONNECT method';
            is $request->protocol, 'websocket',
                'server receives generic Extended CONNECT protocol';
            is $request->scheme, 'https',
                'server receives Extended CONNECT scheme';
            is $request->authority, 'example.test',
                'server receives Extended CONNECT authority';
            ok !$request->initial_is_mutable,
                'Extended CONNECT initial section is frozen after receipt';
            return;
        }

        fail 'server received unexpected request target';
    },

    on_body => sub {
        my ($stream, $request, $bytes) = @_;
        if ($request->target eq '/trailers') {
            is $bytes, 'ping', 'request body arrives before request trailers';
        }
    },

    on_request_end => sub {
        my ($stream, $request) = @_;

        ok $request->is_complete,
            'received request is complete at request end';
        ok !$request->is_mutable,
            'completed received request is fully frozen';

        if ($request->target eq '/trailers') {
            is_deeply(
                $request->trailer_values('x-client-checksum'),
                [ 'abc', 'def' ],
                'request trailers reach the Uniform request losslessly',
            );

            my $response = Uniform::HTTP::Response->new(
                status => 200,
                body   => 'pong',
                trailers => [
                    [ 'X-Server-Checksum', 'one' ],
                    [ 'x-server-checksum', 'two' ],
                ],
            );
            $stream->respond($response);
            return;
        }

        if ($request->target eq '/chat') {
            my $response = Uniform::HTTP::Response->new(
                status => 200,
                body   => 'connected',
            );
            $stream->respond($response);
            return;
        }
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @server_errors, $error;
    },
);

my $client = Unblock::HTTP2::Client->new;

pump_until_idle($client, $server);

my $request = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/trailers',
    scheme    => 'https',
    authority => 'example.test',
    body      => 'ping',
    trailers  => [
        [ 'X-Client-Checksum', 'abc' ],
        [ 'x-client-checksum', 'def' ],
    ],
);

my $stream = $client->request(
    $request,

    on_response => sub {
        my ($stream, $response) = @_;
        is $response->status, 200, 'client receives trailer response status';
        ok !$response->initial_is_mutable,
            'received response initial section is frozen';
        ok $response->trailers_are_mutable,
            'response can still acquire trailing fields';
    },

    on_body => sub {
        my ($stream, $response, $bytes) = @_;
        is $bytes, 'pong', 'response body arrives before response trailers';
    },

    on_complete => sub {
        my ($stream) = @_;
        my $response = $stream->response;

        is_deeply(
            $response->trailer_values('x-server-checksum'),
            [ 'one', 'two' ],
            'response trailers reach the Uniform response losslessly',
        );
        ok $response->is_complete,
            'response with trailers becomes complete';
        ok !$response->is_mutable,
            'completed response with trailers is fully frozen';
        $trailer_exchange_done = 1;
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @client_errors, $error;
    },
);

is $request->version, undef,
    'outgoing request remains version neutral after submission';
ok $request->initial_is_mutable,
    'outgoing application request remains application-owned';

pump_until($client, $server, sub { $trailer_exchange_done });

my $connect = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    protocol  => 'websocket',
    scheme    => 'https',
    authority => 'example.test',
    target    => '/chat',
);

my $connect_stream = $client->request(
    $connect,
    stream_body => 1,

    on_response => sub {
        my ($stream, $response) = @_;
        is $response->status, 200,
            'Extended CONNECT receives a normal Uniform response';
    },

    on_body => sub {
        my ($stream, $response, $bytes) = @_;
        is $bytes, 'connected',
            'Extended CONNECT response data uses the normal stream path';
    },

    on_complete => sub {
        $connect_exchange_done = 1;
    },

    on_error => sub {
        my ($stream, $error) = @_;
        push @client_errors, $error;
    },
);

$connect_stream->end;
pump_until($client, $server, sub { $connect_exchange_done });

is $connect->version, undef,
    'Extended CONNECT request remains version neutral';
is $connect->protocol, 'websocket',
    'application Extended CONNECT metadata is unchanged';
is_deeply \@server_errors, [], 'server reports no Uniform 0.06 errors';
is_deeply \@client_errors, [], 'client reports no Uniform 0.06 errors';

done_testing;
