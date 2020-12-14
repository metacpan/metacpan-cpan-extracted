#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  WWW::Picnic
)) {
  use_ok($_);
}

done_testing;
