#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Time::Piece::Guess' ) || print "Bail out!\n";
}

diag( "Testing Time::Piece::Guess $Time::Piece::Guess::VERSION, Perl $], $^X" );
