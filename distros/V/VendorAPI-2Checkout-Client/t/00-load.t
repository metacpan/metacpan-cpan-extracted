#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'VendorAPI::2Checkout::Client' ) || print "Bail out!\n";
}

diag( "Testing VendorAPI::2Checkout::Client $VendorAPI::2Checkout::Client::VERSION, Perl $], $^X" );
