#!perl

use strict;
use warnings;
use lib 'lib';
use Test::More tests => 1;
use Cwd;
use YAGL;

my $cwd = getcwd;

# Test 1 - DFS on directed graph

my $g = YAGL->new;
$g->read_csv("$cwd/t/26-exhaustive-search-00.csv");
my @expected = qw/
  a
  b
  c
  e
  f
  d
  g
  h
  i
  k
  j
  l
  m
  m
  l
  l
  j
  k
  i
  h
  g
  m
  m
  j
  k
  i
  h
  g
  d
  f
  e
  c
  g
  h
  i
  k
  j
  l
  m
  m
  l
  l
  j
  k
  i
  h
  g
  m
  m
  j
  k
  i
  h
  g
  f
  d
  b
  c
  e
  g
  h
  i
  k
  j
  l
  m
  m
  l
  l
  j
  k
  i
  h
  g
  m
  m
  j
  k
  i
  h
  g
  e
  c
  b
  d
  g
  h
  i
  k
  j
  l
  m
  m
  l
  l
  j
  k
  i
  h
  g
  m
  m
  j
  k
  i
  h
  g
  g
  e
  c
  b
  d
  f
  f
  d
  b
  c
  l
  j
  k
  i
  h
  m
  m
  j
  k
  i
  h
  h
  i
  k
  j
  l
  e
  c
  b
  d
  f
  f
  d
  b
  c
  m
  m
  l
  e
  c
  b
  d
  f
  f
  d
  b
  c
  /;
my @got;
$g->exhaustive_search( 'a', sub { push @got, $_[0] } );

is_deeply( \@got, \@expected,
"Exhaustive search on the graph in Fig. 44-1 from Sedgewick 2e works as expected."
);

# Local Variables:
# compile-command: "cd .. && perl t/26-exhaustive-search.t"
# End:
