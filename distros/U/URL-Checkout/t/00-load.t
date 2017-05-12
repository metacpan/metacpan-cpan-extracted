#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'URL::Checkout' ) || print "Bail out!
";
}

diag( "Testing URL::Checkout $URL::Checkout::VERSION, Perl $], $^X" );
