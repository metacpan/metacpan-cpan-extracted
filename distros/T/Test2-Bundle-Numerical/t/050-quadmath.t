use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan 12;

my $high_precision = 1.23456789012345678901234567890123456789;
my $near = $high_precision + relative_tolerance(8) / 2;
my $far  = $high_precision + relative_tolerance(8) * 10;

ok($high_precision != $near, 'quadmath preserves extra precision in numeric literals');
ok($high_precision != $far, 'quadmath distinguishes larger differences');

float_is($high_precision, $high_precision, 'float_is exact same quadmath value');
is($high_precision, $high_precision, 'is exact same quadmath value');
float_is($high_precision, $near, 'float_is within quadmath relative tolerance');
float_is_ulps($high_precision, $near, 'float_is_ulps within default ULP count');
float_is_relative($high_precision, $near, 'float_is_relative within quadmath relative tolerance');

float_isnt($high_precision, $far, 'float_is rejects a too-distant quadmath value');
isnt($high_precision, $far, 'is rejects a too-distant quadmath value');
ulp_equal($high_precision, $near, 8, 'ulp_equal accepts a close quadmath value');
ulp_distance($high_precision, $near, 'gte', 0, 'ulp_distance returns a valid distance');

ok(approx_eq($high_precision, $near, relative_tolerance(12)), 'approx_eq accepts a nearby quadmath value');
