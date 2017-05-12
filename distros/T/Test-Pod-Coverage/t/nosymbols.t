#!perl -T

use strict;
use lib "t";
use Test::More tests => 3;
use Test::Builder::Tester;

BEGIN {
    use_ok( 'Test::Pod::Coverage' );
}

NO_VERBOSE: {
    local $ENV{HARNESS_VERBOSE} = 0;
    test_out( "ok 1 - Checking Nosymbols" );
    pod_coverage_ok( "Nosymbols", "Checking Nosymbols" );
    test_test( "Handles files with no symbols" );
}

VERBOSE: {
    local $ENV{HARNESS_VERBOSE} = 1;
    test_out( "ok 1 - Checking Nosymbols" );
    test_diag( "Nosymbols: no public symbols defined" );
    pod_coverage_ok( "Nosymbols", "Checking Nosymbols" );
    test_test( "Handles files with no symbols" );
}
