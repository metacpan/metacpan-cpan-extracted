use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request 0.05;
use Uniform::HTTP::Response 0.05;
use Unblock::WebSocket::Handshake;

sub header_values {
    my ($message, $wanted) = @_;
    my @value;
    for my $index (0 .. $message->header_count - 1) {
        push @value, $message->header_value($index)
            if lc($message->header_name($index)) eq lc($wanted);
    }
    return @value;
}

sub base_request {
    my ($extension) = @_;
    my @headers = (
        [ Host => 'example.test' ],
        [ Upgrade => 'websocket' ],
        [ Connection => 'Upgrade' ],
        [ 'Sec-WebSocket-Key' => 'dGhlIHNhbXBsZSBub25jZQ==' ],
        [ 'Sec-WebSocket-Version' => '13' ],
    );
    push @headers, [ 'Sec-WebSocket-Extensions' => $extension ]
        if defined $extension;

    return Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/chat',
        scheme    => 'https',
        authority => 'example.test',
        version   => '1.1',
        headers   => \@headers,
    );
}

sub response_for {
    my ($client, $extension) = @_;
    my @headers = (
        [ Upgrade => 'websocket' ],
        [ Connection => 'Upgrade' ],
        [ 'Sec-WebSocket-Accept' =>
            Unblock::WebSocket::Handshake->accept_key(
                'dGhlIHNhbXBsZSBub25jZQ==',
            ),
        ],
    );
    push @headers, [ 'Sec-WebSocket-Extensions' => $extension ]
        if defined $extension;

    return Uniform::HTTP::Response->new(
        status  => 101,
        version => '1.1',
        reason  => 'Switching Protocols',
        headers => \@headers,
    );
}

for my $version ('1.1', '2', '3') {
    my ($client, $request) =
        Unblock::WebSocket::Handshake->client_request(
            'wss://example.test/chat',
            http_version       => $version,
            permessage_deflate => 1,
            ($version eq '1.1'
                ? (key => 'dGhlIHNhbXBsZSBub25jZQ==') : ()),
        );

    is_deeply(
        [ header_values($request, 'Sec-WebSocket-Extensions') ],
        [ 'permessage-deflate' ],
        "$version client offers simple permessage-deflate",
    );

    my $server = Unblock::WebSocket::Handshake->server_accept(
        $request,
        permessage_deflate => 1,
    );
    is_deeply($server->permessage_deflate, {},
        "$version server accepts simple permessage-deflate");

    my $response = $server->server_response;
    is_deeply(
        [ header_values($response, 'Sec-WebSocket-Extensions') ],
        [ 'permessage-deflate' ],
        "$version server emits negotiated extension",
    );

    $client->validate_client_response($response);
    is_deeply($client->permessage_deflate, {},
        "$version client validates negotiated extension");
    is_deeply(
        $client->connection_options,
        { permessage_deflate => {} },
        "$version handshake exports connection options",
    );
}

{
    my ($client, $request) =
        Unblock::WebSocket::Handshake->client_request(
            'wss://example.test/chat',
            http_version => '1.1',
            key          => 'dGhlIHNhbXBsZSBub25jZQ==',
            permessage_deflate => {
                server_no_context_takeover => 1,
                client_no_context_takeover => 1,
                server_max_window_bits     => 12,
            },
        );

    is_deeply(
        [ header_values($request, 'Sec-WebSocket-Extensions') ],
        [
            'permessage-deflate; server_no_context_takeover; '
            . 'client_no_context_takeover; server_max_window_bits=12'
        ],
        'client serializes directional compression offer',
    );

    my $server = Unblock::WebSocket::Handshake->server_accept(
        $request,
        permessage_deflate => {
            server_max_window_bits     => 10,
            client_no_context_takeover => 1,
        },
    );

    my $expected = {
        server_no_context_takeover => 1,
        client_no_context_takeover => 1,
        server_max_window_bits     => 10,
    };
    is_deeply($server->permessage_deflate, $expected,
        'server honors required and policy compression parameters');

    my $response = $server->server_response;
    $client->validate_client_response($response);
    is_deeply($client->permessage_deflate, $expected,
        'client accepts compatible directional response');
}

{
    my $request = base_request(
        'permessage-deflate; server_max_window_bits=8, permessage-deflate'
    );
    my $server = Unblock::WebSocket::Handshake->server_accept(
        $request,
        permessage_deflate => 1,
    );
    is_deeply(
        $server->permessage_deflate,
        { server_max_window_bits => 8 },
        'server accepts preferred 8-bit compressor offer',
    );
}

{
    my $request = base_request(
        'permessage-deflate; client_max_window_bits'
    );
    my $server = Unblock::WebSocket::Handshake->server_accept(
        $request,
        permessage_deflate => {
            client_max_window_bits => 10,
        },
    );
    is_deeply(
        $server->permessage_deflate,
        { client_max_window_bits => 10 },
        'server may constrain client window when client offered the parameter',
    );
    is_deeply(
        [ header_values($server->server_response, 'Sec-WebSocket-Extensions') ],
        [ 'permessage-deflate; client_max_window_bits=10' ],
        'server serializes selected client window',
    );
}

{
    my $request = base_request(
        'permessage-deflate; server_no_context_takeover; '
        . 'server_no_context_takeover, permessage-deflate'
    );
    my $server = Unblock::WebSocket::Handshake->server_accept(
        $request,
        permessage_deflate => 1,
    );
    is_deeply($server->permessage_deflate, {},
        'server declines malformed duplicate-parameter offer and uses fallback');
}

{
    my ($client) = Unblock::WebSocket::Handshake->client_request(
        'wss://example.test/chat',
        http_version => '1.1',
        key          => 'dGhlIHNhbXBsZSBub25jZQ==',
    );
    my $ok = eval {
        $client->validate_client_response(
            response_for($client, 'permessage-deflate')
        );
        1;
    };
    ok(!$ok, 'client rejects unsolicited permessage-deflate');
    like($@, qr/unsupported extension/i,
        'unsolicited compression reports unsupported extension');
}

{
    my ($client) = Unblock::WebSocket::Handshake->client_request(
        'wss://example.test/chat',
        http_version => '1.1',
        key          => 'dGhlIHNhbXBsZSBub25jZQ==',
        permessage_deflate => {
            server_no_context_takeover => 1,
        },
    );
    my $ok = eval {
        $client->validate_client_response(
            response_for($client, 'permessage-deflate')
        );
        1;
    };
    ok(!$ok, 'client rejects response that drops required no-context request');
    like($@, qr/omitted required server_no_context_takeover/i,
        'missing required no-context parameter is explicit');
}

{
    my ($client) = Unblock::WebSocket::Handshake->client_request(
        'wss://example.test/chat',
        http_version => '1.1',
        key          => 'dGhlIHNhbXBsZSBub25jZQ==',
        permessage_deflate => {
            server_max_window_bits => 12,
        },
    );
    my $ok = eval {
        $client->validate_client_response(
            response_for(
                $client,
                'permessage-deflate; server_max_window_bits=13',
            )
        );
        1;
    };
    ok(!$ok, 'client rejects server window larger than offered maximum');
    like($@, qr/increased server_max_window_bits/i,
        'oversized server window is explicit');
}

{
    my ($client, $request) =
        Unblock::WebSocket::Handshake->client_request(
            'wss://example.test/chat',
            http_version => '1.1',
            key          => 'dGhlIHNhbXBsZSBub25jZQ==',
            permessage_deflate => {
                client_max_window_bits => 8,
            },
        );

    is_deeply(
        [ header_values($request, 'Sec-WebSocket-Extensions') ],
        [ 'permessage-deflate; client_max_window_bits=8' ],
        'client can advertise an 8-bit compressor window',
    );

    my $server = Unblock::WebSocket::Handshake->server_accept(
        $request,
        permessage_deflate => {
            client_max_window_bits => 8,
        },
    );
    my $response = $server->server_response;
    $client->validate_client_response($response);

    is_deeply(
        $client->permessage_deflate,
        { client_max_window_bits => 8 },
        'client accepts negotiated 8-bit outgoing compressor window',
    );
}

{
    my ($client, $request) =
        Unblock::WebSocket::Handshake->client_request(
            'wss://example.test/chat',
            http_version => '1.1',
            key          => 'dGhlIHNhbXBsZSBub25jZQ==',
            permessage_deflate => {
                client_max_window_bits => undef,
            },
        );

    is_deeply(
        [ header_values($request, 'Sec-WebSocket-Extensions') ],
        [ 'permessage-deflate; client_max_window_bits' ],
        'client can advertise valueless client_max_window_bits',
    );

    my $response = response_for(
        $client,
        'permessage-deflate; client_max_window_bits=12',
    );
    $client->validate_client_response($response);
    is_deeply(
        $client->permessage_deflate,
        { client_max_window_bits => 12 },
        'server selects client compressor window from valueless offer',
    );
}

{
    my ($client) =
        Unblock::WebSocket::Handshake->client_request(
            'wss://example.test/chat',
            http_version => '1.1',
            key          => 'dGhlIHNhbXBsZSBub25jZQ==',
            permessage_deflate => {
                client_max_window_bits => 8,
            },
        );

    my $response = response_for(
        $client,
        'permessage-deflate; client_max_window_bits=12',
    );
    my $ok = eval { $client->validate_client_response($response); 1 };
    ok($ok,
        'client accepts client_max_window_bits response above offer hint');
    is_deeply(
        $client->permessage_deflate,
        { client_max_window_bits => 12 },
        'agreed response window overrides smaller client hint',
    );
}

{
    my $request = base_request(
        'permessage-deflate; server_max_window_bits="10"; '
        . 'client_max_window_bits="12"'
    );
    my $server = Unblock::WebSocket::Handshake->server_accept(
        $request,
        permessage_deflate => {
            client_max_window_bits => 11,
        },
    );
    is_deeply(
        $server->permessage_deflate,
        {
            server_max_window_bits => 10,
            client_max_window_bits => 11,
        },
        'quoted server_max_window_bits is accepted after numeric validation',
    );
}

for my $bad (
    'permessage-deflate; server_max_window_bits="08"',
    'permessage-deflate; server_max_window_bits="16"',
    'permessage-deflate; server_max_window_bits="ten"',
) {
    my $request = base_request($bad);
    my $server = Unblock::WebSocket::Handshake->server_accept(
        $request,
        permessage_deflate => 1,
    );
    ok(!defined($server->permessage_deflate),
        "invalid quoted window value is declined: $bad");
}


{
    my ($client) = Unblock::WebSocket::Handshake->client_request(
        'wss://example.test/chat',
        http_version       => '1.1',
        key                => 'dGhlIHNhbXBsZSBub25jZQ==',
        permessage_deflate => 1,
    );

    my $response = response_for(
        $client,
        'permessage-deflate; server_max_window_bits=10; '
        . 'server_no_context_takeover; client_no_context_takeover',
    );

    my $ok = eval { $client->validate_client_response($response); 1 };
    ok($ok,
        'client accepts legal unsolicited server-side compression parameters');
    is_deeply(
        $client->permessage_deflate,
        {
            server_max_window_bits     => 10,
            server_no_context_takeover => 1,
            client_no_context_takeover => 1,
        },
        'legal unsolicited response parameters become agreed state',
    );
}

{
    my ($client) = Unblock::WebSocket::Handshake->client_request(
        'wss://example.test/chat',
        http_version       => '1.1',
        key                => 'dGhlIHNhbXBsZSBub25jZQ==',
        permessage_deflate => 1,
    );

    my $ok = eval {
        $client->validate_client_response(
            response_for(
                $client,
                'permessage-deflate; client_max_window_bits=10',
            )
        );
        1;
    };
    ok(!$ok,
        'client rejects client_max_window_bits when it was not offered');
    like($@, qr/client_max_window_bits.*not offered/i,
        'unsolicited client window rejection is explicit');
}


{
    my ($client) = Unblock::WebSocket::Handshake->client_request(
        'wss://example.test/chat',
        http_version => '1.1',
        key          => 'dGhlIHNhbXBsZSBub25jZQ==',
        permessage_deflate => {
            client_no_context_takeover => 1,
        },
    );

    $client->validate_client_response(
        response_for($client, 'permessage-deflate')
    );

    is_deeply(
        $client->permessage_deflate,
        {},
        'ignored client_no_context_takeover hint is not treated as agreed',
    );
}

done_testing;
