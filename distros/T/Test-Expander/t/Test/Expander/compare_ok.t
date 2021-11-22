#!/usr/bin/env perl

use v5.14;
use warnings
  FATAL    => qw(all),
  NONFATAL => qw(deprecated exec internal malloc newline once portable redefine recursion uninitialized);

use Test::Builder::Tester tests => 1;

use Test::Expander;

$METHOD //= 'compare_ok';
my $dir   = path(__FILE__)->parent->child($METHOD);
my $title = 'execution';
test_out("ok 1 - $title");
compare_ok($dir->child('got'), $dir->child('expected'), $title);
test_test($title);
