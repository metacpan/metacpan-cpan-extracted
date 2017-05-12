#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Google::Closure' ) || print "Bail out!
";
}

diag( "Testing WebService::Google::Closure $WebService::Google::Closure::VERSION, Perl $], $^X" );
