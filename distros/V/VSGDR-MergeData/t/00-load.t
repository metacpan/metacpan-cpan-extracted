#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'VSGDR::MergeData' )  
}

diag( "Testing VSGDR::MergeData, $VSGDR::MergeData::VERSION Perl $], $^X" );
