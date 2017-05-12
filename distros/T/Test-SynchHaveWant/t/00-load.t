#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::SynchHaveWant' ) || print "Bail out!
";
}

diag( "Testing Test::SynchHaveWant $Test::SynchHaveWant::VERSION, Perl $], $^X" );
