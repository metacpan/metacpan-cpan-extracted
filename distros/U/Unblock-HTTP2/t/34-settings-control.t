use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until_idle);
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

my @client_settings;
my @server_settings;
my @client_acks;
my @server_acks;

my $server = Unblock::HTTP2::Server->new(
    settings => {
        header_table_size   => 2_048,
        initial_window_size => 4_096,
    },

    on_settings => sub {
        my ($engine, $peer, $changed) = @_;
        push @server_settings, [ $peer, $changed ];
    },

    on_settings_ack => sub {
        my ($engine, $acked) = @_;
        push @server_acks, $acked;
    },
);

my $client = Unblock::HTTP2::Client->new(
    settings => {
        header_table_size   => 1_024,
        initial_window_size => 8_192,
    },

    on_settings => sub {
        my ($engine, $peer, $changed) = @_;
        push @client_settings, [ $peer, $changed ];
    },

    on_settings_ack => sub {
        my ($engine, $acked) = @_;
        push @client_acks, $acked;
    },
);

is $client->settings_pending, 1,
    'client initial SETTINGS waits for acknowledgement';
is $server->settings_pending, 1,
    'server initial SETTINGS waits for acknowledgement';

is $client->local_setting('enable_push'), 0,
    'client advertises server push disabled';
is $server->local_setting('enable_connect_protocol'), 1,
    'server advertises Extended CONNECT enabled';
is $client->local_setting('initial_window_size'), 8_192,
    'client initial SETTINGS accept public constructor overrides';
is $server->local_setting('initial_window_size'), 4_096,
    'server initial SETTINGS accept public constructor overrides';

pump_until_idle($client, $server);

is $client->settings_pending, 0,
    'client initial SETTINGS is acknowledged';
is $server->settings_pending, 0,
    'server initial SETTINGS is acknowledged';

is $client->peer_setting('initial_window_size'), 4_096,
    'client exposes effective peer initial window';
is $server->peer_setting('initial_window_size'), 8_192,
    'server exposes effective peer initial window';
is $client->peer_setting('header_table_size'), 2_048,
    'client exposes effective peer header-table size';
is $server->peer_setting('header_table_size'), 1_024,
    'server exposes effective peer header-table size';

ok @client_settings >= 1,
    'client receives peer SETTINGS notifications';
ok @server_settings >= 1,
    'server receives peer SETTINGS notifications';
ok @client_acks >= 1,
    'client receives SETTINGS acknowledgement notifications';
ok @server_acks >= 1,
    'server receives SETTINGS acknowledgement notifications';

is $client_settings[-1][1]{initial_window_size}, 4_096,
    'client SETTINGS event reports changed peer values';
is $server_settings[-1][1]{initial_window_size}, 8_192,
    'server SETTINGS event reports changed peer values';
is $client_acks[-1]{initial_window_size}, 8_192,
    'client ACK event identifies the submitted SETTINGS frame';
is $server_acks[-1]{initial_window_size}, 4_096,
    'server ACK event identifies the submitted SETTINGS frame';

my $snapshot = $client->peer_settings;
$snapshot->{initial_window_size} = 1;
is $client->peer_setting('initial_window_size'), 4_096,
    'peer_settings returns a read-only-by-copy protocol snapshot';

$server->update_settings(
    initial_window_size    => 2_048,
    max_concurrent_streams => 3,
);

is $server->settings_pending, 1,
    'later server SETTINGS is tracked until ACK';

pump_until_idle($client, $server);

is $server->settings_pending, 0,
    'later server SETTINGS is acknowledged';
is $client->peer_setting('initial_window_size'), 2_048,
    'peer effective SETTINGS update after connection startup';
is $client->peer_setting('max_concurrent_streams'), 3,
    'later concurrency SETTINGS is visible through public API';
is $client_settings[-1][1]{initial_window_size}, 2_048,
    'later SETTINGS notification reports initial-window change';
is $client_settings[-1][1]{max_concurrent_streams}, 3,
    'later SETTINGS notification reports concurrency change';
is $server_acks[-1]{initial_window_size}, 2_048,
    'later ACK identifies the server SETTINGS values';

$client->update_settings({
    header_table_size => 512,
});
pump_until_idle($client, $server);

is $server->peer_setting('header_table_size'), 512,
    'hash-reference update_settings form works';
is $server_settings[-1][1]{header_table_size}, 512,
    'server receives later client SETTINGS notification';

my $ok = eval {
    $client->update_settings(enable_push => 1);
    1;
};
ok !$ok, 'client cannot enable unsupported server push';
like $@, qr/enable_push=1.*unsupported/i,
    'push refusal explains the public capability limit';

$ok = eval {
    $server->update_settings(enable_push => 1);
    1;
};
ok !$ok, 'server rejects forbidden ENABLE_PUSH value one';
like $@, qr/server.*enable_push/i,
    'server push-setting validation is explicit';

$ok = eval {
    $server->update_settings(enable_push => 0);
    1;
};
ok !$ok, 'server rejects ENABLE_PUSH even when value is zero';
like $@, qr/server.*must not send enable_push/i,
    'ENABLE_PUSH is enforced as a client-only setting';

$ok = eval {
    $server->update_settings(max_frame_size => 16_383);
    1;
};
ok !$ok, 'SETTINGS_MAX_FRAME_SIZE lower bound is validated';
like $@, qr/max_frame_size.*16384.*16777215/i,
    'frame-size validation reports the HTTP/2 range';

$ok = eval {
    $server->update_settings(initial_window_size => 2_147_483_648);
    1;
};
ok !$ok, 'SETTINGS_INITIAL_WINDOW_SIZE upper bound is validated';
like $@, qr/initial_window_size.*maximum/i,
    'window-size validation reports the HTTP/2 maximum';

$ok = eval {
    $server->update_settings(unknown_setting => 1);
    1;
};
ok !$ok, 'unknown public SETTINGS names are rejected';
like $@, qr/unknown setting/i,
    'unknown-setting failure is explicit';

$ok = eval {
    $server->update_settings(enable_connect_protocol => 0);
    1;
};
ok !$ok,
    'ENABLE_CONNECT_PROTOCOL cannot return to zero after being advertised as one';
like $@, qr/enable_connect_protocol.*cannot return to zero/i,
    'Extended CONNECT SETTINGS monotonicity is enforced';

done_testing;
