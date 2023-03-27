#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Weather::Astro7Timer' ) || print "Bail out!\n";
}

diag( "Testing Weather::Astro7Timer $Weather::Astro7Timer::VERSION, Perl $], $^X" );
