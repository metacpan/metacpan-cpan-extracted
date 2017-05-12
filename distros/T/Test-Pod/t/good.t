#!perl -T

use strict;

use Test::Builder::Tester tests => 3;
use Test::More;

BEGIN {
    use_ok( 'Test::Pod' );
}


my $filename = "t/pod/good.pod";
GOOD: {
    test_out( "ok 1 - Blargo!" );
    pod_file_ok( $filename, "Blargo!" );
    test_test( 'Handles good.pod OK' );
}

DEFAULT_NAME: {
    test_out( "ok 1 - POD test for t/pod/good.pod" );
    pod_file_ok( $filename );
    test_test( 'Handles good.pod OK, and builds default name OK' );
}
