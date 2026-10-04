use strict;
use warnings;

use Test2::V0;

use Unblock::HTTP3::_Native;

like(
    Unblock::HTTP3::_Native::nghttp3_version(),
    qr/\A[0-9]+\.[0-9]+\.[0-9]+/,
    'linked libnghttp3 reports a version',
);

my $client = Unblock::HTTP3::_Native->client;
isa_ok($client, ['Unblock::HTTP3::_Native::Connection']);
is($client->role, 'client', 'native client state exists');

my $server = Unblock::HTTP3::_Native->server;
isa_ok($server, ['Unblock::HTTP3::_Native::Connection']);
is($server->role, 'server', 'native server state exists');

my $shutdown_server = Unblock::HTTP3::_Native->server;
my $shutdown_client = Unblock::HTTP3::_Native->client;

$shutdown_server->bind_streams(3, 7, 11);
$shutdown_client->bind_streams(2, 6, 10);

$shutdown_server->submit_shutdown_notice;

my %shutdown_wire;

for (1 .. 32) {
    my $out = $shutdown_server->next_write;
    last unless defined $out;

    my ($stream_id, $bytes, $fin) = @$out;
    $shutdown_wire{$stream_id} .= $bytes;

    $shutdown_server->add_write_offset(
        $stream_id,
        length($bytes),
    );
}

ok(
    defined($shutdown_wire{3}) && length($shutdown_wire{3}),
    'shutdown notice produces server control-stream bytes',
);

my $shutdown_read = $shutdown_client->read_stream(
    3,
    $shutdown_wire{3},
    0,
    1,
);

is(scalar(@$shutdown_read), 1,
    'client accepts server control stream with shutdown notice');

my $shutdown_event;

while (my $event = $shutdown_client->next_event) {
    if ($event->[0] eq 'shutdown') {
        $shutdown_event = $event;
        last;
    }
}

ok(defined($shutdown_event),
    'client receives remote HTTP/3 shutdown event');
ok($shutdown_event->[1] > 1_000_000,
    'initial graceful shutdown uses the special large shutdown ID');

$shutdown_server->begin_shutdown;

my $final_control = '';

for (1 .. 32) {
    my $out = $shutdown_server->next_write;
    last unless defined $out;

    my ($stream_id, $bytes, $fin) = @$out;
    $final_control .= $bytes if $stream_id == 3;

    $shutdown_server->add_write_offset(
        $stream_id,
        length($bytes),
    );
}

ok(length($final_control),
    'final graceful shutdown produces another control-stream GOAWAY');

ok($shutdown_server->is_drained,
    'server is drained after final GOAWAY is accepted');

my $final_shutdown_read = $shutdown_client->read_stream(
    3,
    $final_control,
    0,
    2,
);

is(scalar(@$final_shutdown_read), 1,
    'client accepts final graceful shutdown control bytes');

my $final_shutdown_event;

while (my $event = $shutdown_client->next_event) {
    if ($event->[0] eq 'shutdown') {
        $final_shutdown_event = $event;
        last;
    }
}

ok(defined($final_shutdown_event),
    'client receives final HTTP/3 shutdown event');
is($final_shutdown_event->[1], 0,
    'server with no request streams sends final GOAWAY ID zero');

my $parser = Unblock::HTTP3::_Native->server;

my $settings = $parser->read_stream(
    2,
    "\x00\x04\x00",
    0,
    1,
);

is(scalar(@$settings), 1,
    'valid peer control SETTINGS input succeeds');
ok($settings->[0] >= 0,
    'valid peer control input reports consumed bytes');

my $bad_datagram_settings = Unblock::HTTP3::_Native->server;

my $invalid_datagram_setting = $bad_datagram_settings->read_stream(
    2,
    "\x00\x04\x02\x33\x02",
    0,
    2,
);

is(scalar(@$invalid_datagram_setting), 4,
    'invalid SETTINGS_H3_DATAGRAM returns native error details');
is($invalid_datagram_setting->[2], 0x0109,
    'SETTINGS_H3_DATAGRAM value above one maps to H3_SETTINGS_ERROR');

my $fatal = $parser->read_stream(
    0,
    "\x04\x00",
    1,
    2,
);

is(scalar(@$fatal), 4,
    'fatal HTTP/3 parser result includes error details');
ok(!defined($fatal->[0]),
    'fatal HTTP/3 parser result has no consumed byte count');
ok($fatal->[1] < 0,
    'fatal HTTP/3 parser result includes libnghttp3 error');
is($fatal->[2], 0x0105,
    'unexpected request-stream SETTINGS maps to H3_FRAME_UNEXPECTED');
like($fatal->[3], qr/frame/i,
    'fatal HTTP/3 parser result includes readable error text');

like(
    dies { $parser->role },
    qr/no longer usable/,
    'native connection rejects API use after fatal parse error',
);

done_testing;