#! /usr/bin/env perl

use strict;
use Test;

BEGIN { plan tests => 14 };

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
  my @ngrams = $n->ngrams_text(3, "a rose is a flower");
  print "# a rose is a flower => [ ";
  for my $ngram (@ngrams) {
    print "(",$ngram->[0],",",$ngram->[1],",",$ngram->[2],") ";
  }
  print "]\n";
  ok(scalar(@ngrams) == 3); # ("a rose is", "rose is a", "is a flower")
}

{
  my @ngrams = $n->ngrams_text(4, "a rose is a flower");
  print "# a rose is a flower => [ ";
  for my $ngram (@ngrams) {
    print "(",$ngram->[0],",",$ngram->[1],",",$ngram->[2],",",$ngram->[3],") ";
  }
  print "]\n";
  ok(scalar(@ngrams) == 2); # ("a rose is a", "rose is a flower")
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
  my @skipgrams = $n->skipgrams_text(3, 1, "a rose is a flower");
  print "# a rose is a flower => [ ";
  for my $skipgram (@skipgrams) {
    print "(",$skipgram->[0],",",$skipgram->[1],",",$skipgram->[2],") ";
  }
  print "]\n";
  ok(scalar(@skipgrams) == 1); # ("a is flower")
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
  my @skipgrams = $n->skipgrams_text(3, 2, "a rose is a flower");
  print "# a rose is a flower => [ ";
  for my $skipgram (@skipgrams) {
    print "(",$skipgram->[0],",",$skipgram->[1],",",$skipgram->[2],") ";
  }
  print "]\n";
  ok(scalar(@skipgrams) == 0); # ()
}

{
  my @skipgrams = $n->skipgrams_text(3, 2, "a rose is a flower that has a good smell");
  print "# a rose is a flower that has a good smell=> [ ";
  for my $skipgram (@skipgrams) {
    print "(",$skipgram->[0],",",$skipgram->[1],",",$skipgram->[2],") ";
  }
  print "]\n";
  ok(scalar(@skipgrams) == 4); # ("a a has", "rose flower a", "is that good", "a has smell")
}

{
  my @skipgrams = $n->skipgrams_text(4, 2, "a rose is a flower that has a good smell");
  print "# a rose is a flower that has a good smell=> [ ";
  for my $skipgram (@skipgrams) {
    print "(",$skipgram->[0],",",$skipgram->[1],",",$skipgram->[2],",",$skipgram->[3],") ";
  }
  print "]\n";
  ok(scalar(@skipgrams) == 1); # ("a a has smell")
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
