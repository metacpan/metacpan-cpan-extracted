#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Scriptogram' ) || print "Bail out!\n";
}

diag( "Testing WebService::Scriptogram $WebService::Scriptogram::VERSION, Perl $], $^X" );
