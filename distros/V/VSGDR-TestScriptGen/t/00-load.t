#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'VSGDR::TestScriptGen' )  
}

diag( "Testing VSGDR::TestScriptGen, $VSGDR::TestScriptGen::VERSION Perl $], $^X" );
