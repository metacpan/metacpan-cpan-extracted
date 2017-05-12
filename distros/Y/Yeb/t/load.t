#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  Yeb
  Yeb::Application
  Yeb::Class
  Yeb::Context
  Yeb::Plugin::Static
)) {
  use_ok($_);
}

done_testing;
