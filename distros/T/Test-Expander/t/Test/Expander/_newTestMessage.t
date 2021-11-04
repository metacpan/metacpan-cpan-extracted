#!/usr/bin/env perl
## no critic (ProtectPrivateSubs RequireLocalizedPunctuationVars)

use v5.14;
use warnings
  FATAL    => qw(all),
  NONFATAL => qw(deprecated exec internal malloc newline once portable redefine recursion uninitialized);

use Test::Expander::Constants qw($NEW_FAILED $NEW_SUCCEEDED);
use constant TEST_CASES => {
  "'new' succeeded" => { exception => '',    output => $NEW_SUCCEEDED },
  "'new' failed"    => { exception => 'ABC', output => $NEW_FAILED },
};
use Test::Builder::Tester tests => scalar(keys(%{TEST_CASES()}));

use Test::Expander;

foreach my $title (keys(%{TEST_CASES()})) {
  test_out("ok 1 - $title");
  $@ = TEST_CASES->{$title}->{exception};
  my $expected = TEST_CASES->{$title}->{output} =~ s/%s/.*/gr;
  like(Test::Expander::_newTestMessage('CLASS'), qr/$expected/, $title);
  test_test($title);
}
