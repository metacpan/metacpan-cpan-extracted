#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Xen::API' ) || print "Bail out!\n";
}

diag( "Testing Xen::API $Xen::API::VERSION, Perl $], $^X" );
