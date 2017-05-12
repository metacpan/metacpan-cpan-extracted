#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Win32::ExcelSimple' ) || print "Bail out!\n";
}

diag( "Testing Win32::ExcelSimple $Win32::ExcelSimple::VERSION, Perl $], $^X" );
