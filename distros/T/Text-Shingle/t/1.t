#! /usr/bin/env perl

use strict;
use Test;

BEGIN { plan tests => 5 };

use Text::Shingle;
ok(1); # If we made it this far, we're loaded.

my $s = Text::Shingle->new();
ok($s); # It got created

{
  my $s = Text::Shingle->new();
  my @shingles = $s->shingle_text("a rose is a rose");
  print '# a rose is a rose => [ (',join(') (',@shingles),') ]',"\n";
  ok(scalar(@shingles) == 3); # ("a rose", "is rose", "a is")... in some order
}

{
  my $s = Text::Shingle->new(w => 2);
  my @shingles = $s->shingle_text("a rose is a rose");
  print '# a rose is a rose => [ (',join(') (',@shingles),') ]',"\n";
  ok(scalar(@shingles) == 3); # ("a rose", "is rose", "a is")... in some order
}

{
  my $s = Text::Shingle->new(w => 3);
  my @shingles = $s->shingle_text("a rose is a rose");
  print '# a rose is a rose => [ (',join(') (',@shingles),') ]',"\n";
  ok(scalar(@shingles) == 1); # ("a is rose")
}

# -*- mode: perl -*-
