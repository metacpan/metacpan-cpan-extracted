use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until pump_until_idle);
use Uniform::HTTP::Request;
use Unblock::HTTP2;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

sub request_for {
    my ($target) = @_;
    return Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => $target,
        scheme    => 'https',
        authority => 'example.test',
    );
}

{
    my $server_stream;

    my $server = Unblock::HTTP2::Server->new(
        on_request => sub {
            my ($stream, $request) = @_;
            $server_stream = $stream;
        },
    );
    my $client = Unblock::HTTP2::Client->new;

    my $stream = $client->request(request_for('/goaway'));
    pump_until($client, $server, sub { $server_stream });

    is $server->goaway(
        error_code => Unblock::HTTP2::ENHANCE_YOUR_CALM(),
        debug_data => 'busy',
    ), $server, 'server goaway is chainable';

    ok $server->draining,
        'explicit GOAWAY puts server into draining state';

    is_deeply(
        $server->local_goaway,
        {
            last_stream_id => $stream->stream_id,
            error_code     => Unblock::HTTP2::ENHANCE_YOUR_CALM(),
            debug_data     => 'busy',
        },
        'server retains the submitted GOAWAY facts',
    );

    pump_until_idle($client, $server);

    is_deeply(
        $client->peer_goaway,
        {
            last_stream_id => $stream->stream_id,
            error_code     => Unblock::HTTP2::ENHANCE_YOUR_CALM(),
            debug_data     => 'busy',
        },
        'client receives explicit server GOAWAY details',
    );

    is $server->goaway(
        last_stream_id => 0,
        error_code     => Unblock::HTTP2::NO_ERROR(),
        debug_data     => 'final',
    ), $server, 'server can narrow the GOAWAY boundary';

    pump_until_idle($client, $server);

    is_deeply(
        $client->peer_goaway,
        {
            last_stream_id => 0,
            error_code     => Unblock::HTTP2::NO_ERROR(),
            debug_data     => 'final',
        },
        'later GOAWAY can lower last_stream_id',
    );

    my $increase_ok = eval {
        $server->goaway(last_stream_id => $stream->stream_id);
        1;
    };
    ok !$increase_ok,
        'successive local GOAWAY cannot increase last_stream_id';
    like $@, qr/cannot increase/,
        'GOAWAY boundary violation is explicit';
}

{
    my $server = Unblock::HTTP2::Server->new;
    my $client = Unblock::HTTP2::Client->new;

    pump_until_idle($client, $server);

    my $debug = "\x00binary\xff";
    is $client->goaway(
        error_code => Unblock::HTTP2::PROTOCOL_ERROR(),
        debug_data => $debug,
    ), $client, 'client can send explicit GOAWAY';

    is_deeply(
        $client->local_goaway,
        {
            last_stream_id => 0,
            error_code     => Unblock::HTTP2::PROTOCOL_ERROR(),
            debug_data     => $debug,
        },
        'client retains binary GOAWAY debug data',
    );

    pump_until_idle($client, $server);

    is_deeply(
        $server->peer_goaway,
        {
            last_stream_id => 0,
            error_code     => Unblock::HTTP2::PROTOCOL_ERROR(),
            debug_data     => $debug,
        },
        'server receives client GOAWAY error and binary debug data',
    );
}

{
    my $server = Unblock::HTTP2::Server->new;
    my $client = Unblock::HTTP2::Client->new;

    pump_until_idle($client, $server);

    for my $case (
        [ error_code => -1 ],
        [ error_code => 4_294_967_296 ],
        [ last_stream_id => -1 ],
        [ last_stream_id => 2_147_483_648 ],
        [ debug_data => [] ],
    ) {
        my $ok = eval {
            $client->goaway(@$case);
            1;
        };
        ok !$ok, 'invalid GOAWAY argument is rejected';
    }
}

done_testing;
