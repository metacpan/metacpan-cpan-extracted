#!/usr/bin/perl

use strict;
use warnings;

use constant MINIMUM_VERSION => '0.02';

use Test::More;

my @Modules = qw(
  Tree::Node
);

plan tests => scalar(@Modules);

foreach my $name (@Modules) {
  use_ok($name, MINIMUM_VERSION);
}



