#!/usr/bin/env perl

use v5.14;
use warnings
  FATAL    => qw(all),
  NONFATAL => qw(deprecated exec internal malloc newline once portable redefine recursion uninitialized);

use Test::Builder::Tester tests => 1;

use Test::Expander;

use constant CLASS => 'IO::Select';

my $title = "require @{[CLASS]}";
test_out("ok 1 - $title;");
require_ok(CLASS);
test_test($title);
