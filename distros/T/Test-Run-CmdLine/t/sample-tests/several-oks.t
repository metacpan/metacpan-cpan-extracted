#!/usr/bin/perl -w

use strict;

use Test::More tests => 3;

# TEST
ok(1, "OK on 1");

# TEST
ok(1, "OK on 2");

my $sum;
for(1 .. 10_000) { $sum += $_; }
# TEST
ok(1, "OK on 3");
