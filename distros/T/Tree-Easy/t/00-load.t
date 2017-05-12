#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tree::Easy' );
}

diag( "Testing Tree::Easy $Tree::Easy::VERSION, Perl $], $^X" );
