#!perl

use strict;
use warnings;
use experimentals;
use lib 'lib';
use Test::More tests => 5;
use YAGL;

my $g = YAGL->new;

my @new = (
    [ 's', 'a', { weight => 560 } ],
    [ 's', 'd', { weight => 529 } ],
    [ 'a', 'b', { weight => 112 } ],
    [ 'a', 'd', { weight => 843 } ],
    [ 'b', 'c', { weight => 690 } ],
    [ 'b', 'e', { weight => 891 } ],
    [ 'd', 'e', { weight => 492 } ],
    [ 'e', 'f', { weight => 35 } ],
);

$g->add_edges(@new);

$g->remove_vertex('s');

# --------------------------------------------------------------------
# Was the vertex deleted?

my $has_s = $g->has_vertex('s');

ok( !defined $has_s, "remove_vertex() method works as expected" );

# --------------------------------------------------------------------
# Is there an edge between the deleted vertex and another one that
# exists?

# We start by making sure that the *other* vertex we are checking for
# an edge between does in fact exists.  That way when the test fails,
# it's because of what we expect (that vertex "s" does not exist).

my $has_a = $g->has_vertex('a');

ok( $has_a == 1, "Vertex we are checking for an edge with does exist" );

# Now we can see whether an edge exists between a known-deleted vertex
# and a known-good one.

my $has_edge_s_a = $g->edge_between( 's', 'a' );

ok( !defined $has_edge_s_a,
    "There is no edge between a deleted and non-deleted vertex." );

# --------------------------------------------------------------------
# When a vertex that was part of an edge has been deleted, do that
# edge's attributes also get deleted?

# First, let's check for attributes of an edge that *does* exist.

my $edge_attrs_a_b = $g->get_edge_attributes( 'a', 'b' );

my $expected_attrs = { weight => 112 };

is_deeply( $edge_attrs_a_b, $expected_attrs,
    "Checking for attributes of a known-good edge works." );

# Next, we check for edge attributes of an edge that should no longer
# exist, because one of the vertices involved was deleted earlier.

$g->remove_vertex('b');

my $edge_attrs_a_b_now = $g->get_edge_attributes( 'a', 'b' );

ok(
    !defined $edge_attrs_a_b_now,
qq[Edge attributes do not exist in an "edge" between a deleted vertex 'B' and an extant vertex 'A'.]
);
