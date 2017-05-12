#!./perl
#
# const.t -- tests for the const() interface
#

use strict;
use warnings;
use Test::More;
use ex::constant::vars 'const';

ok((const SCALAR my $scalar1, 42), "tie integer scalar");
ok((const SCALAR my $scalar2, 'forty-two'), "tie string scalar");
ok((const ARRAY  my @array1,  (17,23)), "tie array of integers");
ok((const ARRAY  my @array2,  qw(red green blue)), "tie array of strings");
ok((const HASH   my %hash1,   (x => 1, y => 2, z => 3)), "tie hash of integers");
ok((const HASH   my %hash2,   (name => 'Felix', age => 4.75, legs => 2)), "tie hash of mixed scalars");

ok($scalar1 == 42, "check value of first scalar");
ok($scalar2 eq 'forty-two', "check value of second scalar");
ok(@array1 == 2 && $array1[0] == 17 && $array1[1] == 23, "check first array");
ok(@array2 == 3 && $array2[0] eq 'red' && $array2[1] eq 'green' && $array2[2] eq 'blue', "check second array");
ok(int(keys %hash1) == 3 && $hash1{x} == 1 && $hash1{y} == 2 && $hash1{z} == 3, "check first hash");
ok(int(keys %hash2) == 3 && $hash2{name} eq 'Felix' && $hash2{age} == 4.75 && $hash2{legs} == 2, "check second hash");

eval { $scalar1 = 43; };
ok($@, "assigning to scalar1 should die");
ok($scalar1 == 42, "scalar1 should still have original value");

eval { $scalar2 = 'forty-three'; };
ok($@, "assigning to scalar2 should die");
ok($scalar2 eq 'forty-two', "scalar2 should still have original value");

eval { push(@array1, 37); };
ok($@, "trying to push into array1 should die");
ok(@array1 == 2 && $array1[0] == 17 && $array1[1] == 23, "check first array hasn't changed");

eval { $array1[0] = 7; };
ok($@, "trying to change entry in array1 should die");
ok(@array1 == 2 && $array1[0] == 17 && $array1[1] == 23, "check first array hasn't changed");

eval { push(@array2, 'cyan'); };
ok($@, "trying to push into array2 should die");
ok(@array2 == 3 && $array2[0] eq 'red' && $array2[1] eq 'green' && $array2[2] eq 'blue', "check second array hasn't changed");

eval { $hash1{w} = 0; };
ok($@, "trying to add new entry to hash1");
ok(int(keys %hash1) == 3 && $hash1{x} == 1 && $hash1{y} == 2 && $hash1{z} == 3, "check first hash hasn't changed");

eval { $hash1{x} = 0; };
ok($@, "trying to change existing entry in hash1");
ok(int(keys %hash1) == 3 && $hash1{x} == 1 && $hash1{y} == 2 && $hash1{z} == 3, "check first hash hasn't changed");

eval { $hash2{siblings} = 1; };
ok($@, "trying to add new entry to hash2");
ok(int(keys %hash2) == 3 && $hash2{name} eq 'Felix' && $hash2{age} == 4.75 && $hash2{legs} == 2, "check second hash hasn't changed");

eval { $hash2{age} = 5; };
ok($@, "trying to change existing entry in hash2");
ok(int(keys %hash2) == 3 && $hash2{name} eq 'Felix' && $hash2{age} == 4.75 && $hash2{legs} == 2, "check second hash hasn't changed");

done_testing();
