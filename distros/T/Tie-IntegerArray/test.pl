# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use strict;
use Test;
BEGIN { plan tests => 12 };

use Tie::IntegerArray;
ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my @integer_array;
tie @integer_array, 'Tie::IntegerArray';
$integer_array[0] = 1;
ok($integer_array[0] == 1);

push(@integer_array, -2, 3, -4);
ok($integer_array[0] == 1 and $integer_array[3] == -4
   and $integer_array[2] == 3);

delete $integer_array[0];
ok($integer_array[1] == -2 and $integer_array[3] == -4
   and $integer_array[2] == 3 and $integer_array[0] == 0);

untie @integer_array;

tie @integer_array, 'Tie::IntegerArray',
  bits => 9,
  undef => 1;
  # trace => 1;
$integer_array[0] = 1;
ok($integer_array[0] == 1);

$integer_array[100] = 50;
ok($integer_array[100] == 50 and $integer_array[99] == 0);

eval {
  $integer_array[100] = 500;
};
ok($@ =~ /out of range/);

ok(exists $integer_array[50] and not defined $integer_array[50]);
ok(not exists $integer_array[5000]);

$integer_array[128] = -128;
$integer_array[127] = -128;
$integer_array[129] = -128;
ok($integer_array[128] == -128);
delete($integer_array[128]);
ok((not defined $integer_array[128]) and $integer_array[127] == -128 and $integer_array[129] == -128);

@integer_array = ();
ok(not exists($integer_array[0]));
