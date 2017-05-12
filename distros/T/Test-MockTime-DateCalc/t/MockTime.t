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
  plan tests => 7;
}

# this is before nowarnings() since Test::MockTime 0.12 gets some warnings
# from perl 5.6.2 about prototype mismatches
my $have_test_mocktime;
my $skip;
BEGIN {
  $have_test_mocktime = eval { require Test::MockTime; 1 } ;
  if (! $have_test_mocktime) {
    print STDERR "# Test::MockTime not available -- $@";
  }
  $skip = ($have_test_mocktime ? undef : 'due to Test::MockTime not available');
}

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Test::MockTime::DateCalc;
use Date::Calc;


my $fake_str = "10 Jan 1990 12:30:00 GMT";
print STDERR "# $fake_str\n";
#                                      S  M  H   D M Y
require Time::Local;
my $fake_time_t = Time::Local::timegm (0,30,12, 10,0,90);
if ($have_test_mocktime) {
  Test::MockTime::set_fixed_time ($fake_time_t);
}
sleep 2;
print STDERR
  "# gmtime($fake_time_t) is ", join(' ',gmtime($fake_time_t)), "\n";

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

{
  my $func = 'System_Clock';
  my @got = Date::Calc::System_Clock(1);
  print STDERR  "# $func ", join(' ',@got), "\n";
  skip ($skip,
        numeq_array(\@got,
                  [1990,1,10, 12,30,0, 10,3,0]),
      1,
      "$fake_str - $func");
}
{
  my $func = 'Today';
  skip ($skip,
        numeq_array([Date::Calc::Today(1)],
                    [1990,1,10]),
        1,
        "$fake_str - $func");
}
{
  my $func = 'Now';
  skip ($skip,
        numeq_array([Date::Calc::Now(1)],
                    [12,30,0]),
        1,
        "$fake_str - $func");
}
{
  my $func = 'Today_and_Now';
  skip ($skip,
        numeq_array([Date::Calc::Today_and_Now(1)],
                    [1990,1,10, 12,30,0]),
        1,
        "$fake_str - $func");
}
{
  my $func = 'This_Year';
  skip ($skip,
        numeq_array([Date::Calc::This_Year(1)],
                    [1990]),
        1,
        "$fake_str - $func");
}
{
  my $func = 'Gmtime';
  skip ($skip,
        numeq_array([Date::Calc::Gmtime()],
                    [1990,1,10, 12,30,0, 10,3,0]),
        1,
        "$fake_str - $func");
}
{
  my $func = 'Localtime';
  # ok (numeq_array([Date::Calc::Localtime()], [1990,1,10, 12,30,0, 10,3,0], "$fake_str - $func");
}
{
  my $func = 'Timezone';
  # FIXME: not sure can reliably force a timezone to check this
  # ok (numeq_array([Date::Calc::Timezone()], [0,0,0, 1,0,0, 0], "$fake_str - Timezone");
}
{
  my $func = 'Time_to_Date';
  # FIXME: is this right for old MacOS, or is it local time?
  skip ($skip,
        numeq_array([Date::Calc::Time_to_Date()],
                    [1990,1,10, 12,30,0]),
        1,
        "$fake_str - $func");
}

exit 0;
