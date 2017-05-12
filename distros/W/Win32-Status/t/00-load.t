#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Win32::Status' ) || print "Bail out!\n";
}

diag( "Testing Win32::Status $Win32::Status::VERSION, Perl $], $^X" );
