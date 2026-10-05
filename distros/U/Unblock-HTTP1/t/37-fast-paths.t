use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;
use Unblock::HTTP1::_Wire;

subtest 'ordinary buffered request uses correct HTTP/1.1 framing' => sub {
    my $request = Uniform::HTTP::Request->new(
        method    => 'POST',
        target    => '/upload',
        authority => 'example.test',
        headers   => [ [ 'X-Test', 'one' ] ],
        body      => 'abc',
    );

    my $plan = Unblock::HTTP1::_Wire::request_plan($request);

    is(
        $plan->{wire},
        "POST /upload HTTP/1.1\r\n" .
        "X-Test: one\r\n" .
        "Host: example.test\r\n" .
        "Content-Length: 3\r\n" .
        "\r\n" .
        "abc",
        'buffered request gets Host and Content-Length exactly once',
    );
    is($plan->{mode}, 'content-length', 'buffered request reports fixed framing');
    is($plan->{remaining}, 0, 'buffered request body is already finalized');
    ok($plan->{keep_alive}, 'ordinary HTTP/1.1 request remains persistent');

    my $empty = Uniform::HTTP::Request->new(
        method    => 'POST',
        target    => '/empty',
        authority => 'example.test',
        body      => '',
    );
    my $empty_plan = Unblock::HTTP1::_Wire::request_plan($empty);
    like(
        $empty_plan->{wire},
        qr/\r\nContent-Length: 0\r\n\r\n\z/,
        'explicit empty buffered body retains Content-Length zero',
    );
};

sub server_events {
    my (@part) = @_;
    my @event;
    my $body = '';
    my @body_complete;

    my $server = Unblock::HTTP1::Server->new(
        on_request => sub {
            my ($tx, $request) = @_;
            push @event, [
                request => $request->is_complete ? 1 : 0,
                $request->initial_is_mutable ? 1 : 0,
            ];
        },
        on_body => sub {
            my ($tx, $request, $bytes) = @_;
            $body .= $bytes;
            push @body_complete, $request->is_complete ? 1 : 0;
        },
        on_request_end => sub {
            my ($tx, $request) = @_;
            push @event, [
                end => $request->is_complete ? 1 : 0,
                $request->initial_is_mutable ? 1 : 0,
            ];
            $tx->respond(
                Uniform::HTTP::Response->new(status => 200, body => 'ok')
            );
        },
    );

    $server->input($_) for @part;
    return (\@event, $body, \@body_complete, $server->output);
}

subtest 'coalesced fixed request matches fragmented request lifecycle' => sub {
    my $head =
        "POST / HTTP/1.1\r\n" .
        "Host: example.test\r\n" .
        "Content-Length: 3\r\n" .
        "\r\n";

    my ($coalesced, $coalesced_body, $coalesced_body_state, $coalesced_wire)
        = server_events($head . 'abc');
    my ($fragmented, $fragmented_body, $fragmented_body_state, $fragmented_wire)
        = server_events($head . 'a', 'bc');

    is_deeply(
        $coalesced,
        [
            [ request => 0, 0 ],
            [ end => 1, 0 ],
        ],
        'coalesced fixed request preserves request/end lifecycle',
    );
    is_deeply(
        $fragmented,
        $coalesced,
        'fragmented fixed request preserves the same request/end lifecycle',
    );
    is($coalesced_body, 'abc', 'coalesced request body bytes are exact');
    is($fragmented_body, 'abc', 'fragmented request body bytes are exact');
    ok(!(grep { $_ } @$coalesced_body_state),
        'coalesced body callbacks observe an incomplete request');
    ok(!(grep { $_ } @$fragmented_body_state),
        'fragmented body callbacks observe an incomplete request');
    is($fragmented_wire, $coalesced_wire,
        'coalesced and fragmented requests produce identical response wire');
};

sub client_events {
    my (@part) = @_;
    my @event;
    my $body = '';
    my @body_complete;

    my $client = Unblock::HTTP1::Client->new;
    my $tx = $client->request(
        Uniform::HTTP::Request->new(
            method  => 'GET',
            target  => '/',
            headers => [ [ Host => 'example.test' ] ],
        ),
        on_response => sub {
            my ($tx, $response) = @_;
            push @event, [
                response => $response->is_complete ? 1 : 0,
                $response->initial_is_mutable ? 1 : 0,
            ];
        },
        on_body => sub {
            my ($tx, $response, $bytes) = @_;
            $body .= $bytes;
            push @body_complete, $response->is_complete ? 1 : 0;
        },
        on_complete => sub {
            my ($tx) = @_;
            my $response = $tx->response;
            push @event, [
                complete => $response->is_complete ? 1 : 0,
                $response->initial_is_mutable ? 1 : 0,
            ];
        },
    );
    $client->output;

    $client->input($_) for @part;
    return (\@event, $body, \@body_complete, $tx);
}

subtest 'coalesced fixed response matches fragmented response lifecycle' => sub {
    my $head =
        "HTTP/1.1 200 OK\r\n" .
        "Content-Length: 3\r\n" .
        "\r\n";

    my ($coalesced, $coalesced_body, $coalesced_body_state, $coalesced_tx)
        = client_events($head . 'abc');
    my ($fragmented, $fragmented_body, $fragmented_body_state, $fragmented_tx)
        = client_events($head . 'a', 'bc');

    is_deeply(
        $coalesced,
        [
            [ response => 0, 0 ],
            [ complete => 1, 0 ],
        ],
        'coalesced fixed response preserves response/completion lifecycle',
    );
    is_deeply(
        $fragmented,
        $coalesced,
        'fragmented fixed response preserves the same response/completion lifecycle',
    );
    is($coalesced_body, 'abc', 'coalesced response body bytes are exact');
    is($fragmented_body, 'abc', 'fragmented response body bytes are exact');
    ok(!(grep { $_ } @$coalesced_body_state),
        'coalesced body callbacks observe an incomplete response');
    ok(!(grep { $_ } @$fragmented_body_state),
        'fragmented body callbacks observe an incomplete response');
    ok($coalesced_tx->is_complete, 'coalesced response transaction completes');
    ok($fragmented_tx->is_complete, 'fragmented response transaction completes');
};

done_testing;
