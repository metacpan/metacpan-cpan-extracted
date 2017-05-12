#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Affiliate' ) || print "Bail out!\n";
}

diag( "Testing WebService::Affiliate $WebService::Affiliate::VERSION, Perl $], $^X" );
