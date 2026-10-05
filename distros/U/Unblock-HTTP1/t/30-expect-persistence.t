use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Response;
use Unblock::HTTP1::Server;

subtest '100-continue is emitted before request body application flow' => sub {
    my @event;
    my $body = '';
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            push @event, 'request';
        },
        on_body => sub {
            my ($tx, $request, $bytes) = @_;
            push @event, 'body';
            $body .= $bytes;
        },
        on_request_end => sub {
            my ($tx) = @_;
            push @event, 'end';
            $tx->respond(Uniform::HTTP::Response->new(
                status => 200,
                body   => 'ok',
            ));
        },
    );

    $server->input(
        "POST /expect HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Content-Length: 4\r\n" .
        "Expect: 100-continue\r\n" .
        "\r\n"
    );

    is($server->output, "HTTP/1.1 100 Continue\r\n\r\n",
        'server emits 100 Continue before request body arrives');
    is_deeply(\@event, [ 'request' ],
        'request head reaches application once before body');

    $server->input('data');
    is($body, 'data', 'request body is delivered after Continue');
    is_deeply(\@event, [ qw(request body end) ],
        'normal request lifecycle follows the interim response');
    is(
        $server->output,
        "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok",
        'final response follows body completion',
    );
};

subtest 'unsupported Expect is rejected before application dispatch' => sub {
    my $request_hits = 0;
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub { $request_hits++ },
    );

    $server->input(
        "POST /expect HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Content-Length: 4\r\n" .
        "Expect: something-else\r\n" .
        "\r\n"
    );

    is($request_hits, 0, 'unsupported expectation never reaches application');
    like($server->output, qr/\AHTTP\/1\.1 417 Expectation Failed\r\n/,
        'unsupported expectation receives 417');
    ok($server->is_closed, 'unsupported expectation closes the HTTP connection');
};

subtest 'HTTP/1.0 ignores Expect instead of sending 100 or 417' => sub {
    my @event;
    my $body = '';
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub { push @event, 'request' },
        on_body => sub {
            my ($tx, $request, $bytes) = @_;
            $body .= $bytes;
            push @event, 'body';
        },
        on_request_end => sub {
            my ($tx) = @_;
            push @event, 'end';
            $tx->respond(Uniform::HTTP::Response->new(
                status => 200,
                body   => 'ok',
            ));
        },
    );

    $server->input(
        "POST /old HTTP/1.0\r\n" .
        "Content-Length: 4\r\n" .
        "Expect: 100-continue\r\n" .
        "\r\n"
    );

    is($server->output, '',
        'HTTP/1.0 Expect does not generate an informational or error response');
    is_deeply(\@event, [ 'request' ],
        'HTTP/1.0 request head reaches the application normally');

    $server->input('data');
    is($body, 'data', 'HTTP/1.0 request body is delivered normally');
    is_deeply(\@event, [ qw(request body end) ],
        'HTTP/1.0 request completes normally');
    is(
        $server->output,
        "HTTP/1.0 200 OK\r\nContent-Length: 2\r\n\r\nok",
        'ordinary final response is emitted without an interim response',
    );
};

subtest 'server cannot send informational response to HTTP/1.0 client' => sub {
    my $informational_error;
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx) = @_;
            my $ok = eval {
                $tx->send_informational(
                    Uniform::HTTP::Response->new(status => 103)
                );
                1;
            };
            $informational_error = $@ unless $ok;
            $tx->respond(Uniform::HTTP::Response->new(
                status => 200,
                body   => 'ok',
            ));
        },
    );

    $server->input("GET / HTTP/1.0\r\n\r\n");

    like(
        $informational_error,
        qr/HTTP\/1\.0 clients cannot receive 1xx responses/,
        'informational response attempt fails explicitly',
    );
    my $wire = $server->output;
    unlike($wire, qr/\AHTTP\/1\.0 1[0-9][0-9]/,
        'no 1xx response reaches the HTTP/1.0 wire');
    is(
        $wire,
        "HTTP/1.0 200 OK\r\nContent-Length: 2\r\n\r\nok",
        'final HTTP/1.0 response remains valid',
    );
};

subtest 'HTTP/1.0 known-length response can remain persistent' => sub {
    my @target;
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx, $request) = @_;
            push @target, $request->target;
            $tx->respond(Uniform::HTTP::Response->new(
                status => 200,
                body   => $request->target,
            ));
        },
    );

    $server->input(
        "GET /one HTTP/1.0\r\nConnection: keep-alive\r\n\r\n" .
        "GET /two HTTP/1.0\r\n\r\n"
    );

    is_deeply(\@target, [ '/one', '/two' ],
        'HTTP/1.0 keep-alive permits another request');
    is(
        $server->output,
        "HTTP/1.0 200 OK\r\nContent-Length: 4\r\nConnection: keep-alive\r\n\r\n/one" .
        "HTTP/1.0 200 OK\r\nContent-Length: 4\r\n\r\n/two",
        'HTTP/1.0 persistence is explicit only when retained',
    );
    ok($server->is_closed, 'second default-close HTTP/1.0 request retires connection');
};

subtest 'HTTP/1.0 unknown-length streaming response is close-delimited' => sub {
    my $write_ok;
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx) = @_;
            $tx->respond(
                Uniform::HTTP::Response->new(
                    status  => 200,
                    headers => [ [ 'Content-Type', 'text/plain' ] ],
                ),
                stream_body => 1,
            );
            $write_ok = $tx->write('old ');
            $tx->end("school\n");
        },
    );

    $server->input(
        "GET /legacy HTTP/1.0\r\nConnection: keep-alive\r\n\r\n"
    );

    ok($write_ok, 'HTTP/1.0 body write reports accepted output');
    my $wire = $server->output;
    unlike($wire, qr/Transfer-Encoding:/i,
        'HTTP/1.0 stream does not use chunked transfer coding');
    unlike($wire, qr/Content-Length:/i,
        'unknown-length HTTP/1.0 stream does not invent Content-Length');
    unlike($wire, qr/Connection: (?:keep-alive|close)/i,
        'close-delimited HTTP/1.0 response does not advertise persistence');
    is(
        $wire,
        "HTTP/1.0 200 OK\r\nContent-Type: text/plain\r\n\r\nold school\n",
        'HTTP/1.0 stream is raw close-delimited content',
    );
    ok($server->is_closed, 'server closes after close-delimited response completes');
};

done_testing;
