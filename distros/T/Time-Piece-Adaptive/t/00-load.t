#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Time::Piece::Adaptive' );
}

diag( "Testing Time::Piece::Adaptive $Time::Piece::Adaptive::VERSION, Perl $], $^X" );
