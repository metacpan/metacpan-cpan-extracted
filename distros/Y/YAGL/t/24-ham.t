#!/usr/bin/env perl

use strict;
use warnings;
use lib 'lib';
use Test::More tests => 10;
use Cwd;
use YAGL;

my $cwd = getcwd;

=head2 Test 1 - Closed Hamiltonian walk.

=cut

my $g = YAGL->new;

$g->read_csv("$cwd/t/24-ham-00.csv");

my $expected_1
  = [['a', 'g', 'h', 'i', 'k', 'j', 'm', 'l', 'e', 'c', 'b', 'd', 'f'],];
my @got_1 = $g->hamiltonian_walks(closed => 1, n_solutions => 1);

is_deeply(\@got_1, $expected_1, "One (1) closed walk on small random graph");

=head2 Test 2 - Find all open Hamiltonian walks on a linear tree

This only works for open walks, and should fail for closed walks, as
well as non-linear trees (see below).

=cut

my $g2 = YAGL->new;

$g2->read_csv("$cwd/t/24-ham-01.csv");

my $expected_2
  = [['hk1881', 'es4065', 'cl9661', 'rh4438', 'pt3513', 'tk3568', 'vo4916']];

my @got_2 = $g2->hamiltonian_walks(closed => undef);

is_deeply(\@got_2, $expected_2, "One (1) open walk on a linear tree");

=head2 Test 3 - No Hamiltonian walks on a non-linear tree

A non-linear tree is a tree with any vertices with degree higher than
1.  (E.g., a binary tree.)  To test this, we add another leaf to the
tree from the previous test to make the tree non-linear.

=cut

$g2->add_edge('tk3568', 'rl12345', {weight => 13});

my $expected_2_prime = [];
my @got_2_prime      = $g2->hamiltonian_walks;

is_deeply(\@got_2, $expected_2, "No walks on a non-linear tree");

=head2 Test 4 - No closed Hamiltonian walks on a tree

=cut

my $g3 = YAGL->new;

$g3->read_csv("$cwd/t/24-ham-01.csv");

my $expected_3 = [];
my @got_3      = $g3->hamiltonian_walks(closed => 1);

is_deeply(\@got_3, $expected_3, "No closed walks on a tree");

=head2 Test 5 - Find the closed Hamiltonian walks on the graph from Sedgewick 2e, fig. 44-1

There should be only 1 found in this case, since by default we do not include reversals.  If we passed the C<allow_reversals> flag, there would be 2.

=cut

my $g4 = YAGL->new;
$g4->read_csv(qq[$cwd/t/24-ham-02.csv]);

my $expected_4
  = [['a', 'f', 'd', 'b', 'c', 'e', 'l', 'm', 'j', 'k', 'i', 'h', 'g'],];
my @got_4 = $g4->hamiltonian_walks(closed => 1);

is_deeply(\@got_4, $expected_4,
    "One (1) closed walk on Sedgewick 2e, fig. 44-1");

=head2 Test 6 - Find the open Hamiltonian walks on the graph from  Sedgewick 2e, fig. 44-1

There should be 5.

=cut

my $g5 = YAGL->new;
$g5->read_csv(qq[$cwd/t/24-ham-02.csv]);

my $expected_5 = [
    ['a', 'f', 'd', 'b', 'c', 'e', 'g', 'h', 'i', 'k', 'j', 'l', 'm'],
    ['a', 'f', 'd', 'b', 'c', 'e', 'g', 'h', 'i', 'k', 'j', 'm', 'l'],
    ['a', 'f', 'd', 'b', 'c', 'e', 'l', 'm', 'j', 'k', 'i', 'h', 'g'],
    ['a', 'g', 'h', 'i', 'k', 'j', 'm', 'l', 'e', 'f', 'd', 'b', 'c']
];

my @got_5 = $g5->hamiltonian_walks;

is_deeply(\@got_5, $expected_5,
    "Four (4) open walks on Sedgewick 2e, fig. 44-1");

=head2 Test 7 - Smallest uniquely hamiltonian graph with minimum degree at least 3

In other words, it has exactly 1 Hamiltonian walk.

L<https://mathoverflow.net/questions/255784/what-is-the-smallest-uniquely-hamiltonian-graph-with-minimum-degree-at-least-3/>

=cut

my $g6 = YAGL->new;
$g6->read_lst(qq[$cwd/t/24-ham-03.lst]);

my $expected_6 = [
    [
        '1', '8',  '17', '5', '12', '9', '3',  '13', '4', '10',
        '2', '16', '18', '7', '15', '6', '11', '14'
    ]
];

my @got_6 = $g6->hamiltonian_walks(closed => 1);

is_deeply(\@got_6, $expected_6,
    "One (1) closed walk on uniquely Hamiltonian graph");

=head2 Test 8 - Smallest uniquely hamiltonian graph with minimum degree at least 3 (reversals allowed)

"Uniquely Hamiltonian" means it has exactly 1 Hamiltonian walk.

L<https://mathoverflow.net/questions/255784/what-is-the-smallest-uniquely-hamiltonian-graph-with-minimum-degree-at-least-3/>

=cut

my $g7 = YAGL->new;
$g7->read_lst(qq[$cwd/t/24-ham-03.lst]);

my $expected_7 = [
    [
        '1', '8',  '17', '5', '12', '9', '3',  '13', '4', '10',
        '2', '16', '18', '7', '15', '6', '11', '14'
    ],
    [
        '1', '14', '11', '6', '15', '7', '18', '16', '2', '10',
        '4', '13', '3',  '9', '12', '5', '17', '8'
    ]
];

my @got_7 = $g7->hamiltonian_walks(closed => 1, allow_reversals => 1);

is_deeply(\@got_7, $expected_7,
    "Two (2) closed walks on uniquely Hamiltonian graph (reversals allowed)");

=head2 Test 9 - The K5 graph - restricting to one solution

L<https://hog.grinvin.org/ViewGraphInfo.action?id=462>

Total (non-distinct) Hamiltonian circuits in complete graph Kn is (n−1)!

L<https://math.stackexchange.com/questions/249817/how-many-hamiltonian-cycles-are-there-in-a-complete-graph-k-n-n-geq-3-why>

=cut

my $g8 = YAGL->new;
$g8->read_lst("$cwd/t/28-graph_462.lst");

my $expected_8 = [['1', '2', '3', '4', '5'],];

my @got_8 = $g8->hamiltonian_walks(closed => 1, n_solutions => 1);

is_deeply(\@got_8, $expected_8, "One (1) closed walk in K5");

=head2 Test 10 - The K5 graph - find all solutions

As noted above, the total (non-distinct) Hamiltonian circuits in
complete graph Kn is (n−1)!

Therefore we should find all 24 solutions.

=cut

my $expected_9 = [
    ['1', '2', '3', '4', '5'],
    ['1', '2', '3', '5', '4'],
    ['1', '2', '4', '3', '5'],
    ['1', '2', '4', '5', '3'],
    ['1', '2', '5', '3', '4'],
    ['1', '2', '5', '4', '3'],
    ['1', '3', '2', '4', '5'],
    ['1', '3', '2', '5', '4'],
    ['1', '3', '4', '2', '5'],
    ['1', '3', '4', '5', '2'],
    ['1', '3', '5', '2', '4'],
    ['1', '3', '5', '4', '2'],
    ['1', '4', '2', '3', '5'],
    ['1', '4', '2', '5', '3'],
    ['1', '4', '3', '2', '5'],
    ['1', '4', '3', '5', '2'],
    ['1', '4', '5', '2', '3'],
    ['1', '4', '5', '3', '2'],
    ['1', '5', '2', '3', '4'],
    ['1', '5', '2', '4', '3'],
    ['1', '5', '3', '2', '4'],
    ['1', '5', '3', '4', '2'],
    ['1', '5', '4', '2', '3'],
    ['1', '5', '4', '3', '2'],
];

my @got_9 = $g8->hamiltonian_walks(allow_reversals => 1);

is_deeply(\@got_9, $expected_9,
    "Twenty-four (24) walks in K5 (reversals allowed)");

# Local Variables:
# compile-command: "cd .. && perl t/24-ham.t"
# End:
