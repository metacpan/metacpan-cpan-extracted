use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;

sub feed_bytes {
    my ($engine, $bytes) = @_;
    for my $byte (split //, $bytes) {
        $engine->input($byte);
    }
}

subtest 'server request head, chunked body, and trailers survive byte fragmentation' => sub {
    my $body = '';
    my $trailer;
    my $complete = 0;

    my $server = Unblock::HTTP1::Server->new(
        on_request => sub { },
        on_body => sub {
            my ($tx, $request, $bytes) = @_;
            $body .= $bytes;
        },
        on_request_end => sub {
            my ($tx, $request) = @_;
            $trailer = $request->trailer('X-End');
            $complete++;
            $tx->respond(Uniform::HTTP::Response->new(
                status => 200,
                body   => 'ok',
            ));
        },
    );

    feed_bytes(
        $server,
        "POST /frag HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Transfer-Encoding: chunked\r\n" .
        "\r\n" .
        "3\r\nabc\r\n" .
        "2\r\nde\r\n" .
        "0\r\n" .
        "X-End: yes\r\n" .
        "\r\n"
    );

    is($body, 'abcde', 'fragmented chunked request body is reconstructed exactly');
    is($trailer, 'yes', 'fragmented request trailer is retained');
    is($complete, 1, 'request completes exactly once');
    is(
        $server->output,
        "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok",
        'server remains able to serialize response after fragmented input',
    );
};

subtest 'client response head, chunked body, and trailers survive byte fragmentation' => sub {
    my $body = '';
    my $trailer;
    my $complete = 0;
    my $error;

    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        Uniform::HTTP::Request->new(
            method  => 'GET',
            target  => '/',
            headers => [ [ Host => 'example.test' ] ],
        ),
        on_body => sub {
            my ($tx, $response, $bytes) = @_;
            $body .= $bytes;
        },
        on_complete => sub {
            my ($tx) = @_;
            $trailer = $tx->response->trailer('X-End');
            $complete++;
        },
        on_error => sub { $error = $_[1] },
    );
    $client->output;

    feed_bytes(
        $client,
        "HTTP/1.1 200 OK\r\n" .
        "Transfer-Encoding: chunked\r\n" .
        "\r\n" .
        "1\r\na\r\n" .
        "4\r\nbcde\r\n" .
        "0\r\n" .
        "X-End: done\r\n" .
        "\r\n"
    );

    ok(!$error, 'fragmented client response has no protocol error');
    is($body, 'abcde', 'fragmented chunked response body is reconstructed exactly');
    is($trailer, 'done', 'fragmented response trailer is retained');
    is($complete, 1, 'fragmented response completes exactly once');
    ok($tx->is_complete, 'Transaction is complete after fragmented response');
};

subtest 'server preserves pipelined ordering with fragmented reads' => sub {
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

    feed_bytes(
        $server,
        "GET /one HTTP/1.1\r\nHost: example.test\r\n\r\n" .
        "GET /two HTTP/1.1\r\nHost: example.test\r\nConnection: close\r\n\r\n"
    );

    is_deeply(\@target, [ '/one', '/two' ],
        'fragmented pipelined requests dispatch in wire order');
    is(
        $server->output,
        "HTTP/1.1 200 OK\r\nContent-Length: 4\r\n\r\n/one" .
        "HTTP/1.1 200 OK\r\nContent-Length: 4\r\nConnection: close\r\n\r\n/two",
        'responses remain ordered for fragmented pipelined requests',
    );
};

subtest 'client handles informational and final response split at every byte' => sub {
    my @status;
    my $body = '';
    my $error;

    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        Uniform::HTTP::Request->new(
            method  => 'POST',
            target  => '/',
            headers => [ [ Host => 'example.test' ] ],
            body    => 'x',
        ),
        on_informational => sub { push @status, $_[1]->status },
        on_response => sub { push @status, $_[1]->status },
        on_body => sub { $body .= $_[2] },
        on_error => sub { $error = $_[1] },
    );
    $client->output;

    feed_bytes(
        $client,
        "HTTP/1.1 100 Continue\r\n\r\n" .
        "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok"
    );

    ok(!$error, 'fragmented informational/final sequence has no error');
    is_deeply(\@status, [100, 200], 'informational response precedes final response');
    is($body, 'ok', 'final body follows informational response correctly');
    ok($tx->is_complete, 'transaction completes after fragmented final body');
};

done_testing;
