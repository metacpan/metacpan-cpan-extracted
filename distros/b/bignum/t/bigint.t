# -*- mode: perl; -*-

###############################################################################

use strict;
use warnings;

use Test::More tests => $] >= 5.033008 ? 45 : 44;

use bigint qw/hex oct/;

###############################################################################
# general tests

my $x = 5;
is(ref($x), 'Math::BigInt', '$x = 5 makes $x a Math::BigInt');

# todo:  is(2 + 2.5, 4.5);                              # should still work
# todo: $x = 2 + 3.5; is(ref($x), 'Math::BigFloat');

$x = 2 ** 255;
is(ref($x), 'Math::BigInt', '$x = 2 ** 255 makes $x a Math::BigInt');

is(12->bfac(), 479001600, '12->bfac() = 479001600');
is(9/4, 2, '9/4 = 2');

is(4.5 + 4.5, 8, '4.5 + 4.5 = 8');                         # truncate
is(ref(4.5 + 4.5), 'Math::BigInt', '4.5 + 4.5 makes a Math::BigInt');

###############################################################################
# accuracy and precision

is(bigint->accuracy(), undef, 'get accuracy');
bigint->accuracy(12);
is(bigint->accuracy(), 12, 'get accuracy again');
bigint->accuracy(undef);
is(bigint->accuracy(), undef, 'get accuracy again');

is(bigint->precision(), undef, 'get precision');
bigint->precision(12);
is(bigint->precision(), 12, 'get precision again');
bigint->precision(undef);
is(bigint->precision(), undef, 'get precision again');

is(bigint->round_mode(), 'even', 'get round mode');
bigint->round_mode('odd');
is(bigint->round_mode(), 'odd', 'get round mode again');
bigint->round_mode('even');
is(bigint->round_mode(), 'even', 'get round mode again');

###############################################################################
# hex() and oct()

my @table =
  (

   [ 'hex(1)',       1 ],
   [ 'hex(01)',      1 ],
   [ 'hex(0x1)',     1 ],
   [ 'hex("01")',    1 ],
   [ 'hex("0x1")',   1 ],
   [ 'hex("0X1")',   1 ],
   [ 'hex("x1")',    1 ],
   [ 'hex("X1")',    1 ],
   [ 'hex("af")',  175 ],

   [ 'oct(1)',       1 ],
   [ 'oct(01)',      1 ],
   [ 'oct(" 1")',    1 ],

   [ 'oct(0x1)',     1 ],
   [ 'oct("0x1")',   1 ],
   [ 'oct("0X1")',   1 ],
   [ 'oct("x1")',    1 ],
   [ 'oct("X1")',    1 ],
   [ 'oct(" 0x1")',  1 ],

   [ 'oct(0b1)',     1 ],
   [ 'oct("0b1")',   1 ],
   [ 'oct("0B1")',   1 ],
   [ 'oct("b1")',    1 ],
   [ 'oct("B1")',    1 ],
   [ 'oct(" 0b1")',  1 ],

   [ 'oct("0o1")',   1 ],
   [ 'oct("0O1")',   1 ],
   [ 'oct("o1")',    1 ],
   [ 'oct("O1")',    1 ],
   [ 'oct(" 0o1")',  1 ],

  );

if ($] >= "5.033008") {         # must be quoted due to pragma
    push @table, [ 'oct(0o1)', 1 ];
}

for my $entry (@table) {
    my ($test, $want) = @$entry;

    subtest $test, sub {
        plan tests => 2;
        my $got = eval $test;
        cmp_ok($got, '==', $want, 'the output value is correct');
        is(ref($x), "Math::BigInt", 'the reference type is correct');
    };
}
