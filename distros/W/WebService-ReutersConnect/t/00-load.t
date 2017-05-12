#!perl

use Test::More tests => 2;

BEGIN {
    use_ok( 'WebService::ReutersConnect' ) || print "Bail out!\n";
    use_ok( 'WebService::ReutersConnect::APIResponse');
}

diag( "Testing WebService::ReutersConnect $WebService::ReutersConnect::VERSION, Perl $], $^X" );
