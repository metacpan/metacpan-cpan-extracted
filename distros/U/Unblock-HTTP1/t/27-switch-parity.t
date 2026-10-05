use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;

sub connect_request {
    return Uniform::HTTP::Request->new(
        method  => 'CONNECT',
        target  => 'example.test:443',
        headers => [ [ Host => 'example.test:443' ] ],
    );
}

sub upgrade_request {
    return Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => '/switch',
        headers => [
            [ Host       => 'example.test' ],
            [ Connection => 'keep-alive, Upgrade' ],
            [ Upgrade    => 'test-proto' ],
        ],
    );
}

subtest 'client successful CONNECT switches at the head boundary' => sub {
    my @event;
    my $error;
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        connect_request(),
        on_response => sub {
            my ($tx, $response) = @_;
            push @event, 'response';
            is($response->status, 200, 'successful CONNECT response is attached');
            is($response->header('X-Proxy'), 'ok', 'ordinary response fields remain visible');
            ok(!$response->is_complete, 'CONNECT response is incomplete during head callback');
        },
        on_switch => sub {
            my ($tx, $response) = @_;
            push @event, 'switch';
            ok($tx->is_complete, 'CONNECT Transaction is complete at switch callback');
            ok($response->is_complete, 'CONNECT Response is complete at switch callback');
        },
        on_error => sub { $error = $_[1] },
    );

    like(
        $client->output,
        qr/\ACONNECT example\.test:443 HTTP\/1\.1\r\nHost: example\.test:443\r\n/s,
        'CONNECT request uses authority-form target and matching Host',
    );

    $client->input(
        "HTTP/1.1 200 Connection Established\r\n" .
        "Content-Length: 999\r\n" .
        "Transfer-Encoding: chunked\r\n" .
        "X-Proxy: ok\r\n" .
        "\r\n" .
        "TUNNEL-DATA"
    );

    ok(!$error, 'successful CONNECT does not report an HTTP framing error');
    ok($client->is_switched, 'client leaves HTTP mode after successful CONNECT');
    is($client->take_remainder, 'TUNNEL-DATA',
        'Content-Length and Transfer-Encoding are ignored at CONNECT handoff');
    is_deeply(\@event, [qw(response switch)], 'CONNECT callback order is stable');
    ok($tx->is_complete, 'returned CONNECT Transaction remains complete');
};

subtest 'client rejects malformed CONNECT requests before wire output' => sub {
    my @case = (
        [
            'bad target',
            Uniform::HTTP::Request->new(
                method => 'CONNECT',
                target => '/bad',
                headers => [ [ Host => 'example.test:443' ] ],
            ),
            qr/authority-form host:port/,
        ],
        [
            'Host mismatch',
            Uniform::HTTP::Request->new(
                method => 'CONNECT',
                target => 'example.test:443',
                headers => [ [ Host => 'other.test:443' ] ],
            ),
            qr/Host must (?:match|identify)/,
        ],
        [
            'body',
            Uniform::HTTP::Request->new(
                method => 'CONNECT',
                target => 'example.test:443',
                headers => [ [ Host => 'example.test:443' ] ],
                body => '',
            ),
            qr/must not contain a buffered body/,
        ],
        [
            'nonzero Content-Length',
            Uniform::HTTP::Request->new(
                method => 'CONNECT',
                target => 'example.test:443',
                headers => [
                    [ Host => 'example.test:443' ],
                    [ 'Content-Length' => '1' ],
                ],
            ),
            qr/Content-Length must be zero/,
        ],
    );

    for my $case (@case) {
        my ($name, $request, $pattern) = @$case;
        my $error;
        my $client = Unblock::HTTP1::Client->new;
        my $tx = $client->request(
            $request,
            on_error => sub { $error = $_[1] },
        );
        is($tx->state, 'error', "$name CONNECT enters error state");
        like($error, $pattern, "$name CONNECT error is explicit");
        is($client->output, '', "$name CONNECT produces no wire bytes");
    }
};

subtest 'client permits zero Content-Length on CONNECT' => sub {
    my $client = Unblock::HTTP1::Client->new;
    my $request = Uniform::HTTP::Request->new(
        method  => 'CONNECT',
        target  => 'example.test:443',
        headers => [
            [ Host => 'example.test:443' ],
            [ 'Content-Length' => '0' ],
        ],
    );

    my $tx = $client->request($request);
    like(
        $client->output,
        qr/\ACONNECT example\.test:443 HTTP\/1\.1\r\n.*Content-Length: 0\r\n/s,
        'zero Content-Length CONNECT serializes without a body',
    );
    ok(!$tx->is_terminal, 'CONNECT transaction remains active awaiting response');
};

subtest 'server successful CONNECT preserves post-head tunnel bytes' => sub {
    my @event;
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx, $request) = @_;
            push @event, 'request';
            $tx->respond(Uniform::HTTP::Response->new(
                status  => 200,
                headers => [ [ 'X-Proxy', 'ok' ] ],
            ));
        },
        on_request_end => sub { push @event, 'request_end' },
        on_switch => sub {
            my ($tx, $response) = @_;
            push @event, 'switch';
            ok($tx->is_complete, 'server CONNECT Transaction completes before switch callback');
        },
    );

    $server->input(
        "CONNECT example.test:443 HTTP/1.1\r\n" .
        "Host: example.test:443\r\n\r\n" .
        "PING"
    );

    ok($server->is_switched, 'server leaves HTTP mode after successful CONNECT');
    is($server->take_remainder, 'PING', 'same-read tunnel bytes are preserved');
    is_deeply(\@event, [qw(request request_end switch)],
        'request lifecycle completes before CONNECT switch');
    is(
        $server->output,
        "HTTP/1.1 200 OK\r\nX-Proxy: ok\r\n\r\n",
        'successful CONNECT response has no HTTP body framing',
    );
};

subtest 'invalid successful CONNECT response fails before handoff' => sub {
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx) = @_;
            $tx->respond(Uniform::HTTP::Response->new(
                status => 200,
                headers => [ [ 'Content-Length', '0' ] ],
            ));
        },
    );
    $server->input(
        "CONNECT example.test:443 HTTP/1.1\r\n" .
        "Host: example.test:443\r\n\r\n"
    );
    ok(!$server->is_switched, 'invalid CONNECT response does not switch protocols');
    like($server->output, qr/\AHTTP\/1\.1 500 /,
        'invalid CONNECT response becomes a server error');
};

subtest 'server Upgrade validates offer and preserves remainder' => sub {
    my @event;
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx) = @_;
            push @event, 'request';
            $tx->respond(Uniform::HTTP::Response->new(
                status => 101,
                headers => [ [ Upgrade => 'test-proto' ] ],
            ));
        },
        on_request_end => sub { push @event, 'request_end' },
        on_switch => sub { push @event, 'switch' },
    );

    $server->input(
        "GET /switch HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Connection: keep-alive, Upgrade\r\n" .
        "Upgrade: test-proto\r\n\r\n" .
        "PING"
    );

    ok($server->is_switched, 'valid Upgrade switches server out of HTTP mode');
    is($server->take_remainder, 'PING', 'same-read Upgrade bytes are preserved');
    is_deeply(\@event, [qw(request request_end switch)],
        'Upgrade completes request lifecycle before switch');
    is(
        $server->output,
        "HTTP/1.1 101 Switching Protocols\r\n" .
        "Upgrade: test-proto\r\n" .
        "Connection: Upgrade\r\n\r\n",
        'server adds Connection: Upgrade when response omitted it',
    );
};

subtest 'server rejects unoffered Upgrade selection' => sub {
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx) = @_;
            $tx->respond(Uniform::HTTP::Response->new(
                status => 101,
                headers => [ [ Upgrade => 'other-proto' ] ],
            ));
        },
    );
    $server->input(
        "GET /switch HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Connection: Upgrade\r\n" .
        "Upgrade: test-proto\r\n\r\n"
    );
    ok(!$server->is_switched, 'unoffered Upgrade protocol does not switch');
    like($server->output, qr/\AHTTP\/1\.1 500 /,
        'unoffered Upgrade selection fails before 101');
};

subtest 'server rejects body-bearing Upgrade request' => sub {
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx) = @_;
            $tx->respond(Uniform::HTTP::Response->new(
                status => 101,
                headers => [ [ Upgrade => 'test-proto' ] ],
            ));
        },
    );
    $server->input(
        "POST /switch HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Connection: Upgrade\r\n" .
        "Upgrade: test-proto\r\n" .
        "Content-Length: 1\r\n\r\nx"
    );
    ok(!$server->is_switched, 'body-bearing Upgrade request does not switch');
    like($server->output, qr/\AHTTP\/1\.1 500 /,
        'body-bearing Upgrade request fails before 101');
};

subtest 'client validates 101 response before response callback' => sub {
    my $response_hits = 0;
    my $error;
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        upgrade_request(),
        on_response => sub { $response_hits++ },
        on_error => sub { $error = $_[1] },
    );
    $client->output;
    $client->input(
        "HTTP/1.1 101 Switching Protocols\r\n" .
        "Connection: Upgrade\r\n" .
        "Upgrade: other-proto\r\n\r\n"
    );
    is($response_hits, 0, 'invalid 101 is rejected before on_response');
    like($error, qr/not offered by request/, 'invalid Upgrade selection error is explicit');
    is($tx->state, 'error', 'invalid 101 makes Transaction terminal');
    ok($client->is_closed, 'invalid 101 closes HTTP connection');
};

subtest 'client valid Upgrade switches with exact remainder' => sub {
    my @event;
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        upgrade_request(),
        on_response => sub { push @event, 'response' },
        on_switch => sub { push @event, 'switch' },
        on_error => sub { die "unexpected client Upgrade error: $_[1]" },
    );
    $client->output;
    $client->input(
        "HTTP/1.1 101 Switching Protocols\r\n" .
        "Connection: Upgrade\r\n" .
        "Upgrade: test-proto\r\n\r\n" .
        "PONG"
    );
    ok($client->is_switched, 'valid 101 switches client out of HTTP mode');
    is($client->take_remainder, 'PONG', 'client preserves post-101 bytes exactly');
    is_deeply(\@event, [qw(response switch)], 'valid 101 callback order is stable');
    ok($tx->is_complete, 'Upgrade Transaction completes');
};

done_testing;
