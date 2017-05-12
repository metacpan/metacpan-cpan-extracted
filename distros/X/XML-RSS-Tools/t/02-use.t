#   $Id: 02-use.t 67 2008-06-29 14:17:37Z adam $

use strict;
use Test::More;

my $test_warn;
BEGIN {
    eval ' require Test::NoWarnings; ';
    if ( $@ ) {
        plan( tests => 1 );
        undef $test_warn;
    }
    else {
        plan( tests => 2 );
        $test_warn = 1;
    }
    use_ok( 'XML::RSS::Tools' );
}

if ( $test_warn ) {
    Test::NoWarnings::had_no_warnings();
}
