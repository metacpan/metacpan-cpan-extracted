#!perl

use strict;
use warnings;
use autodie;
use feature qw/ say /;
use lib '../lib';
use YAGL;

my $g = YAGL->new;

# Populate the graph with 124 vertices, with randomly allocated
# weighted edges between some of the vertices. The 'p' argument is
# the probability that a given node A will *not* be connected to
# another randomly selected node B.

$g->generate_random_vertices({n => 124, p => 0.1, max_weight => 100_000});

# Add vertices to the graph.

$g->add_vertex('abc123');
$g->add_vertex('xyz789');
$g->add_vertex('I_AM_A_TEST');

# Add edges to the graph.  You can store arbitrary attributes on
# edges in hashrefs.

$g->add_edge('abc123',      'xyz789', {weight => 1_000_000});
$g->add_edge('I_AM_A_TEST', 'abc123', {weight => 12345});

# Write the graph out to a CSV file.  This file can be read back
# in later with the 'read_csv' method.

$g->write_csv('foo.csv');

# Pick a start and end vertex at random from the graph.

my @vertices = $g->get_vertices;

my $i     = int rand @vertices;
my $j     = int rand @vertices;
my $start = $vertices[$i];
my $end   = $vertices[$j];

# Using breadth-first search, find a path between the start and
# end vertices, if any such path exists.  Otherwise, this method
# returns undef.

my @path;
@path = $g->find_path_between($start, $end);

# Get a string representation of the graph in the graphviz
# language for passing along to graphviz tools like `dot`.

my $dot_string = $g->to_graphviz;
