use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;

sub get_request {
    my ($target) = @_;
    return Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => $target,
        headers => [ [ Host => 'example.test' ] ],
    );
}

subtest 'client queues requests serially until prior response completes' => sub {
    my @complete;
    my $client = Unblock::HTTP1::Client->new;
    my $one = $client->request(
        get_request('/one'),
        on_complete => sub { push @complete, '/one' },
    );
    my $two = $client->request(
        get_request('/two'),
        on_complete => sub { push @complete, '/two' },
    );

    my $first_wire = $client->output;
    like($first_wire, qr/\AGET \/one HTTP\/1\.1\r\n/,
        'only first queued request is serialized initially');
    unlike($first_wire, qr/GET \/two /, 'second request is not pipelined implicitly');

    $client->input(
        "HTTP/1.1 200 OK\r\nContent-Length: 3\r\n\r\none"
    );
    ok($one->is_complete, 'first queued transaction completes');
    is_deeply(\@complete, [ '/one' ], 'first completion callback runs first');

    my $second_wire = $client->output;
    like($second_wire, qr/\AGET \/two HTTP\/1\.1\r\n/,
        'second request starts only after first response boundary');

    $client->input(
        "HTTP/1.1 200 OK\r\nContent-Length: 3\r\n\r\ntwo"
    );
    ok($two->is_complete, 'second queued transaction completes');
    is_deeply(\@complete, [ '/one', '/two' ], 'queued completion order follows wire order');
};

subtest 'rejected CONNECT remains ordinary reusable HTTP' => sub {
    my @status;
    my $body = '';
    my $client = Unblock::HTTP1::Client->new;

    my $connect = $client->request(
        Uniform::HTTP::Request->new(
            method => 'CONNECT',
            target => 'example.test:443',
            headers => [ [ Host => 'example.test:443' ] ],
        ),
        on_response => sub { push @status, $_[1]->status },
        on_body => sub { $body .= $_[2] },
    );
    my $next = $client->request(
        get_request('/after'),
        on_response => sub { push @status, $_[1]->status },
        on_body => sub { $body .= $_[2] },
    );

    $client->output;
    $client->input(
        "HTTP/1.1 407 Proxy Authentication Required\r\n" .
        "Content-Length: 4\r\n\r\nnope"
    );

    ok(!$client->is_switched, 'non-2xx CONNECT does not enter tunnel mode');
    ok($connect->is_complete, 'rejected CONNECT completes as ordinary response');
    like($client->output, qr/\AGET \/after HTTP\/1\.1\r\n/,
        'connection remains reusable after rejected CONNECT');

    $client->input(
        "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok"
    );
    ok($next->is_complete, 'request after rejected CONNECT completes');
    is_deeply(\@status, [407, 200], 'status sequence remains ordinary HTTP');
    is($body, 'nopeok', 'both response bodies are delivered in order');
};

subtest 'Connection close fails queued requests instead of serializing them' => sub {
    my $queued_error;
    my $client = Unblock::HTTP1::Client->new;
    my $first = $client->request(get_request('/one'));
    my $second = $client->request(
        get_request('/two'),
        on_error => sub { $queued_error = $_[1] },
    );
    $client->output;

    $client->input(
        "HTTP/1.1 200 OK\r\n" .
        "Content-Length: 2\r\nConnection: close\r\n\r\nok"
    );

    ok($first->is_complete, 'first close response completes normally');
    is($second->state, 'error', 'queued request fails when connection cannot be reused');
    like($queued_error, qr/not reusable/i, 'queued request receives reuse failure');
    is($client->output, '', 'queued request is never serialized after Connection close');
    ok($client->is_closed, 'client connection is closed');
};

done_testing;
