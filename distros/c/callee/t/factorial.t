#!/usr/bin/env perl -l
use warnings;
use strict;
use callee;
use Test::More tests => 1;
my $f = sub {
    my $x = shift;
    return 1 if $x <= 1;
    $x * callee->($x - 1);
  }
  ->(5);
is($f, 120, 'factorial');
