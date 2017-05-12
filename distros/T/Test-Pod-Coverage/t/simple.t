#!perl -T

use lib "t";
use strict;
use Test::More tests=>4;
use Test::Builder::Tester;

BEGIN {
    use_ok( 'Test::Pod::Coverage' );
}

pod_coverage_ok( "Simple", "Simple is OK" );

# Now try it under T:B:T
test_out( "ok 1 - Simple is still OK" );
pod_coverage_ok( "Simple", "Simple is still OK" );
test_test( "Simple runs under T:B:T" );

test_out( "ok 1 - Pod coverage on Simple" );
pod_coverage_ok( "Simple" );
test_test( "Simple runs under T:B:T" );
