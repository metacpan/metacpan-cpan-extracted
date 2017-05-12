#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Affiliate::Merchant' ) || print "Bail out!\n";
}

diag( "Testing WebService::Affiliate::Merchant $WebService::Affiliate::Merchant::VERSION, Perl $], $^X" );
