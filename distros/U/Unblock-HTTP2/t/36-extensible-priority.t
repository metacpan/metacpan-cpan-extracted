use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until pump_until_idle);
use Uniform::HTTP::Request;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

my @priority_updates;
my $server_stream;

my $server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($stream, $request) = @_;
        $server_stream = $stream;
    },

    on_priority => sub {
        my ($engine, $stream_id, $field_value) = @_;
        push @priority_updates, [ $stream_id, $field_value ];
    },
);

my $client = Unblock::HTTP2::Client->new;

pump_until_idle($client, $server);

is $client->local_setting('no_rfc7540_priorities'), 1,
    'client advertises RFC 9218 extensible priorities';
is $server->local_setting('no_rfc7540_priorities'), 1,
    'server advertises RFC 9218 extensible priorities';
is $client->peer_setting('no_rfc7540_priorities'), 1,
    'client sees peer RFC 9218 support';
is $server->peer_setting('no_rfc7540_priorities'), 1,
    'server sees peer RFC 9218 support';

my $request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/priority',
    scheme    => 'https',
    authority => 'example.test',
    headers   => [
        [ 'priority', 'u=5' ],
    ],
);

my $stream = $client->request($request);

pump_until($client, $server, sub { $server_stream });

is $server_stream->stream_id, $stream->stream_id,
    'client and server agree on prioritized stream id';

is $stream->update_priority('u=0, i'), $stream,
    'client stream sends PRIORITY_UPDATE and remains chainable';

pump_until_idle($client, $server);

is scalar(@priority_updates), 1,
    'server observes one PRIORITY_UPDATE frame';
is $priority_updates[0][0], $stream->stream_id,
    'PRIORITY_UPDATE identifies the request stream';
is $priority_updates[0][1], 'u=0, i',
    'PRIORITY_UPDATE preserves the complete Priority field value';

my $binary_ok = eval {
    $stream->update_priority([]);
    1;
};
ok !$binary_ok, 'priority update rejects references';
like $@, qr/body must be a scalar|field value must be a scalar/i,
    'reference priority failure is explicit';

my $too_large = 'x' x 16_381;
my $large_ok = eval {
    $stream->update_priority($too_large);
    1;
};
ok !$large_ok, 'priority update enforces the HTTP/2 extension payload limit';
like $@, qr/exceeds.*limit|16380/i,
    'oversized priority failure is explicit';

my $disabled_server = Unblock::HTTP2::Server->new(
    settings => {
        no_rfc7540_priorities => 0,
    },
);

my $disabled_client = Unblock::HTTP2::Client->new;
pump_until_idle($disabled_client, $disabled_server);

is $disabled_client->peer_setting('no_rfc7540_priorities'), 0,
    'client sees peer opt-out of RFC 9218 priority updates';

my $disabled_stream = $disabled_client->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/disabled',
        scheme    => 'https',
        authority => 'example.test',
    ),
);

my $disabled_ok = eval {
    $disabled_stream->update_priority('u=1');
    1;
};
ok !$disabled_ok,
    'client refuses PRIORITY_UPDATE when peer did not enable RFC 9218';
like $@, qr/peer has not enabled RFC 9218 priorities/i,
    'peer capability refusal is explicit';

my $setting_ok = eval {
    $server->update_settings(no_rfc7540_priorities => 0);
    1;
};
ok !$setting_ok,
    'RFC 7540 priority mode cannot change after the first SETTINGS frame';
like $@, qr/no_rfc7540_priorities cannot change/i,
    'priority-mode SETTINGS immutability is enforced';

done_testing;
