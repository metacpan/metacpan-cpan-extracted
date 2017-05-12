#!perl -T

use warnings FATAL => 'all';
use strict;

use Test::Builder::Tester tests => 5;
use Test::More;

BEGIN {
    use_ok( 'Test::Memory::Cycle' );
}

{
my $cycle_less_hash = {};
test_out( "not ok 1 - A hash reference has no cycles" );
test_fail( +1 );
memory_cycle_exists( $cycle_less_hash, "A hash reference has no cycles" );
test_test( "Testing for lack of cycles in hash reference" );
}

{
my $cycle_less_array = [];
test_out( "not ok 1 - An array reference has no cycles" );
test_fail( +1 );
memory_cycle_exists( $cycle_less_array, "An array reference has no cycles" );
test_test( "Testing for lack of cycles in array reference" );
}

{
my $var = 0;
my $cycle_less_scalar = \$var;
test_out( "not ok 1 - A scalar reference has no cycles" );
test_fail( +1 );
memory_cycle_exists( $cycle_less_scalar, "A scalar reference has no cycles" );
test_test( "Testing for lack of cycles in scalar reference" );
}

{
my $cycle_less_object = bless({}, 'NoCyclesHere');
test_out( "not ok 1 - A blessed reference has no cycles" );
test_fail( +1 );
memory_cycle_exists( $cycle_less_object, "A blessed reference has no cycles" );
test_test( "Testing for lack of cycles in blessed reference" );
}


