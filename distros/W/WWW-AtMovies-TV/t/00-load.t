#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::AtMovies::TV' );
}

diag( "Testing WWW::AtMovies::TV $WWW::AtMovies::TV::VERSION, Perl $], $^X" );
