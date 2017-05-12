#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'URI::mid' ) || print "Bail out!\n";
    use_ok( 'URI::cid' ) || print "Bail out!\n";
}

diag( "Testing URI::mid $URI::mid::VERSION, Perl $], $^X" );
