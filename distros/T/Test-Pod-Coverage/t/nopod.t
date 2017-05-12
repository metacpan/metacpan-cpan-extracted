#!perl -T

use strict;
use lib "t";
use Test::More tests=>2;
use Test::Builder::Tester;

BEGIN {
    use_ok( 'Test::Pod::Coverage' );
}

test_out( "not ok 1 - Checking Nopod" );
test_fail(+2);
test_diag( "Nopod: couldn't find pod" );
pod_coverage_ok( "Nopod", "Checking Nopod" );
test_test( "Handles files with no pod at all" );
