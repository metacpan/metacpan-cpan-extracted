#!/usr/bin/env perl

use Test::More tests => 14;

BEGIN {
    use_ok( 'Tree::SEMETrie' ) || print "Bail out!\n";
}

diag( "Testing Tree::SEMETrie $Tree::SEMETrie::VERSION, Perl $], $^X" );

can_ok 'Tree::SEMETrie', $_ for qw{
	new
	children childs value
	has_children has_childs has_value
	add insert
	find lookup
	erase remove
};
