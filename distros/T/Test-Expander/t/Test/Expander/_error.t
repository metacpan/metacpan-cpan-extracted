#!/usr/bin/env perl
## no critic (ProtectPrivateSubs RequireLocalizedPunctuationVars)

use v5.14;
use warnings
  FATAL    => qw(all),
  NONFATAL => qw(deprecated exec internal malloc newline once portable redefine recursion uninitialized);

use Test::Expander::Constants qw($ERROR_WAS);
use constant TEST_CASES => {
  'no exception'                              => { exception => '',    args => [],        output => '' },
  'exception raised, no replacement required' => { exception => 'ABC', args => [],        output => "${ERROR_WAS}ABC" },
  'exception raised, replacement required'    => { exception => 'ABC', args => [qw(B b)], output => "${ERROR_WAS}AbC" },
};
use Test::Builder::Tester tests => scalar(keys(%{TEST_CASES()}));

use Test::Expander;

foreach my $title (keys(%{TEST_CASES()})) {
  test_out("ok 1 - $title");
  $@ = TEST_CASES->{$title}->{exception};
  is(
    Test::Expander::_error(@{TEST_CASES->{$title}->{args}}),
    TEST_CASES->{$title}->{output},
    $title
  );
  test_test($title);
}
