#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Time::Random' ) || print "Bail out!\n";
}

diag( "Testing Time::Random $Time::Random::VERSION, Perl $], $^X" );
