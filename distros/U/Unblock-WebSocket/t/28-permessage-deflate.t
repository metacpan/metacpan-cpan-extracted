use strict;
use warnings;
use Test::More;

use Unblock::WebSocket;
use Unblock::WebSocket::Client;
use Unblock::WebSocket::Server;
use Unblock::WebSocket::_Deflate;
use Unblock::WebSocket::_Frame;

sub close_code_from_wire {
    my ($wire) = @_;
    my $parser = Unblock::WebSocket::_Frame->new_parser(
        expect_masked  => 0,
        max_frame_size => 4096,
    );
    $parser->input($wire);
    while (my $frame = $parser->next_frame) {
        next unless $frame->{opcode} == 8;
        return unpack('n', substr($frame->{payload}, 0, 2))
            if length($frame->{payload}) >= 2;
    }
    return;
}

my @server_message;
my @client_message;

my $client = Unblock::WebSocket::Client->new(
    permessage_deflate => {},
    random_bytes => sub { "\x01\x02\x03\x04" },
    on_message => sub {
        my ($ws, $payload, $type) = @_;
        push @client_message, [ $payload, $type ];
    },
);

my $server = Unblock::WebSocket::Server->new(
    permessage_deflate => {},
    on_message => sub {
        my ($ws, $payload, $type) = @_;
        push @server_message, [ $payload, $type ];
    },
);

is($client->backend, 'perl',
    'deterministic random source keeps client on portable backend');
is_deeply($client->permessage_deflate, {},
    'client exposes negotiated compression config');

$client->send_text('compress me ' x 20);
my $client_wire = $client->output;

my $wire_parser = Unblock::WebSocket::_Frame->new_parser(
    expect_masked  => 1,
    max_frame_size => 4096,
    allow_rsv1     => 1,
);
$wire_parser->input($client_wire);
my $compressed_text = $wire_parser->next_frame;
ok($compressed_text->{rsv1},
    'compressed outgoing text sets RSV1');
is($compressed_text->{opcode}, 1,
    'compressed outgoing text retains text opcode');

$server->input($client_wire);
is_deeply(
    \@server_message,
    [ [ 'compress me ' x 20, 'text' ] ],
    'server receives decompressed text message',
);

$server->send_binary("\x00\x01\x02" x 50);
$client->input($server->output);
is_deeply(
    \@client_message,
    [ [ "\x00\x01\x02" x 50, 'binary' ] ],
    'client receives decompressed binary message',
);

$client->ping('probe');
my $ping_wire = $client->output;
$wire_parser = Unblock::WebSocket::_Frame->new_parser(
    expect_masked  => 1,
    max_frame_size => 125,
    allow_rsv1     => 1,
);
$wire_parser->input($ping_wire);
my $ping = $wire_parser->next_frame;
ok(!$ping->{rsv1}, 'control frames are never compressed');
is($ping->{opcode}, 9, 'control frame remains Ping');

{
    my @message;
    my $fragment_server = Unblock::WebSocket::Server->new(
        permessage_deflate => {},
        on_message => sub {
            my ($ws, $payload, $type) = @_;
            push @message, [ $payload, $type ];
        },
    );

    my $compressor = Unblock::WebSocket::_Deflate->new(
        role             => 'client',
        config           => {},
        max_message_size => 4096,
    );
    my $compressed = $compressor->compress('fragmented text ' x 20);
    my $cut = int(length($compressed) / 2);

    my $first = Unblock::WebSocket::_Frame->encode(
        opcode   => 1,
        payload  => substr($compressed, 0, $cut),
        fin      => 0,
        rsv1     => 1,
        masked   => 1,
        mask_key => "\x05\x06\x07\x08",
    );
    my $last = Unblock::WebSocket::_Frame->encode(
        opcode   => 0,
        payload  => substr($compressed, $cut),
        fin      => 1,
        masked   => 1,
        mask_key => "\x09\x0a\x0b\x0c",
    );

    $fragment_server->input($first . $last);
    is_deeply(
        \@message,
        [ [ 'fragmented text ' x 20, 'text' ] ],
        'compressed fragmented message is reassembled then decompressed',
    );
}

{
    my @error;
    my $plain = Unblock::WebSocket::Server->new(
        backend => 'perl',
        on_error => sub { push @error, $_[1] },
    );
    my $wire = Unblock::WebSocket::_Frame->encode(
        opcode   => 1,
        payload  => 'not negotiated',
        rsv1     => 1,
        masked   => 1,
        mask_key => "\x01\x02\x03\x04",
    );
    $plain->input($wire);
    like($error[0] || '', qr/RSV1|reserved/i,
        'unnegotiated RSV1 is a protocol error');
    is(close_code_from_wire($plain->output), 1002,
        'unnegotiated RSV1 sends Close 1002');
}

{
    my @error;
    my $limited_server = Unblock::WebSocket::Server->new(
        permessage_deflate => {},
        max_message_size   => 16,
        on_error => sub { push @error, $_[1] },
    );
    my $compressor = Unblock::WebSocket::_Deflate->new(
        role             => 'client',
        config           => {},
        max_message_size => 4096,
    );
    my $compressed = $compressor->compress('A' x 500);
    my $wire = Unblock::WebSocket::_Frame->encode(
        opcode   => 2,
        payload  => $compressed,
        rsv1     => 1,
        masked   => 1,
        mask_key => "\x01\x02\x03\x04",
    );
    $limited_server->input($wire);
    like($error[0] || '', qr/exceeds configured limit/i,
        'decompressed message limit reports error');
    is(close_code_from_wire($limited_server->output), 1009,
        'decompressed message limit sends Close 1009');
}

SKIP: {
    skip 'native engine is not available', 5
        unless Unblock::WebSocket->native_available;

    my @message;
    my $native_client = Unblock::WebSocket::Client->new(
        backend            => 'native',
        permessage_deflate => {},
    );
    my $portable_server = Unblock::WebSocket::Server->new(
        backend            => 'perl',
        permessage_deflate => {},
        on_message => sub {
            my ($ws, $payload, $type) = @_;
            push @message, [ $payload, $type ];
        },
    );

    is($native_client->backend, 'native',
        'compressed client can retain native framing backend');

    $native_client->send_text('native compressed path ' x 20);
    my $wire = $native_client->output;

    my $parser = Unblock::WebSocket::_Frame->new_parser(
        expect_masked  => 1,
        max_frame_size => 4096,
        allow_rsv1     => 1,
    );
    $parser->input($wire);
    my $frame = $parser->next_frame;
    ok($frame->{rsv1}, 'native compressed send emits RSV1');
    is($frame->{opcode}, 1, 'native compressed send retains text opcode');

    $portable_server->input($wire);
    is_deeply(
        \@message,
        [ [ 'native compressed path ' x 20, 'text' ] ],
        'portable peer decompresses native-framed compressed message',
    );

    is($server->backend, 'native',
        'server side of mixed round-trip used native compressed framing');
}

done_testing;
