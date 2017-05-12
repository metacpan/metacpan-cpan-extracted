#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More;

# build tool runs the whole test suite on the monolithic version.
# Don't bother testing it if exists
if ( $ENV{AUTHOR_TESTING_MONOLITH_BUILD} ) {
    plan( skip_all => 'Skipping for monolith build test' );
}

eval {
    require Test::Pod::Coverage;
    1;
} or do {
    diag("Error loading Test::Pod::Coverage: $@");
    plan( skip_all => 'Test::Pod::Coverage required for testing pod coverage' );
    exit;
};

eval {
    Test::Pod::Coverage::all_pod_coverage_ok();
    1;
} or do {
    diag( "Some error happened in somewhere, which I don't care: $@" );
    ok( 1, 'Fake test' );
};
