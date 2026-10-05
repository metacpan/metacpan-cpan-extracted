use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until pump_until_idle);
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
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
    my $active;
    my $complete = 0;
    my @errors;

    my $server = Unblock::HTTP2::Server->new(
        on_request => sub {
            my ($stream, $request) = @_;
            $active = $stream;
        },
        on_error => sub {
            my ($stream, $error) = @_;
            push @errors, "server: $error";
        },
    );

    my $client = Unblock::HTTP2::Client->new;

    my $stream = $client->request(
        request_for('/existing'),
        on_complete => sub { $complete = 1 },
        on_error => sub {
            my ($stream, $error) = @_;
            push @errors, "client: $error";
        },
    );

    pump_until($client, $server, sub { $active });

    is $server->drain, $server,
        'server drain is chainable';
    ok $server->draining,
        'server enters draining state after sending GOAWAY';

    pump_until_idle($client, $server);

    ok $client->draining,
        'client enters draining state after receiving server GOAWAY';

    is_deeply(
        $client->peer_goaway,
        {
            last_stream_id => $stream->stream_id,
            error_code     => 0,
            debug_data     => '',
        },
        'client retains the complete peer GOAWAY boundary',
    );

    ok !$client->can_open_transaction,
        'client refuses new streams after GOAWAY';

    my $ok = eval {
        $client->request(request_for('/new'));
        1;
    };
    ok !$ok,
        'request() refuses a new stream while connection drains';
    like $@, qr/cannot accept another transaction/,
        'new-stream refusal is explicit';

    $active->respond(
        Uniform::HTTP::Response->new(
            status => 200,
            body   => 'finished',
        ),
    );

    pump_until($client, $server, sub { $complete });

    ok $stream->is_complete,
        'stream accepted before GOAWAY can complete normally';
    is_deeply \@errors, [],
        'graceful server drain reports no errors';
}

{
    my $server = Unblock::HTTP2::Server->new;
    my $client = Unblock::HTTP2::Client->new;

    pump_until_idle($client, $server);

    is $client->drain, $client,
        'client drain is chainable';
    ok $client->draining,
        'client enters local draining state';

    pump_until_idle($client, $server);

    ok $server->draining,
        'server observes peer GOAWAY';
    is_deeply(
        $server->peer_goaway,
        {
            last_stream_id => 0,
            error_code     => 0,
            debug_data     => '',
        },
        'server retains peer GOAWAY details',
    );
    ok !$client->can_open_transaction,
        'locally draining client cannot open a request stream';
}

done_testing;
