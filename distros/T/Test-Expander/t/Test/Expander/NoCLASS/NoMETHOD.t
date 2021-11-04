#!/usr/bin/env perl

use v5.14;
use warnings
  FATAL    => qw(all),
  NONFATAL => qw(deprecated exec internal malloc newline once portable redefine recursion uninitialized);

use Test::Expander;

is($CLASS, undef, 'there is no class corresponding to this test file');

done_testing();
