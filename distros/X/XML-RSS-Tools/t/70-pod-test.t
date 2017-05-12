#   $Id: 70-pod-test.t 67 2008-06-29 14:17:37Z adam $

use strict;
use Test::More;

my $test_warn;
BEGIN {
    eval ' use Test::Pod; ';

    if ( $@ ) {
        plan( skip_all => 'Test::Pod not installled.' );
    }
    else {
        eval ' require Test::NoWarnings; ';
        if ( $@ ) {
            plan( tests => 12 );
            undef $test_warn;
        }
        else {
            plan( tests => 13 );
            $test_warn = 1;
        }
    }
}

pod_file_ok( './lib/XML/RSS/Tools.pm',               'Valid POD file' );
pod_file_ok( './docs/example-1.pod',                 'Valid POD file' );
pod_file_ok( './docs/example-2.pod',                 'Valid POD file' );
pod_file_ok( './docs/example-3.pod',                 'Valid POD file' );
pod_file_ok( './docs/example-4.pod',                 'Valid POD file' );
pod_file_ok( './docs/example-5.pod',                 'Valid POD file' );
pod_file_ok( './examples/example-1.pl',              'Valid POD file' );
pod_file_ok( './examples/example-2.pl',              'Valid POD file' );
pod_file_ok( './examples/example-3.pl',              'Valid POD file' );
pod_file_ok( './examples/example-4.pl',              'Valid POD file' );
pod_file_ok( './examples/example-5.pl',              'Valid POD file' );
pod_file_ok( './docs/rss-introduction.pod',          'Valid POD file' );
if ( $test_warn ) { Test::NoWarnings::had_no_warnings(); }
