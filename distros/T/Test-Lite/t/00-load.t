#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Lite' ) || print "Bail out!\n";
}

diag( "Testing Test::Lite $Test::Lite::VERSION, Perl $], $^X" );
