#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Time::Left' ) || print "Bail out!\n";
}

diag( "Testing Time::Left $Time::Left::VERSION, Perl $], $^X" );
