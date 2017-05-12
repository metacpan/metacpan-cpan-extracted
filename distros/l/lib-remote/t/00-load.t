#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'lib::remote' ) || print "Bail out!\n";
}

ok(1, 'Test2');

diag( "Testing lib::remote $lib::remote::VERSION, Perl $], $^X" );


