#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tree::Family' );
}

diag( "Testing Tree::Family $Tree::Family::VERSION, Perl $], $^X" );
