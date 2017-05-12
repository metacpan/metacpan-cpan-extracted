#!/usr/bin/perl -w

use strict;
use Test::LectroTest::Compat tests => 7;
use Test::More;

my $true = Property {
    ##[ ]##
    1
}, name => "always succeeds";

my $false = Property {
    ##[  ]##
    0
}, name => "always fails";


my $cmp_ok = Property {
    ##[ x <- Int( range=>[0,10] ) ]##
    cmp_ok($x, '>=', 0) && cmp_ok($x, '<=', 10);
}, name => "cmp_ok can be used";

my $cmp_ok_fail = Property {
    ##[ x <- Int( range=>[0,10] ) ]##
    cmp_ok($x, '>', 10);
}, name => "cmp_ok can be used (2)";;


holds( $true, trials => 5 );
holds( $cmp_ok );

cmp_ok( 0, '<', 1, "trivial 0<1 test" );

holds( Property {
    ##[ ]##
    1;
}, name => "inline" );


cmp_ok( 0, '<', 1, "trivial 0<1 test" );

ok( ! capture( sub { holds( $false ) } ),
    "false property yields test failure" );

ok( ! capture( sub { holds( $cmp_ok_fail ) } ),
    "failing cmp_ok w/in prop yields test failure");


# the following function evaluates a given Test::* test (given as an
# anonymous subroutine) within a protective environment that captures
# the result of the test without reporting it back to Test::More
# (which uses Test::Builder).  this function is used to run tests that
# we expect to fail

sub capture {
    no warnings;
    no strict 'refs';
    my $test_fn = shift;
    local *Test::Builder::ok   = sub { $_[1] ? 1 : 0 };
    local *Test::Builder::diag = sub { 0 };
    return $test_fn->();
}
