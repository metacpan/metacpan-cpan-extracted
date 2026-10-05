use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::_Wire;

sub request {
    return Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => '/',
        headers => [ [ Host => 'example.test' ] ],
    );
}

subtest 'equivalent Content-Length spellings are the same value' => sub {
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
        "Content-Length: 003\r\n" .
        "Content-Length: 3\r\n\r\n" .
        "abc"
    );

    is($body, 'abc', 'body is framed by the shared numeric Content-Length');
    ok($tx->is_complete, 'response completes');
    ok(!$error, 'equivalent decimal spellings are accepted');
};

subtest 'comma-combined equivalent Content-Length spellings are accepted' => sub {
    my $body = '';
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        request(),
        on_body  => sub { $body .= $_[2] },
        on_error => sub { die "unexpected response error: $_[1]" },
    );
    $client->output;

    $client->input(
        "HTTP/1.1 200 OK\r\n" .
        "Content-Length: 0003, 3\r\n\r\n" .
        "abc"
    );

    is($body, 'abc', 'combined values normalize numerically');
    ok($tx->is_complete, 'combined equivalent length completes');
};

subtest 'oversized received Content-Length is rejected' => sub {
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
        "Content-Length: 184467440737095516160\r\n\r\n"
    );

    is($responses, 0, 'oversized length is rejected before on_response');
    like($error, qr/Content-Length exceeds supported framing range/,
        'overflow error is explicit');
    is($tx->state, 'error', 'overflow makes transaction terminal');
};

subtest 'outgoing planner rejects oversized Content-Length' => sub {
    my $response = Uniform::HTTP::Response->new(
        status  => 200,
        headers => [
            [ 'Content-Length' => '184467440737095516160' ],
        ],
    );

    my $ok = eval {
        Unblock::HTTP1::_Wire::response_plan(request(), $response);
        1;
    };
    ok(!$ok, 'oversized outgoing length is rejected');
    like($@, qr/Content-Length exceeds supported framing range/,
        'outgoing overflow error is explicit');
};

done_testing;
