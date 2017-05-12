#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tk::DoubleClick' );
}

diag( "Testing Tk::DoubleClick $Tk::DoubleClick::VERSION, Perl $], $^X" );
