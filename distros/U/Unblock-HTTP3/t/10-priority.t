use strict;
use warnings;

use Test2::V0;

use Unblock::HTTP3::Request;
use Unblock::HTTP3::_Native;

is(
    Unblock::HTTP3::_Native->parse_priority('u=2, i'),
    [ 2, 1 ],
    'libnghttp3 parses RFC 9218 urgency and incremental flag',
);

is(
    Unblock::HTTP3::_Native->parse_priority(''),
    [ 3, 0 ],
    'empty Priority value uses RFC 9218 defaults',
);

my $default = Unblock::HTTP3::Request->new(
    method    => 'GET',
    target    => '/',
    scheme    => 'https',
    authority => 'example.com',
);

is(
    $default->priority,
    {
        urgency     => 3,
        incremental => 0,
    },
    'Request priority defaults to urgency 3 and non-incremental',
);

is($default->header('priority'), undef,
    'default priority does not invent a Priority field');

my $request = Unblock::HTTP3::Request->new(
    method    => 'GET',
    target    => '/priority',
    scheme    => 'https',
    authority => 'example.com',
    priority  => {
        urgency     => 1,
        incremental => 1,
    },
);

is($request->header('priority'), 'u=1, i',
    'Request priority constructor writes normal Priority field');

is(
    $request->priority,
    {
        urgency     => 1,
        incremental => 1,
    },
    'Request priority reads the field through libnghttp3',
);

$request->priority(urgency => 6);

is(
    $request->priority,
    {
        urgency     => 6,
        incremental => 1,
    },
    'partial Request priority update preserves other value',
);

is($request->header('priority'), 'u=6, i',
    'partial Request priority update rewrites canonical field');

$request->priority(incremental => 0);

is($request->header('priority'), 'u=6',
    'false incremental flag is omitted from canonical field');

my $raw = Unblock::HTTP3::Request->new(
    method    => 'GET',
    target    => '/raw',
    scheme    => 'https',
    authority => 'example.com',
    headers   => [
        [ Priority => 'u=5, i' ],
    ],
);

is(
    $raw->priority,
    {
        urgency     => 5,
        incremental => 1,
    },
    'Request priority inspects a manually supplied Priority field',
);

my $malformed = Unblock::HTTP3::Request->new(
    method    => 'GET',
    target    => '/malformed',
    scheme    => 'https',
    authority => 'example.com',
    headers   => [
        [ Priority => 'not a structured priority value' ],
    ],
);

is(
    $malformed->priority,
    {
        urgency     => 3,
        incremental => 0,
    },
    'malformed Priority field falls back to RFC defaults',
);

like(
    dies { $request->priority(urgency => 8) },
    qr/urgency must be an integer from 0 through 7/,
    'urgency above 7 is rejected',
);

like(
    dies { $request->priority(incremental => 2) },
    qr/incremental must be 0 or 1/,
    'incremental value must be boolean',
);

like(
    dies { $request->priority(weight => 10) },
    qr/unknown priority option: weight/,
    'unknown priority option is rejected',
);

like(
    dies {
        Unblock::HTTP3::Request->new(
            method    => 'GET',
            target    => '/bad-priority',
            scheme    => 'https',
            authority => 'example.com',
            priority  => 'high',
        );
    },
    qr/priority must be a hash reference/,
    'constructor priority must be a hash reference',
);

my $native_client = Unblock::HTTP3::_Native->client;
my $native_server = Unblock::HTTP3::_Native->server;

$native_client->bind_streams(2, 6, 10);
$native_server->bind_streams(3, 7, 11);
$native_server->set_max_client_streams_bidi(100);

$native_client->submit_request(
    0,
    [
        [ ':method', 'GET' ],
        [ ':scheme', 'https' ],
        [ ':authority', 'example.com' ],
        [ ':path', '/native-priority' ],
        [ 'priority', 'u=5, i' ],
    ],
);

my %client_fin;

for (1 .. 64) {
    my $out = $native_client->next_write;
    last unless defined $out;

    my ($stream_id, $bytes, $fin) = @$out;

    my $read = $native_server->read_stream(
        $stream_id,
        $bytes,
        $fin ? 1 : 0,
        1,
    );

    is(scalar(@$read), 1,
        "native server accepts initial client stream $stream_id");
    is($read->[0], length($bytes),
        "native server consumes initial client stream $stream_id bytes");

    $native_client->add_write_offset(
        $stream_id,
        length($bytes),
    );

    $client_fin{$stream_id} = 1 if $fin;
}

is(
    $native_server->get_server_stream_priority(0),
    [ 5, 1 ],
    'native server sees initial request priority',
);

$native_client->set_client_stream_priority(
    0,
    'u=1',
);

my $priority_control_bytes = 0;

for (1 .. 32) {
    my $out = $native_client->next_write;
    last unless defined $out;

    my ($stream_id, $bytes, $fin) = @$out;
    $priority_control_bytes += length($bytes)
        if $stream_id == 2;

    my $read = $native_server->read_stream(
        $stream_id,
        $bytes,
        $fin ? 1 : 0,
        2,
    );

    is(scalar(@$read), 1,
        "native server accepts priority update stream $stream_id");

    is($read->[0], length($bytes),
        "native server consumes priority update stream $stream_id bytes");

    $native_client->add_write_offset(
        $stream_id,
        length($bytes),
    );
}

ok($priority_control_bytes > 0,
    'client priority update produces control-stream bytes');

is(
    $native_server->get_server_stream_priority(0),
    [ 1, 0 ],
    'native PRIORITY_UPDATE changes server effective priority',
);

done_testing;
