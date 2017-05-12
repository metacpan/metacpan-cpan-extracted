#   $Id: 72-pod-cover-2.t 67 2008-06-29 14:17:37Z adam $

use strict;
use Test::More;

my $test_warn;
BEGIN {
    eval ' use Test::Pod::Coverage ';
    if ( $@ ) {
        plan( skip_all => 'Test::Pod::Coverage not installled.' );
    }
    else {
        eval ' require Test::NoWarnings; ';
        if ( $@ ) {
            plan( tests => 1 );
            undef $test_warn;
        }
        else {
            plan( tests => 2 );
            $test_warn = 1;
        }
    }
}

my $trustme = { trustme => [qr/^(xsl|rss)_/] };

pod_coverage_ok( "XML::RSS::Tools", $trustme );
if ( $test_warn ) { Test::NoWarnings::had_no_warnings(); }
