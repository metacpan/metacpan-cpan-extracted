#!/usr/bin/env perl

use v5.14;
use warnings
  FATAL    => qw(all),
  NONFATAL => qw(deprecated exec internal malloc newline once portable redefine recursion uninitialized);

use constant {
  CLASS      => 'IO::Select',
  TEST_CASES => {
    'no args'       => undef,
    'args supplied' => [ 0 .. 1 ],
  },
};
use Test::Builder::Tester tests => scalar(keys(%{TEST_CASES()}));

use Test::Expander;

eval("use @{[CLASS]}");
foreach my $title (keys(%{TEST_CASES()})) {
  test_out("ok 1 - An object of class '@{[CLASS]}' isa '@{[CLASS]}'");
  new_ok(CLASS, TEST_CASES->{$title}, $title);
  test_test($title);
}
