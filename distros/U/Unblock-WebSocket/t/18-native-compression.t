use strict;
use warnings;
use Test::More;

use Unblock::WebSocket;
use Unblock::WebSocket::_Deflate;
use Unblock::WebSocket::_Frame;

plan skip_all => 'native engine is not available'
    unless Unblock::WebSocket->native_available;

require Unblock::WebSocket::_Native;

my $compressor = Unblock::WebSocket::_Deflate->new(
    role             => 'client',
    config           => {},
    max_message_size => 4096,
);

my $compressed = $compressor->compress('native event flag ' x 20);

my $server = Unblock::WebSocket::_Native->new(
    'server',
    8192,
    1,
);

my $wire = Unblock::WebSocket::_Frame->encode(
    opcode   => 1,
    payload  => $compressed,
    rsv1     => 1,
    masked   => 1,
    mask_key => "\x01\x02\x03\x04",
);

my $events = $server->feed($wire);
is scalar(@$events), 1, 'native parser emits one compressed event';
is $events->[0][0], 1, 'compressed event retains text opcode';
is $events->[0][1], $compressed, 'native event payload remains compressed bytes';
is $events->[0][2] & 0x01, 0x01, 'native event carries compressed flag';

my $client = Unblock::WebSocket::_Native->new(
    'client',
    8192,
    1,
);
$client->queue_message(2, $compressed, 1);
my $native_wire = $client->flush;

my $parser = Unblock::WebSocket::_Frame->new_parser(
    expect_masked  => 1,
    max_frame_size => 8192,
    allow_rsv1     => 1,
);
$parser->input($native_wire);
my $frame = $parser->next_frame;

ok $frame->{rsv1}, 'native compressed send sets RSV1';
is $frame->{opcode}, 2, 'native compressed send retains binary opcode';
is $frame->{payload}, $compressed, 'native compressed send preserves payload bytes';

my $plain = Unblock::WebSocket::_Native->new('server', 8192);
$events = $plain->feed($wire);
is_deeply $events, [], 'native parser without extension exposes no compressed event';
is $plain->_error_string, 'RESERVED_BIT',
    'native parser without extension rejects RSV1';

done_testing;
