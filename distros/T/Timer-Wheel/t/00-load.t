#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Timer::Wheel' ) || print "Bail out!\n";
}

diag( "Testing Timer::Wheel $Timer::Wheel::VERSION, Perl $], $^X" );
