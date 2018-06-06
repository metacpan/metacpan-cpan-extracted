#! /usr/bin/env perl

use strict;
use Test;

BEGIN { plan tests => 3 };

use Text::Shingle;
ok(1); # If we made it this far, we're loaded.

my $s = Text::Shingle->new();
ok($s); # It got created

{
  my @shingles = $s->shingle_text("a rose is a rose");
  print '# a rose is a rose => [ (',join(') (',@shingles),') ]',"\n";
  ok(scalar(@shingles) == 3); # ("a rose", "is rose", "a is")... in some order
}

# -*- mode: perl -*-
