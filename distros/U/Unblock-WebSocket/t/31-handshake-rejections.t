use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::WebSocket::Handshake;

sub dies_like {
    my ($code, $pattern, $name) = @_;
    my $ok = eval { $code->(); 1 };
    my $error = $@;
    ok(!$ok, $name);
    like($error, $pattern, "$name reports expected error");
}

dies_like(
    sub { Unblock::WebSocket::Handshake->client_request('https://example.test/') },
    qr/scheme must be ws or wss/i,
    'client rejects non-WebSocket scheme',
);

dies_like(
    sub {
        Unblock::WebSocket::Handshake->client_request(
            'ws://user:pass@example.test/',
        );
    },
    qr/userinfo is not supported/i,
    'client rejects URL userinfo',
);

dies_like(
    sub {
        Unblock::WebSocket::Handshake->client_request(
            'ws://example.test/',
            subprotocols => [ 'chat', 'chat' ],
        );
    },
    qr/duplicate subprotocol/i,
    'client rejects duplicate offered subprotocol',
);

dies_like(
    sub {
        Unblock::WebSocket::Handshake->client_request(
            'ws://example.test/',
            headers => [ [ Upgrade => 'other' ] ],
        );
    },
    qr/owns header Upgrade/i,
    'client rejects caller override of reserved handshake header',
);

dies_like(
    sub {
        Unblock::WebSocket::Handshake->client_request(
            'wss://example.test/',
            http_version => '2',
            key => 'dGhlIHNhbXBsZSBub25jZQ==',
        );
    },
    qr{key is only valid for HTTP/1\.1}i,
    'HTTP/2 client rejects Sec-WebSocket-Key option',
);

my ($client11, $request11) =
    Unblock::WebSocket::Handshake->client_request(
        'wss://example.test/chat',
        http_version => '1.1',
        key => 'dGhlIHNhbXBsZSBub25jZQ==',
        subprotocols => [ 'chat' ],
    );

my $bad_method = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/chat',
    scheme    => 'https',
    authority => 'example.test',
    version   => '1.1',
    headers   => [
        [ Host => 'example.test' ],
        [ Upgrade => 'websocket' ],
        [ Connection => 'Upgrade' ],
        [ 'Sec-WebSocket-Key' => 'dGhlIHNhbXBsZSBub25jZQ==' ],
        [ 'Sec-WebSocket-Version' => '13' ],
    ],
);
dies_like(
    sub { Unblock::WebSocket::Handshake->server_accept($bad_method) },
    qr/method must be GET/i,
    'server rejects non-GET HTTP/1.1 handshake',
);

my $missing_upgrade = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/chat',
    scheme    => 'https',
    authority => 'example.test',
    version   => '1.1',
    headers   => [
        [ Host => 'example.test' ],
        [ Connection => 'Upgrade' ],
        [ 'Sec-WebSocket-Key' => 'dGhlIHNhbXBsZSBub25jZQ==' ],
        [ 'Sec-WebSocket-Version' => '13' ],
    ],
);
dies_like(
    sub { Unblock::WebSocket::Handshake->server_accept($missing_upgrade) },
    qr/Upgrade header must contain websocket/i,
    'server requires HTTP/1.1 Upgrade header',
);

my $wrong_version = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/chat',
    scheme    => 'https',
    authority => 'example.test',
    version   => '1.1',
    headers   => [
        [ Host => 'example.test' ],
        [ Upgrade => 'websocket' ],
        [ Connection => 'Upgrade' ],
        [ 'Sec-WebSocket-Key' => 'dGhlIHNhbXBsZSBub25jZQ==' ],
        [ 'Sec-WebSocket-Version' => '12' ],
    ],
);
dies_like(
    sub { Unblock::WebSocket::Handshake->server_accept($wrong_version) },
    qr/Version must be 13/i,
    'server rejects unsupported WebSocket version',
);

my $bad_key = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/chat',
    scheme    => 'https',
    authority => 'example.test',
    version   => '1.1',
    headers   => [
        [ Host => 'example.test' ],
        [ Upgrade => 'websocket' ],
        [ Connection => 'Upgrade' ],
        [ 'Sec-WebSocket-Key' => 'not-a-websocket-key' ],
        [ 'Sec-WebSocket-Version' => '13' ],
    ],
);
dies_like(
    sub { Unblock::WebSocket::Handshake->server_accept($bad_key) },
    qr/invalid Sec-WebSocket-Key/i,
    'server rejects invalid HTTP/1.1 key',
);

my $h2_key = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    protocol  => 'websocket',
    target    => '/chat',
    scheme    => 'https',
    authority => 'example.test',
    version   => '2',
    headers   => [
        [ 'Sec-WebSocket-Version' => '13' ],
        [ 'Sec-WebSocket-Key' => 'dGhlIHNhbXBsZSBub25jZQ==' ],
    ],
);
dies_like(
    sub { Unblock::WebSocket::Handshake->server_accept($h2_key) },
    qr/must not contain Sec-WebSocket-Key/i,
    'HTTP/2 server rejects HTTP/1.1 key header',
);

my $h3_wrong_protocol = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    protocol  => 'not-websocket',
    target    => '/chat',
    scheme    => 'https',
    authority => 'example.test',
    version   => '3',
    headers   => [
        [ 'Sec-WebSocket-Version' => '13' ],
    ],
);
dies_like(
    sub { Unblock::WebSocket::Handshake->server_accept($h3_wrong_protocol) },
    qr/:protocol must be websocket/i,
    'HTTP/3 server rejects wrong extended CONNECT protocol',
);

my $bad_101 = Uniform::HTTP::Response->new(
    status  => 200,
    version => '1.1',
    headers => [],
);
dies_like(
    sub { $client11->validate_client_response($bad_101) },
    qr/status must be 101/i,
    'HTTP/1.1 client requires 101',
);

my $bad_accept = Uniform::HTTP::Response->new(
    status  => 101,
    version => '1.1',
    headers => [
        [ Upgrade => 'websocket' ],
        [ Connection => 'Upgrade' ],
        [ 'Sec-WebSocket-Accept' => 'wrong' ],
    ],
);
dies_like(
    sub { $client11->validate_client_response($bad_accept) },
    qr/invalid Sec-WebSocket-Accept/i,
    'HTTP/1.1 client validates accept hash',
);

my ($client2) = Unblock::WebSocket::Handshake->client_request(
    'wss://example.test/chat',
    http_version => '2',
    subprotocols => [ 'chat' ],
);

my $h2_101 = Uniform::HTTP::Response->new(
    status  => 101,
    version => '2',
    headers => [],
);
dies_like(
    sub { $client2->validate_client_response($h2_101) },
    qr/status must be 200/i,
    'HTTP/2 client requires 200',
);

my $h2_accept = Uniform::HTTP::Response->new(
    status  => 200,
    version => '2',
    headers => [
        [ 'Sec-WebSocket-Accept' => 'unexpected' ],
    ],
);
dies_like(
    sub { $client2->validate_client_response($h2_accept) },
    qr/must not contain Sec-WebSocket-Accept/i,
    'HTTP/2 client rejects HTTP/1.1 accept header',
);

my $extension = Uniform::HTTP::Response->new(
    status  => 200,
    version => '2',
    headers => [
        [ 'Sec-WebSocket-Extensions' => 'permessage-deflate' ],
    ],
);
dies_like(
    sub { $client2->validate_client_response($extension) },
    qr/unsupported extension/i,
    'client rejects unimplemented extensions',
);

my $unknown_protocol = Uniform::HTTP::Response->new(
    status  => 200,
    version => '2',
    headers => [
        [ 'Sec-WebSocket-Protocol' => 'other' ],
    ],
);
dies_like(
    sub { $client2->validate_client_response($unknown_protocol) },
    qr/unknown subprotocol/i,
    'client rejects unoffered subprotocol',
);

done_testing;
