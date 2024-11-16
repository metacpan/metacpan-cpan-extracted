use strict;
use warnings;
use utf8;

use 5.036;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test2::V0 -target => 'UserAgent::Any';
use TestSuite;  # From our the t/lib directory.

BEGIN {
  eval 'use LWP::UserAgent';  ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
  skip_all('LWP::UserAgent is not installed') if $@;
}

sub get_ua {
  my $underlying_ua = LWP::UserAgent->new();
  return UserAgent::Any->new($underlying_ua);
}

{
  my $ua = get_ua();
  isa_ok($ua, ['UserAgent::Any::Impl', 'UserAgent::Any::Impl::LwpUserAgent']);
  DOES_ok($ua, 'UserAgent::Any');
}

TestSuite::run(\&get_ua);

done_testing;
