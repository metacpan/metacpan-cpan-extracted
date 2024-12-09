#!perl

use strict;
use warnings;
use experimentals;
use lib 'lib';
use Test::More tests => 4;
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

# --------------------------------------------------------------------
# First, we verify that the edge s-a does exist.  Then we can verify
# that it's deleted later.

my $edge_s_a = $g->edge_between( 's', 'a' );

ok( $edge_s_a == 1, "There exists an edge S-A." );

# --------------------------------------------------------------------
# Next, we delete the edge, and verify that it has been deleted.

$g->remove_edge( 's', 'a' );

my $edge_s_a_now = $g->edge_between( 's', 'a' );

ok( !defined $edge_s_a_now, "After deleting 'S', there is no edge S-A." );

# --------------------------------------------------------------------
# Finally, we verify that the vertices S and A are still in the graph
# after the edge between them was deleted.

my $has_s = $g->has_vertex('s');
my $has_a = $g->has_vertex('a');

ok( $has_s == 1, "Graph still has vertex S after deleting edge S-A." );
ok( $has_a == 1, "Graph still has vertex A after deleting edge A-S." );
