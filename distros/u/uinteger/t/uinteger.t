#!perl
use strict;
use warnings;
use Test::More;

{
  use uinteger;
  is(1.25+1, 2, "lexically on");
  no uinteger;
  is(1.25+1, 2.25, "lexically off");
}
is(1.25+1, 2.25, "still lexically off");

use uinteger;

is(2-3    , ~0  , "subtract to get a large number");
is(~0 *2  , ~1  , "multiply (UV)(-1) by 2");
is(~0 + ~0, -2|0, "add two large numbers");
is(-1     , ~0  , "negate a number");

################################################################################
################################################################################

my $one = 13289325352150669043; # 72% of 2^64
my $two = 7378697629483820646;  # 40% of 2^64
my $big = 18446744073709551615; # 2^64 - 1

is($one + $one       , 8131906630591786470 , 'Overflow addition #1');
is($two + $two + $two, 3689348814741910322 , 'Overflow addition #2');
is($two + $two       , 14757395258967641292, 'No overflow addition');
is($one * $one       , 460133867965229737  , 'Overflow multiplication');
is($big + 0          , 18446744073709551615, '2^64 math');
is($big + 1          , 0                   , '2^64 math');
is($one >> 1         , 6644662676075334521 , 'Bitshift starting with 1');
is($two >> 1         , 3689348814741910323 , 'Bitshift starting with 0');
is($one ^ $two       , 15999966321478398101, 'XOR');

# Make sure what we did above doesn't affect `use integer` math
use integer;
is($big + 0      , -1                  , '2^64 overflow #1');
is($one + 0      , -5157418721558882573, '2^64 overflow #2');
is($two * 2      , -3689348814741910324, '2^64 overflow #3');
is($one + $two   , 2221278907924938073 , '2^64 overflow to positive');
is($two - $one   , -5910627722666848397, '2^64 subtraction to negative');
is($big + $two   , 7378697629483820645 , '2^64 overflow addition');
is(int(2**63) + 1, -9223372036854775807, '2^63 + 1 Integer mode');

done_testing();
