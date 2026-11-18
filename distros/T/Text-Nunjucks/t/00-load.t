#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  Text::Nunjucks
)) {
  use_ok($_);
}

done_testing;
