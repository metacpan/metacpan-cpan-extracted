#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan skip_all => "Enable DEVEL_TESTS environent variable"
  unless ($ENV{DEVEL_TESTS});

eval "use Devel::Leak";

plan skip_all => "Devel::Leak not installed" if ($@);

plan tests => 2;

use_ok('Tree::Node', 0.05);

my @List = sort (1..10);

my $handle;
my $start = Devel::Leak::NoteSV($handle);

# The problem is to test for memory leaks that aren't from the Perl core

{
  my $first = Tree::Node->new(1);
  my $count = 0;
  foreach my $k (@List) {
    my $node = Tree::Node->new(1);
    $node->set_key($k);
    $node->set_value(++$count);
    $node->set_child(0, $first);
  }
}

my $finish = Devel::Leak::CheckSV($handle);
my $count  = ($finish-$start);
ok($count== 0, "no leaks");

if ($count) {
  print STDERR "\x23 count = $count\n";
}

