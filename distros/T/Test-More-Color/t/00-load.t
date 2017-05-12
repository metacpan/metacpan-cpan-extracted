#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::More::Color' ) || print "Bail out!
";
}

diag( "Testing Test::More::Color $Test::More::Color::VERSION, Perl $], $^X" );
