#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'sBNC::User::Summary' ) || print "Bail out!\n";
}

diag( "Testing sBNC::User::Summary $sBNC::User::Summary::VERSION, Perl $], $^X" );
