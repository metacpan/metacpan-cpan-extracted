#!perl

use strict;
use warnings;
use lib 'lib';
use Test::More tests => 3;
use Cwd;
use YAGL;

my $g   = YAGL->new;
my $cwd = getcwd;

$g->read_csv("$cwd/t/23-mst-00.csv");

=pod

Get the MST of the following very small, simple graph:

    S -(12)- A -(13)- B -(17)- C
    |
    + -(10)- D -(14)- E -(19)- F

=cut

my $mst = $g->mst;

=pod

Test 01. Check that the MST returned is a (different) YAGL graph object, as expected.

=cut

isa_ok( $g, 'YAGL' );

=pod

Test 02. Check that the MST returned is the expected tree.  We know
through experimentation that the sum of the MST for the graph in this
example is 81.  Therefore, we check that the sum of the new MST
generated during this test is 81.

Remember that the structure of an edge returned by F<get_edges> is:

    [ $a, $b, { foo => 'bar', baz => 'quux', } ]

=cut

my $expected = 81;

my @edges = $mst->get_edges;

my $got;
for my $edge (@edges) {
    $got += $edge->[2]->{weight};
}

ok( $expected == $got,
    "Summing the edges of the MST returns the expected weight." );

=pod

Test 03. We now check that the full set of edges in the MST what we expected.

=cut

my $edges = [
    [
        'e', 'f',
        {
            'weight' => 19
        }
    ],
    [
        'd', 's',
        {
            'weight' => 10
        }
    ],
    [
        'd', 'e',
        {
            'weight' => 14
        }
    ],
    [
        'b', 'c',
        {
            'weight' => 17
        }
    ],
    [
        'a', 'd',
        {
            'weight' => 8
        }
    ],
    [
        'a', 'b',
        {
            'weight' => 13
        }
    ]
];

is_deeply( $edges, \@edges, "MST algorithm returns the expected edges." );
