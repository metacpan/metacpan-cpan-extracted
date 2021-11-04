#!/usr/bin/env perl
## no critic (ProtectPrivateSubs)

use v5.14;
use warnings
  FATAL    => qw(all),
  NONFATAL => qw(deprecated exec internal malloc newline once portable redefine recursion uninitialized);

use constant TEST_CASES => {
  'module version required'                => { input => [ '1.22.333' ], output => ' 1.22.333' },
  'single import but not a module version' => { input => [ 'x' ],        output => '' },
  'multiple imports'                       => { input => [ qw(x y) ],    output => '' },
};
use Test::Builder::Tester tests => scalar(keys(%{TEST_CASES()}));

use Test::Expander;

foreach my $title (keys(%{TEST_CASES()})) {
  test_out("ok 1 - $title");
  is(Test::Expander::_useImports(TEST_CASES->{$title}->{input}), TEST_CASES->{$title}->{output}, $title);
  test_test($title);
}
