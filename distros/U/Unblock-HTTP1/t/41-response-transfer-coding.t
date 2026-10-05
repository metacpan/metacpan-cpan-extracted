use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::_Native;
use Unblock::HTTP1::_Wire;

sub request {
    return Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => '/',
        headers => [ [ Host => 'example.test' ] ],
    );
}

sub request_accepting {
    my ($coding) = @_;
    return Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => '/',
        headers => [
            [ Host => 'example.test' ],
            [ Connection => 'TE' ],
            [ TE => $coding ],
        ],
    );
}

subtest 'response with transfer coding before final chunked is framed by chunked' => sub {
    my $body = '';
    my $error;
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        request(),
        on_body  => sub { $body .= $_[2] },
        on_error => sub { $error = $_[1] },
    );
    $client->output;

    $client->input(
        "HTTP/1.1 200 OK\r\n" .
        "Transfer-Encoding: gzip; level=\"a,b\", chunked\r\n" .
        "\r\n" .
        "3\r\nabc\r\n0\r\n\r\n"
    );

    is($body, 'abc',
        'outer chunked framing is removed while earlier transfer-coded bytes remain opaque');
    ok($tx->is_complete, 'chunk-framed transfer-coded response completes');
    ok(!$error, 'valid transfer-coding chain is accepted');
    ok(!$client->is_closed, 'final chunked coding permits persistent reuse');
};

subtest 'response whose final transfer coding is not chunked is close-delimited' => sub {
    my $body = '';
    my @event;
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        request(),
        on_body     => sub { $body .= $_[2] },
        on_complete => sub { push @event, 'complete' },
        on_error    => sub { die "unexpected response error: $_[1]" },
    );
    $client->output;

    $client->input(
        "HTTP/1.1 200 OK\r\n" .
        "Transfer-Encoding: gzip\r\n" .
        "\r\n" .
        "abc"
    );

    is($body, 'abc', 'non-chunked transfer-coded bytes are delivered opaquely');
    ok(!$tx->is_complete, 'close-delimited response remains incomplete before EOF');

    $client->input_eof;

    ok($tx->is_complete, 'transport EOF completes non-chunked transfer-coded response');
    is_deeply(\@event, [ 'complete' ], 'completion occurs exactly once');
    ok($client->is_closed, 'close-delimited response cannot reuse the connection');
};

subtest 'invalid transfer-coding combinations fail before application response delivery' => sub {
    for my $field (
        'chunked, chunked',
        'chunked; bad=1',
        'gzip; broken',
    ) {
        my $responses = 0;
        my $error;
        my $client = Unblock::HTTP1::Client->new;
        my $tx = $client->request(
            request(),
            on_response => sub { ++$responses },
            on_error    => sub { $error = $_[1] },
        );
        $client->output;
        $client->input(
            "HTTP/1.1 200 OK\r\n" .
            "Transfer-Encoding: $field\r\n\r\n"
        );

        is($responses, 0, "$field is rejected before on_response");
        ok($error, "$field produces an explicit protocol error");
        is($tx->state, 'error', "$field makes the transaction terminal");
        ok($client->is_closed, "$field closes the connection");
    }
};

subtest 'HTTP/1.0 messages cannot carry Transfer-Encoding' => sub {
    my $request_head = Unblock::HTTP1::_Native->parse_request_head(
        "POST / HTTP/1.0\r\n" .
        "Transfer-Encoding: chunked\r\n\r\n"
    );
    ok(!$request_head->{ok}, 'HTTP/1.0 request Transfer-Encoding is rejected');
    is($request_head->{status}, 400, 'HTTP/1.0 request framing error maps to 400');

    my $responses = 0;
    my $error;
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        request(),
        on_response => sub { ++$responses },
        on_error    => sub { $error = $_[1] },
    );
    $client->output;
    $client->input(
        "HTTP/1.0 200 OK\r\n" .
        "Transfer-Encoding: chunked\r\n\r\n" .
        "0\r\n\r\n"
    );

    is($responses, 0, 'HTTP/1.0 Transfer-Encoding response is rejected before callback');
    like($error, qr/HTTP\/1\.0 response must not contain Transfer-Encoding/,
        'HTTP/1.0 response error is explicit');
    is($tx->state, 'error', 'faulty HTTP/1.0 response makes transaction terminal');
};

done_testing;
