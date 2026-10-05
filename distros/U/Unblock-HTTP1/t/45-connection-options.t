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

subtest 'received request Connection options are tokens' => sub {
    my $good = Unblock::HTTP1::_Native->parse_request_head(
        "GET / HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Connection: , keep-alive, , close,\r\n\r\n"
    );
    ok($good->{ok}, 'empty received list elements are tolerated');
    ok(!$good->{keep_alive}, 'valid close token still controls persistence');

    my $bad = Unblock::HTTP1::_Native->parse_request_head(
        "GET / HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Connection: keep alive\r\n\r\n"
    );
    ok(!$bad->{ok}, 'non-token Connection member is rejected');
    is($bad->{status}, 400, 'invalid Connection request maps to 400');
};

subtest 'received response rejects malformed Connection option' => sub {
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
        "Connection: keep alive\r\n" .
        "Content-Length: 0\r\n\r\n"
    );

    is($responses, 0, 'malformed Connection response is rejected before callback');
    like($error, qr/invalid Connection option/,
        'response Connection error is explicit');
    is($tx->state, 'error', 'malformed Connection response is terminal');
};

subtest 'outgoing request and response reject malformed Connection options' => sub {
    my $bad_request = Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => '/',
        headers => [
            [ Host => 'example.test' ],
            [ Connection => 'keep alive' ],
        ],
    );

    my $request_ok = eval {
        Unblock::HTTP1::_Wire::request_plan($bad_request);
        1;
    };
    ok(!$request_ok, 'malformed outgoing request Connection is rejected');
    like($@, qr/invalid Connection option/,
        'outgoing request Connection error is explicit');

    my $bad_response = Uniform::HTTP::Response->new(
        status  => 200,
        headers => [ [ Connection => 'keep alive' ] ],
    );
    my $response_ok = eval {
        Unblock::HTTP1::_Wire::response_plan(request(), $bad_response);
        1;
    };
    ok(!$response_ok, 'malformed outgoing response Connection is rejected');
    like($@, qr/invalid Connection option/,
        'outgoing response Connection error is explicit');
};

done_testing;
