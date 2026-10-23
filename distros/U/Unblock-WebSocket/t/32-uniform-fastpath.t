use strict;
use warnings;
use Test::More;

use Uniform::HTTP::FastPath 0.05;
use Uniform::HTTP::Request 0.05;
use Uniform::HTTP::Response 0.05;
use Unblock::WebSocket::Handshake;

{
    package Local::UniformRequest;
    use parent 'Uniform::HTTP::Request';
}

{
    package Local::UniformResponse;
    use parent 'Uniform::HTTP::Response';
}

my ($client, $request) =
    Unblock::WebSocket::Handshake->client_request(
        'wss://example.test/chat',
        http_version => '1.1',
        key          => 'dGhlIHNhbXBsZSBub25jZQ==',
        subprotocols => [ 'chat' ],
    );

ok(
    Uniform::HTTP::FastPath::can_view($request),
    'canonical client request supports Uniform FastPath',
);

my $request_view = Uniform::HTTP::FastPath::view($request);
is(
    $request_view->[Uniform::HTTP::FastPath::SLOT_METHOD()],
    'GET',
    'FastPath request view exposes WebSocket method',
);
is(
    $request_view->[Uniform::HTTP::FastPath::SLOT_TARGET()],
    '/chat',
    'FastPath request view exposes exact WebSocket target',
);

my $server = Unblock::WebSocket::Handshake->server_accept(
    $request,
    subprotocols => [ 'chat' ],
);
my $response = $server->server_response;

ok(
    Uniform::HTTP::FastPath::can_view($response),
    'canonical server response supports Uniform FastPath',
);

$client->validate_client_response($response);
is($client->subprotocol, 'chat',
    'canonical FastPath-compatible handshake validates normally');

my $sub_request = Local::UniformRequest->new(
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
        [ 'Sec-WebSocket-Version' => '13' ],
        [ 'Sec-WebSocket-Protocol' => 'chat' ],
    ],
);

ok(
    !Uniform::HTTP::FastPath::can_view($sub_request),
    'Uniform request subclass is intentionally not FastPath-viewable',
);

my $sub_server = Unblock::WebSocket::Handshake->server_accept(
    $sub_request,
    subprotocols => [ 'chat' ],
);
is(
    $sub_server->subprotocol,
    'chat',
    'request subclass falls back to portable Uniform accessors',
);

my ($sub_client) =
    Unblock::WebSocket::Handshake->client_request(
        'wss://example.test/chat',
        http_version => '1.1',
        key          => 'dGhlIHNhbXBsZSBub25jZQ==',
        subprotocols => [ 'chat' ],
    );

my $sub_response = Local::UniformResponse->new(
    status  => 101,
    version => '1.1',
    reason  => 'Switching Protocols',
    headers => [
        [ Upgrade => 'websocket' ],
        [ Connection => 'Upgrade' ],
        [ 'Sec-WebSocket-Accept' =>
            Unblock::WebSocket::Handshake->accept_key(
                'dGhlIHNhbXBsZSBub25jZQ==',
            ),
        ],
        [ 'Sec-WebSocket-Protocol' => 'chat' ],
    ],
);

ok(
    !Uniform::HTTP::FastPath::can_view($sub_response),
    'Uniform response subclass is intentionally not FastPath-viewable',
);

$sub_client->validate_client_response($sub_response);
is(
    $sub_client->subprotocol,
    'chat',
    'response subclass falls back to portable Uniform accessors',
);

done_testing;
