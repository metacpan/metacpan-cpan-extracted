use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;

subtest 'client streaming request exposes high/low-water backpressure' => sub {
    my $drains = 0;
    my $client = Unblock::HTTP1::Client->new(
        high_water => 32,
        low_water  => 8,
    );

    my $tx = $client->request(
        Uniform::HTTP::Request->new(
            method => 'POST',
            target => '/',
            headers => [ [ Host => 'example.test' ] ],
        ),
        stream_body => 1,
        on_drain => sub { $drains++ },
    );

    $client->output;
    my $before_empty = $client->want_write;
    ok($tx->write(''), 'empty request-body write is accepted');
    is($client->want_write, $before_empty,
        'empty request-body write emits no chunk framing');

    my $accepted = $tx->write('x' x 40);
    ok(!$accepted, 'large request chunk crosses high-water mark');
    is($drains, 0, 'drain callback does not run while output remains queued');

    my $wire = $client->output;
    like($wire, qr/\A28\r\n/i, 'large request body is framed as one chunk');
    is($drains, 1, 'drain callback fires after output falls below low-water mark');

    $tx->end('');
    is($client->output, "0\r\n\r\n",
        'final empty end emits exactly one terminating chunk');
};

subtest 'server streaming response exposes high/low-water backpressure' => sub {
    my $drains = 0;
    my $write_status;
    my $server = Unblock::HTTP1::Server->new(
        high_water => 48,
        low_water  => 8,
        on_request => sub {
            my ($tx) = @_;
            $tx->respond(
                Uniform::HTTP::Response->new(status => 200),
                stream_body => 1,
                on_drain => sub { $drains++ },
            );

            ok($tx->write(''), 'empty response-body write is accepted');
            $write_status = $tx->write('y' x 64);
        },
    );

    $server->input(
        "GET / HTTP/1.1\r\nHost: example.test\r\n\r\n"
    );

    ok(!$write_status, 'large response chunk crosses high-water mark');
    is($drains, 0, 'server drain waits until queued output is removed');

    my $wire = $server->output;
    like(
        $wire,
        qr/\AHTTP\/1\.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n40\r\n/s,
        'response head and large chunk are queued together',
    );
    unlike($wire, qr/0\r\n\r\n0\r\n\r\n/,
        'empty response write does not terminate the stream');
    is($drains, 1, 'server drain callback fires after output drains');

    my $tx = $server->transaction;
    $tx->end('');
    is($server->output, "0\r\n\r\n",
        'response end emits exactly one terminating chunk');
    ok($tx->is_complete, 'response Transaction completes after final chunk');
};

subtest 'fixed-length streaming request enforces declared length' => sub {
    my $client = Unblock::HTTP1::Client->new;
    my $short = $client->request(
        Uniform::HTTP::Request->new(
            method => 'POST',
            target => '/',
            headers => [
                [ Host => 'example.test' ],
                [ 'Content-Length' => '5' ],
            ],
        ),
        stream_body => 1,
    );
    $client->output;

    my $ok = eval { $short->end('abc'); 1 };
    ok(!$ok, 'short final request write is rejected');
    like($@, qr/ended before declared Content-Length/,
        'short body error identifies Content-Length mismatch');
    $short->cancel;

    my $client2 = Unblock::HTTP1::Client->new;
    my $long = $client2->request(
        Uniform::HTTP::Request->new(
            method => 'POST',
            target => '/',
            headers => [
                [ Host => 'example.test' ],
                [ 'Content-Length' => '5' ],
            ],
        ),
        stream_body => 1,
    );
    $client2->output;

    $ok = eval { $long->write('abcdef'); 1 };
    ok(!$ok, 'oversized request write is rejected');
    like($@, qr/exceeds declared Content-Length/,
        'oversized body error identifies Content-Length overflow');
    $long->cancel;
};

done_testing;
