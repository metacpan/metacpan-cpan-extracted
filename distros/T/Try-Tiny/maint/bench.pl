#!/usr/bin/env perl

use warnings;
use strict;

use Benchmark::Dumb ':all';
use Try::Tiny;

my $max = 10_000;

cmpthese('0.003', {
  eval => sub { do { local $@; eval { die 'foo' } } for (1..$max) },
  try => sub { do { try { die 'foo' } } for (1..$max) },
});
