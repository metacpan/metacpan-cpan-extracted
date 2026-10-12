use strict;
use warnings;

use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;

use Unblock::HTTP3::Connection;
use Unblock::HTTP3::Server;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP3::Transaction;
use Net::QUIC::Endpoint;

my $endpoint = Net::QUIC::Endpoint->client(
    local       => pack_sockaddr_in(40031, inet_aton('127.0.0.1')),
    peer        => pack_sockaddr_in(4433, inet_aton('127.0.0.1')),
    alpn        => 'h3',
    server_name => 'localhost',
);

my $h3 = Unblock::HTTP3::Server->new(
    quic => $endpoint->connection,
);

my $next_id = 0;

sub make_tx {
    my (%args) = @_;

    my $method = delete $args{method};
    my $status = delete $args{status};

    my $request = Uniform::HTTP::Request->new(
        method => $method,
        target => '/',
    );

    my $response = Uniform::HTTP::Response->new(
        status => $status,
    );

    my $id = $next_id;
    $next_id += 4;

    my $tx = Unblock::HTTP3::Transaction->_new(
        connection => $h3,
        stream_id  => $id,
        request    => $request,
        response   => $response,
    );

    $h3->{transactions}{$id} = $tx;

    return $tx;
}

for my $case (
    [ HEAD => 200, 'response to HEAD' ],
    [ GET  => 204, '204 response' ],
    [ GET  => 205, '205 response' ],
    [ GET  => 304, '304 response' ],
) {
    my ($method, $status, $label) = @$case;
    my $tx = make_tx(
        method => $method,
        status => $status,
    );

    like(
        dies { $tx->response_body },
        qr/must not contain content/,
        "$label rejects an incremental response body",
    );
}

for my $case (
    [ HEAD => 200, 'response to HEAD' ],
    [ GET  => 204, '204 response' ],
    [ GET  => 205, '205 response' ],
    [ GET  => 304, '304 response' ],
) {
    my ($method, $status, $label) = @$case;
    my $tx = make_tx(
        method => $method,
        status => $status,
    );

    $tx->response->body('not allowed');

    like(
        dies { $tx->respond($tx->response) },
        qr/must not contain content/,
        "$label rejects a buffered response body",
    );
}

my $trailer_tx = make_tx(
    method => 'HEAD',
    status => 200,
);
$trailer_tx->response->add_trailer('x-test', 'not-allowed');

like(
    dies { $trailer_tx->respond($trailer_tx->response) },
    qr/must not contain content/,
    'bodyless response semantics reject trailers',
);

my $normal = make_tx(
    method => 'GET',
    status => 200,
);

isa_ok(
    $normal->response_body,
    ['Unblock::HTTP3::Body::Stream'],
    'ordinary 200 response may use an incremental body',
);

done_testing;
