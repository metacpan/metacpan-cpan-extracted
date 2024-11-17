use strict;
use warnings;
use utf8;

use 5.036;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test2::V0 -target => 'UserAgent::Any';
use TestSuite;  # From our the t/lib directory.

BEGIN {
  eval 'use AnyEvent::UserAgent';  ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
  skip_all('AnyEvent::UserAgent is not installed') if $@;
  skip_all('Requires AnyEvent::UserAgent 0.09') if $AnyEvent::UserAgent::VERSION < '0.09';
  eval 'use Promise::XS';  ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
  skip_all('Promise::XS is not installed') if $@;
  eval 'use AnyEvent';  ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
  skip_all('AnyEvent is not installed') if $@;
}

sub get_ua {
  # The Test::HTTP::MockServer that we are using in the test suite does not
  # implement persistent connection and this is not handled correctly by
  # AnyEvent::UserAgent (and/or the underlying AnyEvent::HTTP, it is unclear
  # which lib is at fault).
  #
  # For some repro of the issue, see:
  # https://rt.cpan.org/Ticket/Display.html?id=156970
  #
  # In any case, we can work around it by setting `persistent => 0` so that the
  # library does not even try to reuse the connection.
  my $underlying_ua = AnyEvent::UserAgent->new(persistent => 0);
  return UserAgent::Any->new($underlying_ua);
}

my $cv;
TestSuite::run(\&get_ua, sub { $cv = AnyEvent->condvar; $cv->recv }, sub { $cv->send });

done_testing;
