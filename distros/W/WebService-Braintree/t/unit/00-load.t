# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

use lib qw(lib t/lib);

BEGIN {
    use_ok( 'WebService::Braintree' ) || print "Bail out!\n";
}

diag( "Testing WebService::Braintree $WebService::Braintree::VERSION, Perl $], $^X" );

done_testing();
