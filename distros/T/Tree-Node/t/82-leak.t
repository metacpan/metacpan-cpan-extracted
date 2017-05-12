#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan skip_all => "Enable DEVEL_TESTS environent variable"
  unless ($ENV{DEVEL_TESTS});

eval "use Devel::Leak";

plan skip_all => "Devel::Leak not installed" if ($@);

plan tests => 2;

use_ok('Tree::Node', 0.06, ':p_node');

my @List = sort (1..10);

my $handle;
my $start = Devel::Leak::NoteSV($handle);

# The problem is to test for memory leaks that aren't from the Perl core

{
  my $first = p_new(1);
  my $count = 0;
  foreach my $k (@List) {
    my $node = p_new(1);
    p_set_key($node, $k);
    p_set_value($node, ++$count);
    p_set_child($node, 0, $first);
    p_destroy($node);
  }
  p_destroy($first);
}

my $finish = Devel::Leak::CheckSV($handle);
my $count  = ($finish-$start);
ok($count== 0, "no leaks");

if ($count) {
  print STDERR "\x23 count = $count\n";
}

