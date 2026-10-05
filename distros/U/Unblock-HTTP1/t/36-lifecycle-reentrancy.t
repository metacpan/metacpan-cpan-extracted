use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;

subtest 'received request completion follows actual body boundary' => sub {
    my @seen;
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx, $request) = @_;
            push @seen, [
                $request->target,
                'request',
                $request->is_complete ? 1 : 0,
                $request->initial_is_mutable ? 1 : 0,
            ];
            $tx->respond(Uniform::HTTP::Response->new(status => 200, body => 'ok'));
        },
        on_request_end => sub {
            my ($tx, $request) = @_;
            push @seen, [
                $request->target,
                'end',
                $request->is_complete ? 1 : 0,
                $request->initial_is_mutable ? 1 : 0,
            ];
        },
    );

    $server->input(
        "GET /none HTTP/1.1\r\nHost: example.test\r\n\r\n" .
        "POST /zero HTTP/1.1\r\nHost: example.test\r\nContent-Length: 0\r\n\r\n" .
        "POST /body HTTP/1.1\r\nHost: example.test\r\nContent-Length: 1\r\nConnection: close\r\n\r\nx"
    );

    is_deeply(
        \@seen,
        [
            [ '/none', 'request', 1, 0 ],
            [ '/none', 'end',     1, 0 ],
            [ '/zero', 'request', 0, 0 ],
            [ '/zero', 'end',     1, 0 ],
            [ '/body', 'request', 0, 0 ],
            [ '/body', 'end',     1, 0 ],
        ],
        'bodyless, zero-length, and bodyful request completion states match framing boundaries',
    );
};

subtest 'server transport input cannot recursively enter from callback' => sub {
    my $callback_error;
    my $server;
    $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx) = @_;
            my $ok = eval {
                $server->input(
                    "GET /nested HTTP/1.1\r\nHost: example.test\r\n\r\n"
                );
                1;
            };
            $callback_error = $@ unless $ok;
            die $callback_error if !$ok;
        },
    );

    $server->input(
        "GET / HTTP/1.1\r\nHost: example.test\r\n\r\n"
    );

    like($callback_error, qr/cannot be called recursively/,
        'recursive server input fails explicitly');
    like($server->output, qr/\AHTTP\/1\.1 500 /,
        'recursive transport entry becomes protocol-safe server failure');
    ok($server->is_closed, 'recursive server entry closes the connection');
};

subtest 'client transport input cannot recursively enter from callback' => sub {
    my $callback_error;
    my $reported_error;
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        Uniform::HTTP::Request->new(
            method => 'GET',
            target => '/',
            headers => [ [ Host => 'example.test' ] ],
        ),
        on_response => sub {
            my $ok = eval {
                $client->input(
                    "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"
                );
                1;
            };
            $callback_error = $@ unless $ok;
            die $callback_error if !$ok;
        },
        on_error => sub { $reported_error = $_[1] },
    );
    $client->output;

    $client->input(
        "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"
    );

    like($callback_error, qr/cannot be called recursively/,
        'recursive client input fails explicitly');
    like($reported_error, qr/cannot be called recursively/,
        'callback failure is reported as client transaction error');
    is($tx->state, 'error', 'recursive client entry makes Transaction error');
    ok($client->is_closed, 'recursive client entry closes connection');
};

done_testing;
