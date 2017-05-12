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

my $dad = {
    name => "Dan Lester",
};

my $me = {
    name => "Andy Lester",
    parents => [$mom,$dad],
};
my $andy = $me;

my $amy = {
    name => "Amy Lester",
};

my $quinn = {
    name => "Quinn Lester",
    parents => [$andy,$amy],
};

$mom->{children} = [$andy];
$mom->{grandchildren} = [$quinn];

test_out( "not ok 1 - The Array Family" );
test_fail( +13 );
test_diag( 'Cycle #1' );
test_diag( '    %A->{parents} => @B' );
test_diag( '    @B->[0] => %C' );
test_diag( '    %C->{children} => @D' );
test_diag( '    @D->[0] => %A' );
test_diag( 'Cycle #2' );
test_diag( '    %A->{parents} => @B' );
test_diag( '    @B->[0] => %C' );
test_diag( '    %C->{grandchildren} => @E' );
test_diag( '    @E->[0] => %F' );
test_diag( '    %F->{parents} => @G' );
test_diag( '    @G->[0] => %A' );
memory_cycle_ok( $me, "The Array Family" );
test_test( "Array family testing" );

test_out( "ok 1 - The Array Family has Cycles" );
memory_cycle_exists( $me, "The Array Family has Cycles" );
test_test( "Array family testing for cycles" );

weaken($me->{parents}->[0]->{children}->[0]);
weaken($me->{parents}->[0]->{grandchildren}->[0]->{parents}->[0]);

test_out( "ok 1 - The Array Family (weakened)" );
memory_cycle_ok( $me, "The Array Family (weakened)" );
test_test( "Array family (weakened) testing (no cycles)" );

test_out( "not ok 1 - The Array Family (weakened)" );
test_fail( +13 );
test_diag( 'Cycle #1' );
test_diag( '    %A->{parents} => @B' );
test_diag( '    @B->[0] => %C' );
test_diag( '    %C->{children} => @D' );
test_diag( '    w->@D->[0] => %A' );
test_diag( 'Cycle #2' );
test_diag( '    %A->{parents} => @B' );
test_diag( '    @B->[0] => %C' );
test_diag( '    %C->{grandchildren} => @E' );
test_diag( '    @E->[0] => %F' );
test_diag( '    %F->{parents} => @G' );
test_diag( '    w->@G->[0] => %A' );
weakened_memory_cycle_ok( $me, "The Array Family (weakened)" );
test_test( "Array family (weakened) testing (weakened cycles showing)" );

test_out( "not ok 1 - The Array Family (weakened) has Cycles" );
test_fail( +1 );
memory_cycle_exists( $me, "The Array Family (weakened) has Cycles" );
test_test( "Array family (weakened) testing for cycles (no cycles)" );

test_out( "ok 1 - The Array Family (weakened) has Cycles" );
weakened_memory_cycle_exists( $me, "The Array Family (weakened) has Cycles" );
test_test( "Array family (weakened) testing for cycles (weakened cycles showing)" );
