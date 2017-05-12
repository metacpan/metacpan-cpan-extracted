#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Futu' ) || print "Bail out!
";
}

diag( "Testing WebService::Futu $WebService::Futu::VERSION, Perl $], $^X" );
