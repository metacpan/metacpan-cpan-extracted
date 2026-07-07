use strict;
use warnings;
use Test::More;

use Web3::Tiny::Util qw(to_wei from_wei hex_to_bigint bigint_to_hex);

is(to_wei('1.5', 'ether'), '1500000000000000000', 'to_wei 1.5 ether');
is(to_wei('1', 'ether'), '1000000000000000000', 'to_wei 1 ether');
is(to_wei('100', 'gwei'), '100000000000', 'to_wei 100 gwei');
is(to_wei('0.000000000000000001', 'ether'), '1', 'to_wei smallest unit');

is(from_wei('1500000000000000000'), '1.5', 'from_wei 1.5 ether default unit');
is(from_wei('1000000000000000000'), '1', 'from_wei 1 ether, no trailing zeros');
is(from_wei('100000000000', 'gwei'), '100', 'from_wei 100 gwei');

is(hex_to_bigint('0x1a'), 26, 'hex_to_bigint');
is(bigint_to_hex(26), '0x1a', 'bigint_to_hex');

done_testing;
