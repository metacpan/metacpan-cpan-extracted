#!perl -T

use strict;

use Test::Builder::Tester tests => 3;
use Test::More;

BEGIN {
    use_ok( 'Test::Pod' );
}

MISSING_FILE: {
    my $file = 't/non-existent.pod';
    test_out( "not ok 1 - I hope the file is there" );
    test_fail(+1);
    pod_file_ok( $file, "I hope the file is there" );
    test_diag( "$file does not exist" );
    test_test( "$file is bad" );
}


MISSING_FILE_NO_MESSAGE: {
    my $file = 't/non-existent.pod';
    test_out( "not ok 1 - POD test for $file" );
    test_fail(+1);
    pod_file_ok( $file );
    test_diag( "$file does not exist" );
    test_test( "$file is bad" );
}
