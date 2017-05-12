#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tree::Predicate' );
}

diag( "Testing Tree::Predicate $Tree::Predicate::VERSION, Perl $], $^X" );
