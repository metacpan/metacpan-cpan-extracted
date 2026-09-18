#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  WWW::Picnic
  WWW::Picnic::Result::Categories
  WWW::Picnic::Result::Suggestions
)) {
  use_ok($_);
}

done_testing;
