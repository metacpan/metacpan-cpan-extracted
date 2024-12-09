#!/usr/bin/env perl

use strict;
use warnings;
use lib 'lib';
use Test::More tests => 4;
use YAGL;
use Cwd;

my $cwd = getcwd;

=head2 Test 1. Bipartite graph from House of Graphs

L<https://hog.grinvin.org/ViewGraphInfo.action?id=45342>

=cut

my $g = YAGL->new;
$g->read_lst("$cwd/t/29-graph_45342.lst");

my $got      = $g->is_bipartite;
my $expected = 1;

is($got, $expected, "Graph 45342 from House of Graphs is bipartite.");

=head2 Test 2. Making a bipartite graph into a non-bipartite one

In this test, we add vertices and edges to the previous graph that
make a cycle, so that it is no longer bipartite.

=cut

my @vertices = $g->get_vertices;
my $v = $vertices[0];

$g->add_edge('foo', 'bar');
$g->add_edge('bar', 'baz');
$g->add_edge('foo', 'baz');

my $got_2 = $g->is_bipartite;

isnt($got_2, $expected, "Bipartite graph + a cycle is no longer bipartite.");

=head2 Test 3. Making a non-bipartite graph back into a bipartite one

In this test, we remove the edges and vertices added in the previous
test.  Once again, the graph should be bipartite.

=cut

$g->remove_vertex('foo');
$g->remove_vertex('bar');
$g->remove_vertex('baz');

my $got_3 = $g->is_bipartite;
my $expected_3 = 1;

is($got_3, $expected_3, "Bipartite graph - a cycle is bipartite once again.");

=head2 Test 4. Verifying a non-bipartite graph

=cut

my $h = YAGL->new;
$h->read_lst("$cwd/t/29-graph_19187.lst");

my $got_4      = $h->is_bipartite;
my $expected_4 = undef;

is($got_4, $expected_4, "Graph 19187 from House of Graphs is not bipartite.");

# Local Variables:
# compile-command: "cd .. && perl t/29-bipartite.t"
# End:
