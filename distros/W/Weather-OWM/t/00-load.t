#!perl
use 5.008;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Weather::OWM' ) || print "Bail out!\n";
}

diag( "Testing Weather::OWM $Weather::OWM::VERSION, Perl $], $^X" );
