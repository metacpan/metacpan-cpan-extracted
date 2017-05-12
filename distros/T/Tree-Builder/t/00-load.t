#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tree::Builder' );
}

diag( "Testing Tree::Builder $Tree::Builder::VERSION, Perl $], $^X" );
