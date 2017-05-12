#!perl -T

use strict;

use Test::More skip_all => "Not written yet";
use Test::Builder::Tester tests => 2;
use Test::More;

BEGIN {
    use_ok( 'Test::Pod' );
}

BAD: {
    my $name = 'Test name: Something not likely to accidentally occur!';
    my $file = 't/spaced-directives.pod';
    test_out( "not ok 1 - $name" );
    pod_file_ok( $file, $name );
    test_fail(-1);
    test_diag('*** WARNING: line containing nothing but whitespace in paragraph at line 11 in file t/spaced-directives.pod');
    test_diag('*** WARNING: line containing nothing but whitespace in paragraph at line 17 in file t/spaced-directives.pod');
    test_test( "$name is bad" );
}
