#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::CloudPT' ) || print "Bail out!\n";
}

diag( "Testing WebService::CloudPT $WebService::CloudPT::VERSION, Perl $], $^X" );
