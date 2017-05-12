#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Pushwoosh' ) || print "Bail out!\n";
}

diag( "Testing WebService::Pushwoosh $WebService::Pushwoosh::VERSION, Perl $], $^X" );
