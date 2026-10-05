use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;

sub request {
    my ($target) = @_;
    return Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => $target,
        headers => [ [ Host => 'example.test' ] ],
    );
}

subtest 'server retains higher received minor and responds with supported version' => sub {
    my $seen_version;
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx, $request) = @_;
            $seen_version = $request->version;
            $tx->respond(Uniform::HTTP::Response->new(
                status => 200,
                body   => 'ok',
            ));
        },
    );

    $server->input(
        "GET / HTTP/1.9\r\nHost: example.test\r\n\r\n"
    );

    is($seen_version, '1.9', 'received Uniform request retains actual wire version');
    like(
        $server->output,
        qr/\AHTTP\/1\.1 200 OK\r\n/,
        'server emits the highest HTTP/1 version it implements',
    );
    ok(!$server->is_closed,
        'higher minor version receives HTTP/1.1 persistent semantics');
};

subtest 'client treats higher response minor as HTTP/1.1 semantics' => sub {
    my @version;
    my @complete;
    my $client = Unblock::HTTP1::Client->new;

    my $first = $client->request(
        request('/one'),
        on_response => sub {
            my ($tx, $response) = @_;
            push @version, $response->version;
        },
        on_complete => sub { push @complete, 'one' },
        on_error => sub { die "unexpected first response error: $_[1]" },
    );
    my $second = $client->request(
        request('/two'),
        on_response => sub {
            my ($tx, $response) = @_;
            push @version, $response->version;
        },
        on_complete => sub { push @complete, 'two' },
        on_error => sub { die "unexpected second response error: $_[1]" },
    );

    like($client->output, qr/\AGET \/one HTTP\/1\.1\r\n/,
        'first request is sent');

    $client->input(
        "HTTP/1.9 204 No Content\r\n\r\n"
    );

    ok($first->is_complete, 'first higher-minor response completes');
    is_deeply(\@version, [ '1.9' ],
        'higher response minor is retained on Uniform response');
    ok(!$client->is_closed,
        'higher response minor keeps HTTP/1.1 persistence by default');
    like($client->output, qr/\AGET \/two HTTP\/1\.1\r\n/,
        'queued request starts after higher-minor persistent response');

    $client->input(
        "HTTP/1.1 204 No Content\r\n\r\n"
    );
    ok($second->is_complete, 'second response completes normally');
    is_deeply(\@complete, [ qw(one two) ],
        'both transactions complete in order');
};

subtest 'higher-minor Upgrade uses HTTP/1.1 switch semantics' => sub {
    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx) = @_;
            $tx->respond(Uniform::HTTP::Response->new(
                status  => 101,
                headers => [ [ Upgrade => 'test-proto' ] ],
            ));
        },
    );

    $server->input(
        "GET /switch HTTP/1.9\r\n" .
        "Host: example.test\r\n" .
        "Connection: Upgrade\r\n" .
        "Upgrade: test-proto\r\n\r\n" .
        "NEXT"
    );

    ok($server->is_switched,
        'higher HTTP/1 minor request can switch using HTTP/1.1 semantics');
    like($server->output, qr/\AHTTP\/1\.1 101 Switching Protocols\r\n/,
        'switch response advertises supported HTTP/1.1 version');
    is($server->take_remainder, 'NEXT',
        'post-switch bytes are preserved for higher-minor request');
};

done_testing;
