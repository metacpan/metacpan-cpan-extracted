use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

{
    my $server = Unblock::HTTP2::Server->new;

    my $ok = eval {
        $server->input('X' x 24);
        1;
    };

    ok !$ok,
        'fatal nghttp2 receive failure is rethrown to the caller';
    like $@, qr/nghttp2|client magic|receive failed/i,
        'fatal receive exception preserves useful backend detail';

    ok $server->is_closed,
        'fatal receive failure closes the engine';
    like $server->close_reason, qr/nghttp2|client magic|receive failed/i,
        'fatal receive failure is retained as close_reason';

    ok !$server->want_read,
        'closed engine no longer wants protocol input';
    ok !$server->want_write,
        'closed engine no longer reports protocol output';

    my $again = eval {
        $server->input('anything');
        1;
    };
    ok !$again,
        'closed engine cannot be reused after fatal receive failure';
    like $@, qr/connection is closed/,
        'reuse failure is explicit';
}

{
    my $client = Unblock::HTTP2::Client->new;
    my $transaction = $client->request(
        Uniform::HTTP::Request->new(
            method    => 'GET',
            target    => '/',
            scheme    => 'https',
            authority => 'example.test',
        ),
    );

    ok !$transaction->is_error,
        'active transaction is not in error state';

    is $client->close('transport closed'), $client,
        'explicit close remains chainable';
    ok $client->is_closed,
        'explicit close marks engine closed';
    is $client->close_reason, 'transport closed',
        'explicit close reason is retained';

    ok $transaction->is_error,
        'connection failure moves an active transaction to error state';
    is $transaction->state, 'error',
        'failed transaction exposes the error state';
    is $transaction->error, 'transport closed',
        'failed transaction preserves the connection failure reason';
}

done_testing;
