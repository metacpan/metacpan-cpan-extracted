use strict;
use warnings;
use Test::More;
use Compress::Raw::Zlib 2.017 qw(Z_BUF_ERROR Z_OK);

use Unblock::WebSocket::_Deflate;

my $codec = Unblock::WebSocket::_Deflate->new(
    role             => 'client',
    config           => {},
    max_message_size => 1024,
);

my $hello = $codec->compress('Hello');
is(
    unpack('H*', $hello),
    'f248cdc9c90700',
    'raw permessage-deflate output matches RFC 7692 Hello example',
);
is($codec->decompress($hello), 'Hello',
    'RFC example payload decompresses');

my $context = Unblock::WebSocket::_Deflate->new(
    role             => 'client',
    config           => {},
    max_message_size => 1024,
);
my $first = $context->compress('HelloHelloHello');
my $second = $context->compress('HelloHelloHello');
cmp_ok(length($second), '<', length($first),
    'context takeover reuses compression history');

my $no_context = Unblock::WebSocket::_Deflate->new(
    role => 'client',
    config => {
        client_no_context_takeover => 1,
    },
    max_message_size => 1024,
);
my $fresh1 = $no_context->compress('HelloHelloHello');
my $fresh2 = $no_context->compress('HelloHelloHello');
is($fresh2, $fresh1,
    'client_no_context_takeover starts each message with empty history');

my $sender = Unblock::WebSocket::_Deflate->new(
    role             => 'client',
    config           => {},
    max_message_size => 4096,
);
my $bomb = $sender->compress('A' x 1000);
my $limited = Unblock::WebSocket::_Deflate->new(
    role             => 'server',
    config           => {},
    max_message_size => 32,
);

my $ok = eval { $limited->decompress($bomb); 1 };
ok(!$ok, 'decompressed message limit rejects compression bomb');
like($@, qr/exceeds configured limit/i,
    'compression bomb reports configured message limit');

my $eight_bit = Unblock::WebSocket::_Deflate->new(
    role => 'client',
    config => {
        client_max_window_bits => 8,
    },
    max_message_size => 4096,
);
my $eight_wire = $eight_bit->compress('abcdef' x 200);

my ($inflate8, $inflate_status) = Compress::Raw::Zlib::Inflate->new(
    -WindowBits => -8,
);
ok($inflate8 && $inflate_status == Z_OK,
    'peer 8-bit raw inflater initializes');

my $eight_input = $eight_wire . "\x00\x00\xff\xff";
my $eight_output = '';
my $eight_status = $inflate8->inflate(
    $eight_input,
    $eight_output,
    1,
);
ok($eight_status == Z_OK || $eight_status == Z_BUF_ERROR,
    '8-bit constrained peer accepts compressed stream');
is($eight_output, 'abcdef' x 200,
    '8-bit compressor fallback round-trips through 8-bit peer window');


my $client_in8 = Unblock::WebSocket::_Deflate->new(
    role => 'client',
    config => {
        server_max_window_bits => 8,
    },
    max_message_size => 4096,
);
is($client_in8->{in_bits}, 8,
    'incoming server window is configured directionally for client');

my $server_in9 = Unblock::WebSocket::_Deflate->new(
    role => 'server',
    config => {
        client_max_window_bits => 9,
    },
    max_message_size => 4096,
);
is($server_in9->{in_bits}, 9,
    'incoming client window is configured directionally for server');

my $server_out8 = Unblock::WebSocket::_Deflate->new(
    role => 'server',
    config => {
        server_max_window_bits => 8,
    },
    max_message_size => 4096,
);
my $server_wire8 = $server_out8->compress('directional window ' x 40);
is(
    $client_in8->decompress($server_wire8),
    'directional window ' x 40,
    '8-bit negotiated incoming window round-trips through configured inflater',
);

done_testing;
