use strict;
use warnings;
use Test::More;

use Web3::Tiny::RLP qw(rlp_encode int_to_bytes);

sub hx { return unpack('H*', $_[0]) }

is(hx(rlp_encode('')), '80', 'empty string');
is(hx(rlp_encode('dog')), '83646f67', 'short string "dog"');
is(hx(rlp_encode(['cat', 'dog'])), 'c88363617483646f67', 'list ["cat","dog"]');
is(hx(rlp_encode([])), 'c0', 'empty list');
is(hx(rlp_encode(chr(0x7f))), '7f', 'single byte < 0x80 is its own encoding');
is(hx(rlp_encode(chr(0x80))), '8180', 'single byte >= 0x80 gets length prefix');
is(hx(rlp_encode([[], [[]], [[], [[]]]])), 'c7c0c1c0c3c0c1c0', 'nested list (Ethereum wiki example)');

is(hx(rlp_encode(int_to_bytes(0))), '80', 'integer 0 encodes as empty string');
is(hx(rlp_encode(int_to_bytes(15))), '0f', 'integer 15');
is(hx(rlp_encode(int_to_bytes(1024))), '820400', 'integer 1024');

my $long = 'a' x 56;
is(hx(rlp_encode($long)), 'b838' . ('61' x 56), 'long string (>55 bytes) length-of-length prefix');

done_testing;
