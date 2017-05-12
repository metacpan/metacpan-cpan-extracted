#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Weather::Airport' ) || print "Bail out!
";
}

diag( "Testing Weather::Airport $Weather::Airport::VERSION, Perl $], $^X" );
