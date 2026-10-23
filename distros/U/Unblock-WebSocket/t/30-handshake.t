use strict;
use warnings;
use Test::More;
use MIME::Base64 ();

use Uniform::HTTP::Response;
use Unblock::WebSocket::Handshake;

for my $version ('1.1', '2', '3') {
    my ($client_hs, $request) = Unblock::WebSocket::Handshake->client_request(
        'wss://example.test/chat?room=1',
        http_version => $version,
        subprotocols => [ 'chat', 'superchat' ],
        ($version eq '1.1'
            ? (key => 'dGhlIHNhbXBsZSBub25jZQ==') : ()),
    );

    my $server_hs = Unblock::WebSocket::Handshake->server_accept(
        $request,
        subprotocols => [ 'superchat', 'chat' ],
    );
    my $response = $server_hs->server_response;
    $client_hs->validate_client_response($response);

    is $client_hs->subprotocol, 'chat', "$version negotiated first client-offered supported subprotocol";
    if ($version eq '1.1') {
        is $request->method, 'GET', 'HTTP/1.1 uses GET';
        is $response->status, 101, 'HTTP/1.1 uses 101';
    }
    else {
        is $request->method, 'CONNECT', "$version uses CONNECT";
        is $request->protocol, 'websocket', "$version uses extended CONNECT protocol";
        is $response->status, 200, "$version uses 200";
    }
}

my ($generated_hs, $generated_request) =
    Unblock::WebSocket::Handshake->client_request(
        'ws://example.test/generated-key',
        http_version => '1.1',
    );

my @generated_key;
for my $index (0 .. $generated_request->header_count - 1) {
    push @generated_key, $generated_request->header_value($index)
        if lc($generated_request->header_name($index))
            eq 'sec-websocket-key';
}

is scalar(@generated_key), 1, 'generated handshake contains one client key';
like $generated_key[0], qr/\A[A-Za-z0-9+\/]{22}==\z/,
    'generated client key is valid base64 shape';
is length(MIME::Base64::decode_base64($generated_key[0])), 16,
    'generated client key decodes to 16 random bytes';

done_testing;
