#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of Test-MockTime-DateCalc.
#
# Test-MockTime-DateCalc is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Test-MockTime-DateCalc is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Test-MockTime-DateCalc.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Test;
BEGIN {
  plan tests => 20;
}

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $fake_time_t;
my $overridden_time;

BEGIN {
  $overridden_time = 0;
  *CORE::GLOBAL::time = sub () {
    $overridden_time++;
    return $fake_time_t;
  };
}

use Test::MockTime::DateCalc;
use Date::Calc;

{
  my $want_version = 6;
  ok ($Test::MockTime::DateCalc::VERSION,
      $want_version,
      'VERSION variable');

 SKIP: {
    $] >= 5.004
      or skip 'UNIVERSAL->VERSION new in 5.004', 3;

    ok (Test::MockTime::DateCalc->VERSION,
        $want_version,
        'VERSION class method');
    ok (eval { Test::MockTime::DateCalc->VERSION($want_version); 1 },
        1,
        "VERSION class check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { Test::MockTime::DateCalc->VERSION($check_version); 1 },
        1,
        "VERSION class check $check_version");
  }
}

{
  ## no critic (RequireCheckingReturnValueOfEval)
  require POSIX;
  eval { POSIX::tzset() }; # can die with "not implemented"
  print STDERR
    "# TZ is '", (defined $ENV{TZ} ? $ENV{TZ} : 'undef'), "'\n";
}

sub numeq_array {
  my ($a1, $a2) = @_;
  while (@$a1 && @$a2) {
    if ($a1->[0] ne $a2->[0]) {
      return 0;
    }
    shift @$a1;
    shift @$a2;
  }
  return (@$a1 == @$a2);
}

#------------------------------------------------------------------------------

my $fake_str = "10 Jan 1990 12:30:00 GMT";
require Time::Local;
#                                   S  M  H   D M Y
$fake_time_t = Time::Local::timegm (0,30,12, 10,0,90);
print STDERR
  "# gmtime($fake_time_t) is ", join(' ',gmtime($fake_time_t)), "\n";


{
  my $func = 'System_Clock';
  $overridden_time = 0;
  my @got = Date::Calc::System_Clock(1);
  print STDERR '# ', join(' ',@got), "\n";
  ok ($overridden_time, 1, 'fake time() called - System_Clock');
  ok (numeq_array(\@got, [1990,1,10, 12,30,0, 10,3,0]),
      1,
      "$fake_str - $func");
}
{
  my $func = 'Today';
  $overridden_time = 0;
  my @got = Date::Calc::Today(1);
  ok ($overridden_time, 1, "fake time() called - $func");
  ok (numeq_array(\@got, [1990,1,10]),
      1,
      "$fake_str - $func");
}
{
  my $func = 'Now';
  $overridden_time = 0;
  my @got = Date::Calc::Now(1);
  ok ($overridden_time, 1, "fake time() called - $func");
  ok (numeq_array(\@got, [12,30,0]),
      1,
      "$fake_str - $func");
}
{
  my $func = 'Today_and_Now';
  $overridden_time = 0;
  my @got = Date::Calc::Today_and_Now(1);
  ok ($overridden_time, 1, "fake time() called - $func");
  ok (numeq_array(\@got, [1990,1,10, 12,30,0]),
      1,
      "$fake_str - $func");
}
{
  my $func = 'This_Year';
  $overridden_time = 0;
  my @got = Date::Calc::This_Year(1);
  ok ($overridden_time, 1, "fake time() called - $func");
  ok (numeq_array(\@got, [1990]),
      1,
      "$fake_str - $func");
}
{
  my $func = 'Gmtime';
  $overridden_time = 0;
  my @got = Date::Calc::Gmtime();
  ok ($overridden_time, 1, "fake time() called - $func");
  ok (numeq_array(\@got, [1990,1,10, 12,30,0, 10,3,0]),
      1,
      "$fake_str - $func");
}
{
  my $func = 'Localtime';
  $overridden_time = 0;
  my @got = Date::Calc::Localtime();
  ok ($overridden_time, 1, "fake time() called - $func");
  # ok (numeq_array(\@got, [1990,1,10, 12,30,0, 10,3,0]),
      # 1,
      # "$fake_str - $func");
}
{
  my $func = 'Timezone';
  $overridden_time = 0;
  my @got = Date::Calc::Timezone();
  ok ($overridden_time, 1, "fake time() called - $func");
  # FIXME: not sure can reliably force a timezone to check this
  # ok (numeq_array(\@got, [0,0,0, 1,0,0, 0]),
  #    1,
  #   "$fake_str - Timezone");
}
{
  my $func = 'Time_to_Date';
  $overridden_time = 0;
  my @got = Date::Calc::Time_to_Date();
  ok ($overridden_time, 1, "fake time() called - $func");
  # FIXME: is this right for old MacOS, or is it local time?
  ok (numeq_array(\@got, [1990,1,10, 12,30,0]),
      1,
      "$fake_str - $func");
}

exit 0;
