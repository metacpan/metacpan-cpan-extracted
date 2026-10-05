use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;

sub request_for {
    my ($method) = @_;
    return Uniform::HTTP::Request->new(
        method  => $method,
        target  => '/',
        headers => [ [ Host => 'example.test' ] ],
    );
}

sub client_case {
    my (%args) = @_;
    my $response_hits = 0;
    my $body_hits = 0;
    my $complete_hits = 0;
    my $error;
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        request_for($args{method} || 'GET'),
        on_response => sub { $response_hits++ },
        on_body => sub { $body_hits++ },
        on_complete => sub { $complete_hits++ },
        on_error => sub { $error = $_[1] },
    );
    $client->output;
    $client->input($args{wire});
    return {
        client        => $client,
        tx            => $tx,
        response_hits => $response_hits,
        body_hits     => $body_hits,
        complete_hits => $complete_hits,
        error         => $error,
    };
}

subtest 'HEAD ignores framing metadata and never consumes body bytes' => sub {
    my $state = client_case(
        method => 'HEAD',
        wire   =>
            "HTTP/1.1 200 OK\r\n" .
            "Content-Length: 123\r\n" .
            "Transfer-Encoding: gzip\r\n" .
            "\r\n",
    );
    is($state->{response_hits}, 1, 'HEAD response is delivered');
    is($state->{body_hits}, 0, 'HEAD response has no body callbacks');
    is($state->{complete_hits}, 1, 'HEAD response completes at head boundary');
    ok(!$state->{error}, 'HEAD framing metadata is not treated as body framing');
    ok($state->{tx}->is_complete, 'HEAD Transaction completes');
};

subtest '304 ignores framing metadata and has no body' => sub {
    my $state = client_case(
        wire =>
            "HTTP/1.1 304 Not Modified\r\n" .
            "Content-Length: 999\r\n" .
            "Transfer-Encoding: gzip\r\n" .
            "\r\n",
    );
    is($state->{response_hits}, 1, '304 response is delivered');
    is($state->{body_hits}, 0, '304 response has no body callbacks');
    is($state->{complete_hits}, 1, '304 completes at head boundary');
    ok(!$state->{error}, '304 framing metadata is not interpreted as wire framing');
};

subtest '204 rejects Content-Length before application delivery' => sub {
    my $state = client_case(
        wire =>
            "HTTP/1.1 204 No Content\r\n" .
            "Content-Length: 0\r\n\r\n",
    );
    is($state->{response_hits}, 0, 'invalid 204 is rejected before on_response');
    like($state->{error}, qr/204.*Content-Length|Content-Length.*204/,
        '204 framing error is explicit');
    is($state->{tx}->state, 'error', 'invalid 204 makes Transaction terminal');
    ok($state->{client}->is_closed, 'invalid 204 closes connection');
};

subtest '205 accepts only zero Content-Length' => sub {
    my $good = client_case(
        wire =>
            "HTTP/1.1 205 Reset Content\r\n" .
            "Content-Length: 0\r\n\r\n",
    );
    is($good->{response_hits}, 1, '205 with zero length is delivered');
    is($good->{body_hits}, 0, '205 never has body callbacks');
    is($good->{complete_hits}, 1, '205 with zero length completes');

    my $bad = client_case(
        wire =>
            "HTTP/1.1 205 Reset Content\r\n" .
            "Content-Length: 4\r\n\r\ntest",
    );
    is($bad->{response_hits}, 0, '205 with nonzero length rejected before response callback');
    like($bad->{error}, qr/205.*zero|Content-Length.*zero/,
        '205 nonzero length error is explicit');
};

subtest '205 can use zero-length chunked framing but cannot carry content' => sub {
    my $zero = client_case(
        wire =>
            "HTTP/1.1 205 Reset Content\r\n" .
            "Transfer-Encoding: chunked\r\n\r\n" .
            "0\r\n\r\n",
    );
    is($zero->{response_hits}, 1, 'chunk-framed 205 response is delivered');
    is($zero->{body_hits}, 0, 'zero-chunk 205 has no content callback');
    is($zero->{complete_hits}, 1, 'zero-chunk 205 completes normally');
    ok(!$zero->{error}, 'zero-chunk 205 is valid framing');

    my $body = client_case(
        wire =>
            "HTTP/1.1 205 Reset Content\r\n" .
            "Transfer-Encoding: chunked\r\n\r\n" .
            "1\r\nx\r\n0\r\n\r\n",
    );
    like($body->{error}, qr/205 response must not contain content/,
        'decoded 205 content is rejected');
    is($body->{tx}->state, 'error', 'content-bearing 205 is terminal');
};

subtest 'invalid informational framing is rejected before callback' => sub {
    my $informational = 0;
    my $error;
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        request_for('POST'),
        on_informational => sub { $informational++ },
        on_error => sub { $error = $_[1] },
    );
    $client->output;
    $client->input(
        "HTTP/1.1 100 Continue\r\nContent-Length: 0\r\n\r\n"
    );
    is($informational, 0, 'invalid informational response is not dispatched');
    like($error, qr/1xx.*Content-Length|Content-Length.*1xx/,
        'informational framing violation is explicit');
    is($tx->state, 'error', 'invalid informational response makes Transaction error');
};

subtest 'server HEAD body is metadata only' => sub {
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx) = @_;
            $tx->respond(Uniform::HTTP::Response->new(
                status => 200,
                body   => 'hello',
            ));
        },
    );
    $server->input(
        "HEAD / HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Connection: close, TE\r\n" .
        "TE: gzip\r\n\r\n"
    );
    is(
        $server->output,
        "HTTP/1.1 200 OK\r\nContent-Length: 5\r\nConnection: close\r\n\r\n",
        'HEAD serializes representation length without body bytes',
    );
};

subtest 'server HEAD permits transfer-coding metadata' => sub {
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx) = @_;
            $tx->respond(Uniform::HTTP::Response->new(
                status  => 200,
                headers => [ [ 'Transfer-Encoding', 'gzip' ] ],
            ));
        },
    );
    $server->input(
        "HEAD / HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Connection: close, TE\r\n" .
        "TE: gzip\r\n\r\n"
    );
    like(
        $server->output,
        qr/\AHTTP\/1\.1 200 OK\r\nTransfer-Encoding: gzip\r\nConnection: close\r\n\r\n\z/,
        'HEAD preserves Transfer-Encoding as representation metadata',
    );
};

subtest 'server 304 permits transfer-coding metadata' => sub {
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx) = @_;
            $tx->respond(Uniform::HTTP::Response->new(
                status  => 304,
                headers => [ [ 'Transfer-Encoding', 'gzip' ] ],
            ));
        },
    );
    $server->input(
        "GET / HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Connection: close, TE\r\n" .
        "TE: gzip\r\n\r\n"
    );
    is(
        $server->output,
        "HTTP/1.1 304 Not Modified\r\nTransfer-Encoding: gzip\r\nConnection: close\r\n\r\n",
        '304 preserves Transfer-Encoding metadata without content',
    );
};

subtest 'server rejects illegal 204 framing' => sub {
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx) = @_;
            $tx->respond(Uniform::HTTP::Response->new(
                status  => 204,
                headers => [ [ 'Content-Length', '0' ] ],
            ));
        },
    );
    $server->input(
        "GET / HTTP/1.1\r\nHost: example.test\r\n\r\n"
    );
    like($server->output, qr/\AHTTP\/1\.1 500 /,
        'illegal 204 response fails before wire commitment');
};

done_testing;
