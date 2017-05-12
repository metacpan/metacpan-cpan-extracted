#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::OpenLDAP' ) || print "Bail out!\n";
}

diag( "Testing Test::OpenLDAP $Test::OpenLDAP::VERSION, Perl $], $^X" );
