#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Text::PRN::Slurp' ) || print "Bail out!\n";
}

diag( "Testing Text::PRN::Slurp $Text::PRN::Slurp::VERSION, Perl $], $^X" );
