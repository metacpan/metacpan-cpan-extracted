#!perl
use 5.10.1;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Text::Sparkline' ) || print "Bail out!\n";
}

diag( "Testing Text::Sparkline $Text::Sparkline::VERSION, Perl $], $^X" );
