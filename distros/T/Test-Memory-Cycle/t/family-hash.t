#!perl -T

use strict;
use warnings FATAL => 'all';

use Scalar::Util qw( weaken );

use Test::More tests => 7;
use Test::Builder::Tester;

BEGIN {
    use_ok( 'Test::Memory::Cycle' );
}

my $mom = {
    name => "Marilyn Lester",
};

my $me = {
    name => "Andy Lester",
    mother => $mom,
};
$mom->{son} = $me;

test_out( "not ok 1 - Small family" );
test_fail( +4 );
test_diag( 'Cycle #1' );
test_diag( '    %A->{mother} => %B' );
test_diag( '    %B->{son} => %A' );
memory_cycle_ok( $me, "Small family" );
test_test( "Small family testing" );

test_out( "ok 1 - Small family has Cycles" );
memory_cycle_exists( $me, "Small family has Cycles" );
test_test( "Small family testing for cycles" );

weaken($me->{mother}->{son});

test_out( "ok 1 - Small family (weakened)" );
memory_cycle_ok( $me, "Small family (weakened)" );
test_test( "Small family (weakened) testing (no cycles)" );

test_out( "not ok 1 - Small family (weakened)" );
test_fail( +4 );
test_diag( 'Cycle #1' );
test_diag( '    %A->{mother} => %B' );
test_diag( '    w->%B->{son} => %A' );
weakened_memory_cycle_ok( $me, "Small family (weakened)" );
test_test( "Small family (weakened) testing for cycles (weakened cycles found)" );

test_out( "not ok 1 - Small family (weakened) has Cycles" );
test_fail( +1 );
memory_cycle_exists( $me, "Small family (weakened) has Cycles" );
test_test( "Small family (weakened) testing for cycles (no cycles)" );

test_out( "ok 1 - Small family (weakened) has Cycles" );
weakened_memory_cycle_exists( $me, "Small family (weakened) has Cycles" );
test_test( "Small family (weakened) testing for cycles (weakened cycles found)" );