#!perl

use strict;
use warnings;
use lib 'lib';
use Test::More tests => 6;
use Cwd;
use YAGL;

my $cwd = getcwd;

# Test 1 - DFS on directed graph

my $g = YAGL->new(is_directed => 1);
$g->read_csv("$cwd/t/25-dfs-00.csv");

my @expected = qw/a b f e d g c j k l m/;
my @got;
$g->dfs('a', sub { push @got, $_[0] });

is_deeply(\@got, \@expected, "DFS on a connected, directed graph");

# Test 2 - DFS on an undirected graph (that also has a Hamiltonian path, btw)

my $h = YAGL->new;
$h->read_csv("$cwd/t/25-dfs-01.csv");

my @expected2 = qw/a b c d e f g h i j k/;
my @got2;
$h->dfs('a', sub { push @got2, $_[0] });

is_deeply(\@got2, \@expected2, "DFS on a connected, undirected graph");

# Test 3 - DFS on the graph in Fig. 44-1 from Sedgewick, 2nd ed.

my $gg = YAGL->new;
$gg->read_csv("$cwd/t/25-dfs-02.csv");

my @expected3 = qw/a b c e f d g h i k j l m/;
my @got3;
$gg->dfs('a', sub { push @got3, $_[0] });

is_deeply(\@got3, \@expected3,
    "DFS on the graph from Fig. 44-1 in Sedgewick, 2e");

# Test 4 - DFS on the same graph as Test 1, except that it is no
# longer connected (it has 2 connected components).

my $g4 = YAGL->new(is_directed => 1);

$g4->read_csv("$cwd/t/25-dfs-03.csv");

my @expected4 = qw/a b f e d g c j k l m/;
my @got4;
$g4->dfs('a', sub { push @got4, $_[0] });

is_deeply(\@got4, \@expected4, "DFS on an unconnected, directed graph");

# Test 5 - DFS on the same graph as Test 4, except that it is
# undirected.

my $g5 = YAGL->new;

$g5->read_csv("$cwd/t/25-dfs-04.csv");

my @expected5 = qw/a b f e d g c j k l m/;
my @got5;
$g5->dfs('a', sub { push @got5, $_[0] });

is_deeply(\@got5, \@expected5, "DFS on an unconnected, undirected graph");

# Test 6 - DFS on a graph that we know the DFS from by checking it against Mathematica.

my $g6 = YAGL->new;
$g6->read_lst("$cwd/t/25-dfs-05.lst");

my @expected6 = (1, 2, 11, 5, 3, 4, 6, 10, 7, 12, 9, 8);

my @got6;
$g6->dfs(1, sub { push @got6, $_[0] });

is_deeply(\@got6, \@expected6,
    "DFS on graph #33128 from hog.grinvin.org (checked against Mathematica)");

# Local Variables:
# compile-command: "cd .. && perl t/25-dfs.t"
# End:
