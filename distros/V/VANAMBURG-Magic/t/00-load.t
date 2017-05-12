#!perl 
use strict;

use Test::More tests => 1;

BEGIN {
    use_ok( 'VANAMBURG::Magic' ) || print "Bail out!
";
}

diag( "Testing VANAMBURG::Magic $VANAMBURG::Magic::VERSION, Perl $], $^X" );
