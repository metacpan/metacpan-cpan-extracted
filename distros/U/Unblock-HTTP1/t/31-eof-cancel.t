use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Unblock::HTTP1::Client;

sub new_request {
    return Uniform::HTTP::Request->new(
        method  => 'POST',
        target  => '/',
        headers => [ [ Host => 'example.test' ] ],
    );
}

subtest 'truncated Content-Length response fails at EOF' => sub {
    my $error;
    my $complete = 0;
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        Uniform::HTTP::Request->new(
            method => 'GET', target => '/', headers => [ [ Host => 'example.test' ] ],
        ),
        on_complete => sub { $complete++ },
        on_error => sub { $error = $_[1] },
    );
    $client->output;
    $client->input(
        "HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nabc"
    );
    $client->input_eof;

    is($complete, 0, 'truncated fixed body does not complete');
    like($error, qr/unexpected EOF/i, 'truncated fixed body reports EOF error');
    is($tx->state, 'error', 'truncated fixed body makes Transaction error');
    ok($client->is_closed, 'truncated fixed body closes connection');
    ok(!$tx->response->is_complete, 'partial Uniform response remains incomplete');
};

subtest 'truncated chunked response fails at EOF' => sub {
    my $error;
    my $body = '';
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        Uniform::HTTP::Request->new(
            method => 'GET', target => '/', headers => [ [ Host => 'example.test' ] ],
        ),
        on_body => sub { $body .= $_[2] },
        on_error => sub { $error = $_[1] },
    );
    $client->output;
    $client->input(
        "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n" .
        "4\r\ntest\r\n3\r\nab"
    );
    $client->input_eof;

    is($body, 'testab', 'available decoded bytes are delivered before truncation');
    like($error, qr/unexpected EOF/i, 'truncated chunked body reports EOF error');
    is($tx->state, 'error', 'truncated chunked body makes Transaction error');
};

subtest 'explicit cancellation during response body is not an error' => sub {
    my $body = '';
    my $complete = 0;
    my $errors = 0;
    my $closed_in_callback = 0;
    my $response_complete = 1;

    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        Uniform::HTTP::Request->new(
            method => 'GET', target => '/', headers => [ [ Host => 'example.test' ] ],
        ),
        on_body => sub {
            my ($tx, $response, $bytes) = @_;
            $body .= $bytes;
            $tx->cancel;
            $closed_in_callback = $client->is_closed ? 1 : 0;
            $response_complete = $response->is_complete ? 1 : 0;
        },
        on_complete => sub { $complete++ },
        on_error => sub { $errors++ },
    );
    $client->output;
    $client->input(
        "HTTP/1.1 200 OK\r\nContent-Length: 100\r\n\r\npartial"
    );

    is($body, 'partial', 'body callback receives partial bytes before cancellation');
    ok($tx->is_cancelled, 'Transaction reports explicit cancellation');
    ok($closed_in_callback, 'cancellation closes connection immediately');
    ok(!$response_complete, 'cancelled response remains incomplete');
    is($complete, 0, 'cancelled response does not call on_complete');
    is($errors, 0, 'explicit cancellation does not call on_error');
};

subtest 'early final response retires unfinished streaming request' => sub {
    my $complete = 0;
    my $error;
    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        new_request(),
        stream_body => 1,
        on_complete => sub { $complete++ },
        on_error => sub { $error = $_[1] },
    );

    $client->output;
    $tx->write('partial');
    my $queued_before = $client->output;
    ok(length($queued_before), 'partial streamed request body was produced');

    $client->input(
        "HTTP/1.1 413 Content Too Large\r\n" .
        "Content-Length: 8\r\nConnection: close\r\n\r\n" .
        "rejected"
    );

    ok(!$error, 'early final response is not a client protocol error');
    is($complete, 1, 'early final response completes Transaction');
    ok($tx->is_complete, 'Transaction completes despite unfinished request producer');
    ok($client->is_closed, 'early final response makes connection non-reusable');

    my $ok = eval { $tx->write('more'); 1 };
    ok(!$ok, 'request body cannot continue after final response');
    like($@, qr/terminal|complete/i, 'post-response body write has a clear error');
};

done_testing;
