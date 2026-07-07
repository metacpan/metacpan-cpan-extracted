use strict;
use warnings;
use Test::More;

use Web3::Tiny::ABI qw(selector encode_call encode_types decode_types decode_result);

sub hx { return unpack('H*', $_[0]) }

is(hx(selector('transfer(address,uint256)')), 'a9059cbb', 'transfer selector');
is(hx(selector('balanceOf(address)')), '70a08231', 'balanceOf selector');

# classic web3.js tutorial calldata
my $call = encode_call('transfer(address,uint256)', '0x5B38Da6a701c568545dCfcB03FcB875f56beddC4', 100);
is(hx($call),
    'a9059cbb0000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4'
  . '0000000000000000000000000000000000000000000000000000000000000064',
    'encode_call matches known-good transfer(address,uint256) calldata');

# the canonical Solidity ABI spec worked example:
# f(uint256,uint32[],bytes10,bytes) with (0x123, [0x456,0x789], "1234567890", "Hello, world!")
my $types = ['uint256', 'uint32[]', 'bytes10', 'bytes'];
my $args  = [0x123, [0x456, 0x789], '1234567890', 'Hello, world!'];
my $enc   = encode_types($types, $args);
is(hx($enc),
      '0000000000000000000000000000000000000000000000000000000000000123'
    . '0000000000000000000000000000000000000000000000000000000000000080'
    . '3132333435363738393000000000000000000000000000000000000000000000'
    . '00000000000000000000000000000000000000000000000000000000000000e0'
    . '0000000000000000000000000000000000000000000000000000000000000002'
    . '0000000000000000000000000000000000000000000000000000000000000456'
    . '0000000000000000000000000000000000000000000000000000000000000789'
    . '000000000000000000000000000000000000000000000000000000000000000d'
    . '48656c6c6f2c20776f726c642100000000000000000000000000000000000000',
    'encode_types matches the Solidity ABI spec worked example');

my @decoded = decode_types($types, $enc);
is($decoded[0], 291, 'decoded uint256');
is_deeply($decoded[1], [1110, 1929], 'decoded uint32[]');
is(hx($decoded[2]), '31323334353637383930', 'decoded bytes10');
is($decoded[3], 'Hello, world!', 'decoded bytes');

# address round-trip through decode_result
my $addr_bytes = "\x00" x 12 . pack('H*', '5b38da6a701c568545dcfcb03fcb875f56beddc4');
is((decode_result(['address'], $addr_bytes))[0], '0x5b38da6a701c568545dcfcb03fcb875f56beddc4',
    'decode address');

# bool
my $true_word  = ("\x00" x 31) . "\x01";
my $false_word = "\x00" x 32;
is((decode_result(['bool'], $true_word))[0], 1, 'decode bool true');
is((decode_result(['bool'], $false_word))[0], 0, 'decode bool false');

done_testing;
