use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;

subtest 'server request head limit returns 431 before application' => sub {
    my $hits = 0;
    my $server = Unblock::HTTP1::Server->new(
        max_head_size => 32,
        on_request => sub { $hits++ },
    );
    $server->input(
        "GET / HTTP/1.1\r\nHost: example.test\r\nX-Pad: " .
        ('x' x 40) . "\r\n\r\n"
    );
    is($hits, 0, 'oversized request head never reaches application');
    like($server->output, qr/\AHTTP\/1\.1 431 Request Header Fields Too Large\r\n/,
        'oversized request head receives 431');
    ok($server->is_closed, 'oversized request head closes connection');
};

subtest 'server header-count limit returns 431' => sub {
    my $server = Unblock::HTTP1::Server->new(
        max_headers => 2,
        on_request => sub { fail('too many headers must not dispatch') },
    );
    $server->input(
        "GET / HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "X-One: 1\r\n" .
        "X-Two: 2\r\n\r\n"
    );
    like($server->output, qr/\AHTTP\/1\.1 431 /,
        'too many request fields receive 431');
};

subtest 'client response head limit is terminal protocol error' => sub {
    my $response_hits = 0;
    my $error;
    my $client = Unblock::HTTP1::Client->new(max_head_size => 32);
    my $tx = $client->request(
        Uniform::HTTP::Request->new(
            method => 'GET',
            target => '/',
            headers => [ [ Host => 'example.test' ] ],
        ),
        on_response => sub { $response_hits++ },
        on_error => sub { $error = $_[1] },
    );
    $client->output;
    $client->input(
        "HTTP/1.1 200 OK\r\nX-Pad: " . ('x' x 40) . "\r\n\r\n"
    );
    is($response_hits, 0, 'oversized response is rejected before callback');
    like($error, qr/head exceeds configured limit/i,
        'oversized response error identifies configured limit');
    is($tx->state, 'error', 'oversized response makes Transaction error');
    ok($client->is_closed, 'oversized response closes connection');
};

subtest 'chunk trailer limit is enforced independently' => sub {
    my $error;
    my $client = Unblock::HTTP1::Client->new(max_head_size => 64);
    my $tx = $client->request(
        Uniform::HTTP::Request->new(
            method => 'GET',
            target => '/',
            headers => [ [ Host => 'example.test' ] ],
        ),
        on_error => sub { $error = $_[1] },
    );
    $client->output;
    $client->input(
        "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n" .
        "1\r\nx\r\n0\r\nX-Trailer: " . ('y' x 80) . "\r\n\r\n"
    );
    like($error, qr/trailer section exceeds configured limit/i,
        'oversized trailer section is rejected');
    is($tx->state, 'error', 'oversized trailers make Transaction error');
};


subtest 'chunk extension size limit rejects oversized request framing' => sub {
    my $hits = 0;
    my $server = Unblock::HTTP1::Server->new(
        max_chunk_extension_size => 4,
        on_request => sub { ++$hits },
    );

    $server->input(
        "POST / HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Transfer-Encoding: chunked\r\n\r\n" .
        "1;abcde\r\nx\r\n0\r\n\r\n"
    );

    is($hits, 1, 'request head is delivered before body framing fails');
    like($server->output, qr/\AHTTP\/1\.1 400 Bad Request\r\n/,
        'oversized chunk extension receives 400');
    ok($server->is_closed, 'oversized chunk extension closes connection');
};

subtest 'zero chunk extension limit opts out of the extension budget' => sub {
    my $body = '';
    my $server = Unblock::HTTP1::Server->new(
        max_chunk_extension_size => 0,
        on_request => sub { },
        on_body => sub { $body .= $_[2] },
    );

    $server->input(
        "POST / HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Transfer-Encoding: chunked\r\n\r\n" .
        "1;" . ('a' x 100) . "\r\nx\r\n0\r\n\r\n"
    );

    is($body, 'x', 'zero limit permits long chunk extensions');
    ok(!$server->is_closed, 'unlimited extension setting remains usable');
};


subtest 'unknown engine options are rejected' => sub {
    my $ok = eval {
        Unblock::HTTP1::Server->new(
            max_chunk_extenson_size => 4,
            on_request => sub { },
        );
        1;
    };
    ok(!$ok, 'misspelled engine option is not silently ignored');
    like($@, qr/unknown option 'max_chunk_extenson_size'/,
        'unknown option error identifies the typo');
};

done_testing;
