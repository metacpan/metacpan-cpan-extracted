#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::Histogram' ) || print "Bail out!\n";
}

diag( "Testing Text::Histogram $Text::Histogram::VERSION, Perl $], $^X" );
