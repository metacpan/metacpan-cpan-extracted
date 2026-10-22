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

my $retained_client = Unblock::HTTP3::_Native->client;
my $retained_server = Unblock::HTTP3::_Native->server;

$retained_client->bind_streams(2, 6, 10);
$retained_server->bind_streams(3, 7, 11);
$retained_server->set_max_client_streams_bidi(100);

$retained_client->submit_request(
    0,
    [
        [ ':method',    'POST' ],
        [ ':scheme',    'https' ],
        [ ':authority', 'example.test' ],
        [ ':path',      '/retained-body' ],
    ],
    undef,
    1,
);

my %retained_offset;
my $retained_timestamp = 10;

my $transfer_retained = sub {
    while (my $out = $retained_client->next_write) {
        my ($stream_id, $bytes, $fin) = @$out;

        my $read = $retained_server->read_stream(
            $stream_id,
            $bytes,
            $fin ? 1 : 0,
            $retained_timestamp++,
        );

        is(
            scalar(@$read),
            1,
            "retained-body peer accepts stream $stream_id",
        );

        ok(
            $read->[0] >= 0
                && $read->[0] <= length($bytes),
            "retained-body peer accepts immediate or deferred stream consumption",
        );

        $retained_offset{$stream_id} += length($bytes);

        $retained_client->add_write_offset(
            $stream_id,
            length($bytes),
        );
    }

    return;
};

$transfer_retained->();

my $retained_body = 'original-retained-body';
is(
    $retained_client->append_body(
        0,
        $retained_body,
        0,
    ),
    length('original-retained-body'),
    'native streaming append retains the complete chunk',
);

$retained_body = 'mutated-after-append';

is(
    $retained_client->active_streaming_body_count,
    1,
    'native tracks one unfinished streaming producer',
);
is(
    $retained_client->streaming_retained_bytes_for_stream(0),
    length('original-retained-body'),
    'native tracks retained bytes on the owning request stream',
);
is(
    $retained_client->streaming_retained_bytes_for_stream(4),
    0,
    'native reports zero bytes for an unknown stream',
);

$transfer_retained->();

$retained_client->update_ack_offset(
    0,
    $retained_offset{0},
);

is(
    $retained_client->streaming_retained_bytes,
    0,
    'ACK releases retained Perl body storage',
);
is(
    $retained_client->streaming_retained_bytes_for_stream(0),
    0,
    'ACK also releases the owning stream retained-byte count',
);

my $retained_received = '';

while (my $event = $retained_server->next_event) {
    next unless $event->[0] eq 'data';
    next unless $event->[1] == 0;
    $retained_received .= $event->[2];
}

is(
    $retained_received,
    'original-retained-body',
    'caller mutation after append does not change retained body bytes',
);

$retained_client->append_body(0, '', 1);
$transfer_retained->();

$retained_client->close_stream(0);

# An unfinished producer can gain a sibling. Cancelling one returns only its
# storage, and EOF removes the producer from fair-share accounting without
# pretending the unacknowledged bytes have been released.
my $joining = Unblock::HTTP3::_Native->client;
$joining->bind_streams(2, 6, 10);
my $submit_joining = sub {
    my ($id) = @_;
    $joining->submit_request(
        $id,
        [
            [ ':method', 'POST' ],
            [ ':scheme', 'https' ],
            [ ':authority', 'example.test' ],
            [ ':path', "/joined-$id" ],
        ],
        undef,
        1,
    );
};
$submit_joining->(0);
is($joining->active_streaming_body_count, 1,
    'first unfinished producer participates in send budget');
$joining->append_body(0, 'a' x 4096, 0);
is($joining->streaming_retained_bytes_for_stream(0), 4096,
    'first producer retains unacknowledged bytes');

$submit_joining->(4);
is($joining->active_streaming_body_count, 2,
    'new stream joins while first producer retains bytes');
$joining->append_body(4, 'b' x 2048, 0);
is($joining->streaming_retained_bytes, 6144,
    'connection aggregate includes both producers');
is($joining->streaming_retained_bytes_for_stream(4), 2048,
    'joined producer retains its own bytes');

$joining->discard_body(0);
is($joining->streaming_retained_bytes_for_stream(0), 0,
    'cancelled producer discards its retained storage');
is($joining->streaming_retained_bytes, 2048,
    'cancelled producer releases only its aggregate share');
is($joining->active_streaming_body_count, 1,
    'cancelled producer relinquishes active fair-share slot');

$joining->append_body(4, 'c' x 1024, 1);
is($joining->active_streaming_body_count, 0,
    'EOF removes last producer from dynamic share count');
is($joining->streaming_retained_bytes_for_stream(4), 3072,
    'EOF retains unacknowledged storage until discard');
$joining->discard_body(4);
is($joining->streaming_retained_bytes, 0,
    'discard releases remaining retained storage');
is($joining->streaming_retained_bytes_for_stream(4), 0,
    'discard zeros individual stream counter');
$joining->discard_body(4);
is($joining->streaming_retained_bytes, 0,
    'repeated discard does not underflow accounting');

done_testing;