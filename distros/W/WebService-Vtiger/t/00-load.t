#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Vtiger' ) || print "Bail out!
";
}

diag( "Testing WebService::Vtiger $WebService::Vtiger::VERSION, Perl $], $^X" );
