#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::Parts' ) || print "Bail out!";
}

diag( "Testing Text::Parts $Text::Parts::VERSION, Perl $], $^X" );
