#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tree::MultiNode' );
}

diag( "Testing Tree::MultiNode $Tree::MultiNode::VERSION, Perl $], $^X" );
