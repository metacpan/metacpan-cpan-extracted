#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'VSGDR::StaticData' )  
}

diag( "Testing VSGDR::StaticData, $VSGDR::StaticData::VERSION Perl $], $^X" );
