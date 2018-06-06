#! /usr/bin/env perl

use strict;
use Test;

BEGIN { plan tests => 8 };

use Text::NGrammer;
ok(1); # If we made it this far, we're loaded.

my $n = Text::NGrammer->new();
ok($n); # It got created

{
  my @ngrams = $n->ngrams_text(2, "a rose is a flower");
  print "# a rose is a flower => [ ";
  for my $ngram (@ngrams) {
    print "(",$ngram->[0],",",$ngram->[1],") ";
  }
  print "]\n";
  ok(scalar(@ngrams) == 4); # ("a rose", "rose is", "is a", "a flower")
}

{
  my @skipgrams = $n->skipgrams_text(2, 1, "a rose is a flower");
  print "# a rose is a flower => [ ";
  for my $skipgram (@skipgrams) {
    print "(",$skipgram->[0],",",$skipgram->[1],") ";
  }
  print "]\n";
  ok(scalar(@skipgrams) == 3); # ("a is", "rose a", "is flower")
}

{
  my @skipgrams = $n->skipgrams_text(2, 2, "a rose is a flower");
  print "# a rose is a flower => [ ";
  for my $skipgram (@skipgrams) {
    print "(",$skipgram->[0],",",$skipgram->[1],") ";
  }
  print "]\n";
  ok(scalar(@skipgrams) == 2); # ("a a", "rose flower")
}

{
  my @skipgrams = $n->skipgrams_text(2, 3, "a rose is a flower");
  print "# a rose is a flower => [ ";
  for my $skipgram (@skipgrams) {
    print "(",$skipgram->[0],",",$skipgram->[1],") ";
  }
  print "]\n";
  ok(scalar(@skipgrams) == 1); # ("a flower")
}

{
  my @skipgrams = $n->skipgrams_text(2, 0, "a rose is a flower");
  print "# a rose is a flower => [ ";
  for my $skipgram (@skipgrams) {
    print "(",$skipgram->[0],",",$skipgram->[1],") ";
  }
  print "]\n";
  ok(scalar(@skipgrams) == 4); # ("a rose", "rose is", "is a", "a flower")
}

{
  my $croaked = 0;
  eval { my @ignore = $n->skipgrams_text(2, -1, "a rose is a flower"); };
  if ($@) { $croaked = 1; }
  ok($croaked == 1);
}

# -*- mode: perl -*-
