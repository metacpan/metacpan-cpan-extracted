#!perl

use strict;
use warnings;
use experimentals;
use lib 'lib';
use Test::More tests => 4;
use YAGL;

my $g = YAGL->new;

# The graph below is not connected.

# s-a-b-c

# d-----e
#  \   /
#    f

my @edges = (
    [ 's', 'a' ],
    [ 'a', 'b' ],
    [ 'b', 'c' ],
    [ 'd', 'e' ],
    [ 'd', 'f' ],
    [ 'e', 'f' ],
);

$g->add_edges(@edges);

my $h = YAGL->new;
$h->add_edges(@edges);

# --------------------------------------------------------------------
# Is the graph connected?

my $is_connected_0 = $g->is_connected;

ok( !defined $is_connected_0, "G->is_connected fails as expected." );

# --------------------------------------------------------------------
# Now we add an edge that connects the subgraphs.

# s-a-b-c
#       |
# +-----+
# |
# d-----e
#  \   /
#    f

$g->add_edge( 'c', 'd' );

my $is_connected_1 = $g->is_connected;

ok( $is_connected_1 == 1, "G->is_connected succeeds after adding an edge." );

# --------------------------------------------------------------------
# Now we check whether G is a tree, which is defined by Even on p. 23
# of _Graph Algorithms_ as:
# 1. Is it connected?
# 2. Does it have n-1 edges, where n = |V|?

my $is_tree_0 = $g->is_tree;

ok( !defined $is_tree_0, "G->is_tree fails as expected." );

# Now we delete an edge that makes this a tree, i.e.,

# s-a-b-c
#       |
# +-----+
# |
# d-----e
#      /
#    f

$g->remove_edge( 'd', 'f' );

my $is_tree_1 = $g->is_tree;

ok( $is_tree_1 == 1,
    "G->is_tree succeeds as expected, after an edge is deleted." );
