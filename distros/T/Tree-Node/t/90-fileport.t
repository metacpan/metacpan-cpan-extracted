#!/usr/bin/perl

use Test::More;

plan skip_all => "Enable DEVEL_TESTS environent variable"
  unless ($ENV{DEVEL_TESTS});

eval "use Test::Portability::Files";

plan skip_all => "Test::Portability::Files required for testing filenames portability" if $@;

run_tests();
