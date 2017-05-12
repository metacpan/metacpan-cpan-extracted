#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::XING' ) || print "Bail out!\n";
}

diag( "Testing WebService::XING $WebService::XING::VERSION, Perl $], $^X" );
