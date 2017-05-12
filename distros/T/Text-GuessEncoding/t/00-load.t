#!perl -T

use strict;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::GuessEncoding' ) || print "Bail out!
";
}

diag( "Testing Text::GuessEncoding $Text::GuessEncoding::VERSION, Perl $], $^X" );
