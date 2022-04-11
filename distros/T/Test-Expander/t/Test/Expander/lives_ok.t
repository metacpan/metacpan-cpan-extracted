#!/usr/bin/env perl

use v5.14;
use warnings
  FATAL    => qw(all),
  NONFATAL => qw(deprecated exec internal malloc newline once portable redefine recursion uninitialized);

use Test::Builder::Tester tests => 1;

use Test::Expander;

my $title = 'execution succeeds';
test_out("ok 1 - $title");
lives_ok(sub {}, $title);
test_test($title);
