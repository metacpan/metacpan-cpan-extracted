use strict;
use warnings;

use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;

use Unblock::HTTP3::Client;
use Unblock::HTTP3::Connection;
use Unblock::HTTP3::Server;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP3::Transaction;
use Net::QUIC::Endpoint;

sub make_connection {
    my ($role) = @_;

    my $endpoint = Net::QUIC::Endpoint->client(
        local       => pack_sockaddr_in(40032, inet_aton('127.0.0.1')),
        peer        => pack_sockaddr_in(4433, inet_aton('127.0.0.1')),
        alpn        => 'h3',
        server_name => 'localhost',
    );

    return $role eq 'client'
        ? Unblock::HTTP3::Client->new(quic => $endpoint->connection)
        : Unblock::HTTP3::Server->new(quic => $endpoint->connection);
}

my $client = make_connection('client');

for my $case (
    [ 'abc', 'decimal non-negative integer' ],
    [ '-1',  'decimal non-negative integer' ],
    [ '1, 1','decimal non-negative integer' ],
) {
    my ($value, $error) = @$case;

    my $request = Uniform::HTTP::Request->new(
        method    => 'POST',
        target    => '/',
        scheme    => 'https',
        authority => 'example.com',
        headers   => [
            [ 'content-length', $value ],
        ],
        body => 'x',
    );

    like(
        dies { $client->request($request) },
        qr/$error/,
        "request rejects invalid Content-Length '$value'",
    );
}

my $duplicate = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/',
    scheme    => 'https',
    authority => 'example.com',
    headers   => [
        [ 'content-length', '1' ],
        [ 'content-length', '1' ],
    ],
    body => 'x',
);

like(
    dies { $client->request($duplicate) },
    qr/multiple Content-Length fields/,
    'request rejects duplicate Content-Length fields',
);

my $mismatch = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/',
    scheme    => 'https',
    authority => 'example.com',
    headers   => [
        [ 'content-length', '2' ],
    ],
    body => 'x',
);

like(
    dies { $client->request($mismatch) },
    qr/does not match 1 body bytes/,
    'buffered request body must match Content-Length',
);

my $connect_length = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    target    => 'example.com:443',
    authority => 'example.com:443',
    headers   => [
        [ 'content-length', '1' ],
    ],
);

like(
    dies { $client->request($connect_length) },
    qr/CONNECT request Content-Length must be 0/,
    'CONNECT request does not treat tunnel data as message content',
);

my $server = make_connection('server');
my $next_id = 0;

sub make_tx {
    my (%args) = @_;

    my $method = delete $args{method};
    my $status = delete $args{status};
    my $headers = delete $args{headers} || [];
    my $body = delete $args{body};

    my $request = Uniform::HTTP::Request->new(
        method => $method,
        target => $method eq 'CONNECT' ? 'example.com:443' : '/',
    );

    my @response_args = (
        status  => $status,
        headers => $headers,
    );
    push @response_args, body => $body
        if defined $body;

    my $response = Uniform::HTTP::Response->new(@response_args);

    my $id = $next_id;
    $next_id += 4;

    my $tx = Unblock::HTTP3::Transaction->_new(
        connection => $server,
        stream_id  => $id,
        request    => $request,
        response   => $response,
    );

    $server->{transactions}{$id} = $tx;
    return $tx;
}

my $response_mismatch = make_tx(
    method => 'GET',
    status => 200,
    headers => [
        [ 'content-length', '4' ],
    ],
    body => 'abc',
);

like(
    dies { $response_mismatch->respond($response_mismatch->response) },
    qr/does not match 3 body bytes/,
    'buffered response body must match Content-Length',
);

for my $case (
    [ GET     => 204, '0', '204 response' ],
    [ CONNECT => 200, '0', 'successful CONNECT response' ],
) {
    my ($method, $status, $length, $label) = @$case;

    my $tx = make_tx(
        method => $method,
        status => $status,
        headers => [
            [ 'content-length', $length ],
        ],
    );

    like(
        dies { $tx->respond($tx->response) },
        qr/Content-Length is not allowed/,
        "$label rejects Content-Length",
    );
}

my $head = make_tx(
    method => 'HEAD',
    status => 200,
    headers => [
        [ 'content-length', '12345' ],
    ],
);

is(
    $server->_assert_response_content_length(
        $head,
        $head->response,
        'test',
    ),
    '12345',
    'HEAD may describe the GET representation length',
);

my $not_modified = make_tx(
    method => 'GET',
    status => 304,
    headers => [
        [ 'content-length', '12345' ],
    ],
);

is(
    $server->_assert_response_content_length(
        $not_modified,
        $not_modified->response,
        'test',
    ),
    '12345',
    '304 may describe the corresponding 200 representation length',
);

my $reset = make_tx(
    method => 'GET',
    status => 205,
    headers => [
        [ 'content-length', '1' ],
    ],
);

like(
    dies {
        $server->_assert_response_content_length(
            $reset,
            $reset->response,
            'test',
        );
    },
    qr/205 response must be 0/,
    '205 response rejects nonzero Content-Length',
);

my $stream_tx = make_tx(
    method => 'GET',
    status => 200,
    headers => [
        [ 'content-length', '5' ],
    ],
);
$stream_tx->_enable_response_streaming;

is(
    $server->_assert_incremental_content_length(
        $stream_tx,
        'response',
        $stream_tx->response,
        'abc',
        0,
        'test',
    ),
    undef,
    'partial incremental body below Content-Length is accepted',
);

like(
    dies {
        $server->_assert_incremental_content_length(
            $stream_tx,
            'response',
            $stream_tx->response,
            'def',
            0,
            'test',
        );
    },
    qr/body exceeds Content-Length 5/,
    'incremental response cannot exceed Content-Length',
);

my $short_tx = make_tx(
    method => 'GET',
    status => 200,
    headers => [
        [ 'content-length', '5' ],
    ],
);
$short_tx->_enable_response_streaming;

like(
    dies {
        $server->_assert_incremental_content_length(
            $short_tx,
            'response',
            $short_tx->response,
            'abc',
            1,
            'test',
        );
    },
    qr/does not match 3 body bytes/,
    'incremental response cannot finish before Content-Length',
);

done_testing;
