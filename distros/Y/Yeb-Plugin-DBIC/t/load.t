#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  Yeb::Plugin::DBIC
)) {
  use_ok($_);
}

done_testing;
