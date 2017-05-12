#!perl -T

use lib "t";
use strict;
use Test::More tests=>2;
use Test::Builder::Tester;

BEGIN {
    use_ok( 'Test::Pod::Coverage' );
}

OPTIONAL_MESSAGE: {
    test_out( "ok 1 - Pod coverage on Simple" );
    pod_coverage_ok( "Simple" );
    test_test( "Simple runs under T:B:T" );
}
