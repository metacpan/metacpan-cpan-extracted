#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::InDomain' ) || print "Bail out!\n";
}

diag( "Testing Test::InDomain $Test::InDomain::VERSION, Perl $], $^X" );
