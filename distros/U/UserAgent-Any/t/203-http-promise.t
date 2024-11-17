use strict;
use warnings;
use utf8;

use 5.036;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test2::V0 -target => 'UserAgent::Any';
use TestSuite;  # From our the t/lib directory.

BEGIN {
  # The shared memory system used by Promise::Me to exchange data with the
  # parent environment seems flaky and the tests randomly fails (often leaving
  # zombie processes behind). So it’s not executed by default.
  if ($ENV{HARNESS_ACTIVE} && !$ENV{FLAKY_TESTING}) {
    skip_all('Flaky test. Run manually or set $ENV{FLAKY_TESTING} to a true value to run.');
  }
}

BEGIN {
  eval 'use HTTP::Promise';  ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
  skip_all('HTTP::Promise is not installed') if $@;
  # We can’t "use" Promise::Me because it tries to install a source filter and
  # this fails when called in an eval block.
  eval 'require Promise::Me';  ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
  skip_all('Promise::Me is not installed') if $@;
}

BEGIN {
  # Here, we now that Promise::Me was successfully imported, so now we can
  # "import" it.
  Promise::Me->import();
}

$Promise::Me::SHARE_MEDIUM = 'memory';

sub get_ua {
  my $underlying_ua = HTTP::Promise->new();
  return UserAgent::Any->new($underlying_ua);
}

my $done : shared = 0;
TestSuite::run(\&get_ua, sub { 1 until $done; $done = 0 }, sub { $done = 1 });

done_testing;
