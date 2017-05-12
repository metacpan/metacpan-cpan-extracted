#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'VT::API' ) || print "Bail out!
";
}

diag( "Testing VT::API $VT::API::VERSION, Perl $], $^X" );
