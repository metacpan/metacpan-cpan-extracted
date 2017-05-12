#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'TreePath::Role::Graph' ) || print "Bail out!\n";
}

diag( "Testing TreePath::Role::Graph $TreePath::Role::Graph::VERSION, Perl $], $^X" );
