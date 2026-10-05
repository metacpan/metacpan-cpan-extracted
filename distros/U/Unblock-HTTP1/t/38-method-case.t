use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::_Wire;

subtest 'lowercase head is an ordinary extension method' => sub {
    my $request = Uniform::HTTP::Request->new(
        method  => 'head',
        target  => '/',
        headers => [ [ Host => 'example.test' ] ],
    );
    my $response = Uniform::HTTP::Response->new(
        status => 200,
        body   => 'ok',
    );

    my $plan = Unblock::HTTP1::_Wire::response_plan($request, $response);
    like(
        $plan->{wire},
        qr/\r\nContent-Length: 2\r\n\r\nok\z/,
        'lowercase head response carries an ordinary body',
    );

    my $body = '';
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        $request,
        on_body => sub { $body .= $_[2] },
        on_error => sub { die "unexpected client error: $_[1]" },
    );
    $client->output;
    $client->input(
        "HTTP/1.1 200 OK\r\n" .
        "Content-Length: 2\r\n\r\n" .
        "ok"
    );

    is($body, 'ok', 'lowercase head response body is delivered');
    ok($tx->is_complete, 'lowercase head transaction completes normally');
};

subtest 'lowercase connect is not CONNECT semantics' => sub {
    my $request = Uniform::HTTP::Request->new(
        method  => 'connect',
        target  => '/ordinary',
        headers => [ [ Host => 'example.test' ] ],
    );

    my $plan = Unblock::HTTP1::_Wire::request_plan($request);
    like(
        $plan->{wire},
        qr/\Aconnect \/ordinary HTTP\/1\.1\r\n/,
        'lowercase connect accepts ordinary request-target form',
    );

    my $body = '';
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        $request,
        on_body => sub { $body .= $_[2] },
        on_error => sub { die "unexpected client error: $_[1]" },
    );
    $client->output;
    $client->input(
        "HTTP/1.1 200 OK\r\n" .
        "Content-Length: 2\r\n\r\n" .
        "ok"
    );

    ok(!$client->is_switched, 'lowercase connect does not enter tunnel mode');
    is($body, 'ok', 'lowercase connect receives an ordinary response body');
    ok($tx->is_complete, 'lowercase connect transaction completes normally');
};

done_testing;
