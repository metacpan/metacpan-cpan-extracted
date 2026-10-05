use strict;
use warnings;

use Test2::V0;

use Uniform::HTTP::Request;
use Unblock::HTTP3::Transaction;
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

is(
    Unblock::HTTP3::Transaction::_parse_priority_field(undef),
    {
        urgency     => 3,
        incremental => 0,
    },
    'missing Priority field uses RFC 9218 defaults',
);

is(
    Unblock::HTTP3::Transaction::_parse_priority_field('u=5, i'),
    {
        urgency     => 5,
        incremental => 1,
    },
    'Transaction parses a normal Uniform Priority field',
);

is(
    Unblock::HTTP3::Transaction::_parse_priority_field(
        'not a structured priority value',
    ),
    {
        urgency     => 3,
        incremental => 0,
    },
    'malformed Priority field falls back to RFC defaults',
);

is(
    Unblock::HTTP3::Transaction::_priority_field({
        urgency     => 1,
        incremental => 1,
    }),
    'u=1, i',
    'Transaction formats incremental priority for PRIORITY_UPDATE',
);

is(
    Unblock::HTTP3::Transaction::_priority_field({
        urgency     => 6,
        incremental => 0,
    }),
    'u=6',
    'Transaction omits false incremental flag',
);

is(
    Unblock::HTTP3::Transaction::_priority_from_args(
        {
            urgency     => 1,
            incremental => 1,
        },
        urgency => 6,
    ),
    {
        urgency     => 6,
        incremental => 1,
    },
    'partial Transaction priority update preserves the other value',
);

like(
    dies {
        Unblock::HTTP3::Transaction::_priority_from_args(
            {},
            urgency => 8,
        );
    },
    qr/urgency must be an integer from 0 through 7/,
    'urgency above 7 is rejected',
);

like(
    dies {
        Unblock::HTTP3::Transaction::_priority_from_args(
            {},
            incremental => 2,
        );
    },
    qr/incremental must be 0 or 1/,
    'incremental value must be boolean',
);

like(
    dies {
        Unblock::HTTP3::Transaction::_priority_from_args(
            {},
            weight => 10,
        );
    },
    qr/unknown priority option: weight/,
    'unknown priority option is rejected',
);

my $request = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/priority',
    scheme    => 'https',
    authority => 'example.com',
    headers   => [
        [ Priority => 'u=1, i' ],
    ],
);

is($request->header('priority'), 'u=1, i',
    'initial priority is represented by the canonical Uniform header');

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
