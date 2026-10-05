use strict;
use warnings;

use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;

use Unblock::HTTP3::Connection;
use Uniform::HTTP::Request;
use Unblock::HTTP3::_Native;
use Net::QUIC;
use Net::QUIC::Endpoint;

is($Net::QUIC::VERSION, '0.04', 'testing released Net::QUIC 0.04');

my $endpoint = Net::QUIC::Endpoint->client(
    local       => pack_sockaddr_in(40030, inet_aton('127.0.0.1')),
    peer        => pack_sockaddr_in(4433, inet_aton('127.0.0.1')),
    alpn        => 'h3',
    server_name => 'localhost',
);

my $quic = $endpoint->connection;
isa_ok($quic, ['Net::QUIC::Connection']);

like(
    dies {
        Unblock::HTTP3::Connection->client(
            quic                  => $quic,
            enable_http_datagrams => 1,
        );
    },
    qr/requires QUIC DATAGRAM receive support/,
    'HTTP/3 cannot advertise DATAGRAM without QUIC DATAGRAM transport',
);

my $http3 = Unblock::HTTP3::Connection->client(
    quic => $quic,
);

isa_ok($http3, ['Unblock::HTTP3::Connection']);
is($http3->role, 'client', 'HTTP/3 role is client');
is($http3->quic, $quic, 'HTTP/3 keeps the supplied QUIC connection');

is(
    $http3->qpack_max_table_capacity,
    4096,
    'HTTP/3 defaults to a 4 KiB QPACK dynamic table',
);

is(
    $http3->qpack_blocked_streams,
    100,
    'HTTP/3 defaults to 100 QPACK blocked streams',
);

my $static_qpack = Unblock::HTTP3::Connection->client(
    quic                     => $quic,
    qpack_max_table_capacity => 0,
    qpack_blocked_streams    => 0,
);

is(
    $static_qpack->qpack_max_table_capacity,
    0,
    'QPACK dynamic table can be disabled',
);

is(
    $static_qpack->qpack_blocked_streams,
    0,
    'QPACK blocking can be disabled',
);

like(
    dies {
        Unblock::HTTP3::Connection->client(
            quic                     => $quic,
            qpack_max_table_capacity => '4611686018427387904',
        );
    },
    qr/varint maximum/,
    'public QPACK table capacity is bounded to HTTP/3 varint range',
);

like(
    dies {
        Unblock::HTTP3::_Native->client(
            65_536,
            '4611686018427387904',
            100,
        );
    },
    qr/varint maximum/,
    'native constructor also guards HTTP/3 setting bounds',
);

my $connect = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    target    => 'example.com:443',
    authority => 'example.com:443',
);

is($connect->method, 'CONNECT', 'CONNECT request method is preserved');
is($connect->target, 'example.com:443', 'CONNECT uses authority-form target');
is($connect->authority, 'example.com:443', 'CONNECT authority is preserved');
is($connect->scheme, undef, 'basic CONNECT does not require a scheme');

done_testing;