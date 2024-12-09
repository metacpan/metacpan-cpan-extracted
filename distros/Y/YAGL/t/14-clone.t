#!perl

use strict;
use warnings;
use experimentals;
use lib 'lib';
use Test::More tests => 8;
use YAGL;

my $g = YAGL->new;

my @new = (
    [ 'a', 'b', { weight => 1 } ],
    [ 'a', 'c', { weight => 2 } ],
    [ 'a', 'd', { weight => 3 } ],
    [ 'a', 'e', { weight => 3 } ],
);

$g->add_edges(@new);

# Copy the graph object, and add a new vertex.

my $h = $g->clone;

$h->add_vertex('f');

# Verify that the copied object has the new vertex, and the original
# doesn't.

my $h_has_f = $h->has_vertex('f');
my $g_has_f = $g->has_vertex('f');

is( $h_has_f, 1,
    "Copied object H should have the new vertex 'f' that was added to it." );
is( $g_has_f, undef,
"Original object G should not have the new vertex 'f' that was added to the copied object H."
);

# Add 'f' to G as well.  Now they should be the same again.

$g->add_vertex('f');
is_deeply( $g, $h,
    "Copied object H is the same (according to is_deeply) as original G." );

# Now we add a new vertex 'g' to G.  We verify that only G has the new
# vertex, and not H.

$g->add_vertex('g');
my $g_has_g = $g->has_vertex('g');
my $h_has_g = $h->has_vertex('g');

is( $g_has_g, 1,
    "Original object G has the new vertex 'g' that was added to it." );
is( $h_has_g, undef,
"Copied object H does not have the new vertex 'g' that was added to the original object G."
);

# We verify the above claim a bit more strongly by checking their
# lists of vertices against each other.

my @gs = $g->get_vertices;
my @hs = $h->get_vertices;

isnt( \@gs, \@hs,
"Vertices of the copied object are not the same as the original after modifications, as expected."
);

# Add an edge to H
$h->add_edge( 'a', 'h', {} );
my $h_degree = $h->get_degree('a');
my $g_degree = $g->get_degree('a');

is( $g_degree, 4,
"Vertex G.a should have degree 4 even though vertex H.a has been updated to 5"
);
isnt( $h_degree, $g_degree,
"Vertices G['a'] and H['a'] should not have same degree, since H['a'] has an edge added."
);
