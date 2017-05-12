use strict;
use warnings;

use Test::More tests=>9;
use_ok 'XML::Stream', qw( Tree Node );

my @tests;
$tests[4] = 1;
$tests[8] = 1;

my $parser_tree = XML::Stream::Parser->new(style=>"tree");
my $tree = $parser_tree->parsefile("t/test.xml");

my %config = %{&XML::Stream::XML2Config($tree)};

if (exists($config{blah})) {
  my @keys = keys(%{$config{blah}});
  if ($#keys == -1) {
    $tests[2] = 1;
  }
}

if (exists($config{foo}->{bar})) {
  my @keys = keys(%{$config{foo}->{bar}});
  if ($#keys == -1) {
    $tests[3] = 1;
  }
}

if (exists($config{comment_test})) {
  $tests[4] = 0;
}


if (exists($config{last}->{test1}->{test2}->{test3})) {
  if ($config{last}->{test1}->{test2}->{test3} eq "This is a test.") {
    $tests[5] = 1;
  }
}


my $parser_node = XML::Stream::Parser->new(style=>"node");
my $node = $parser_node->parsefile("t/test.xml");

%config = %{&XML::Stream::XML2Config($node)};

if (exists($config{blah})) {
  my @keys = keys(%{$config{blah}});
  if ($#keys == -1) {
    $tests[6] = 1;
  }
}

if (exists($config{foo}->{bar})) {
  my @keys = keys(%{$config{foo}->{bar}});
  if ($#keys == -1) {
    $tests[7] = 1;
  }
}

if (exists($config{comment_test})) {
  $tests[8] = 0;
}

if (exists($config{last}->{test1}->{test2}->{test3})) {
  if ($config{last}->{test1}->{test2}->{test3} eq "This is a test.") {
    $tests[9] = 1;
  }
}


foreach (2..9) {
  ok $tests[$_];
}

