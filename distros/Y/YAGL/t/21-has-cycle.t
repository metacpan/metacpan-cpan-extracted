#!perl

use strict;
use warnings;
use experimentals;
use lib 'lib';
use Test::More tests => 2;
use YAGL;

my $g = YAGL->new;

# The graph below has a cycle.

# s-a-b-c
#       |
# +-----+
# |
# d-----e
#  \   /
#    f

my @edges = (
    [ 's', 'a' ],
    [ 'a', 'b' ],
    [ 'b', 'c' ],
    [ 'c', 'd' ],
    [ 'd', 'e' ],
    [ 'd', 'f' ],
    [ 'e', 'f' ],
);

$g->add_edges(@edges);

# --------------------------------------------------------------------
# Is the graph connected?

my $has_cycle = $g->has_cycle;

ok( $has_cycle == 1, "G->has_cycle returns true as expected." );

# --------------------------------------------------------------------
# Now we delete an edge that removes the cycle.

# s-a-b-c
#       |
# +-----+
# |
# d-----e
#      /
#    f

$g->remove_edge( 'd', 'f' );

my $has_cycle_1 = $g->has_cycle;

ok( !defined $has_cycle_1,
    "G->has_cycle returns false after removing an edge." );
