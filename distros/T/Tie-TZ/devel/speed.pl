#!/usr/bin/perl -w

# Copyright 2007, 2008, 2010 Kevin Ryde

# This file is part of Tie-TZ.
#
# Tie-TZ is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Tie-TZ is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Tie-TZ.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./speed.pl
#
# Measure the relative speeds of Tie::TZ and DateTime::TimeZone.
#
# For me DateTime is about 3.5 times faster in a hard loop like this.  One
# of the worst things about glibc is that it re-reads a /usr/share/zoneinfo/
# file on every change.  Probably that's not too bad for the normal case of
# relatively few zone changes in a program, but if you're going around the
# world it makes DateTime a much more likely proposition.
#

use strict;
use warnings;
use List::Util qw(min max);
use POSIX ();
use Time::HiRes;

use Tie::TZ;
use DateTime;
use DateTime::TimeZone;

use constant TARGET_DURATION => 5; # seconds

sub speed {
  my ($subr) = @_;
  my $t = 0;
  my $runs = 1;

  &$subr(); # warmup

  for (;;) {
    print "  $runs runs";
    my $s = Time::HiRes::time();
    foreach (1 .. $runs) {
      &$subr();
    }
    my $e = Time::HiRes::time();
    $t = $e - $s;
    my $each = $t / $runs;
    printf " took %.6f, is %.3f milliseconds each, %.1f/sec\n",
      $t, $each * 1000.0, 1.0 / $each;

    if ($t > TARGET_DURATION) {
      last;
    }
    if ($t == 0) {
      $runs *= 5;
    } else {
      $runs = max ($runs * 2, POSIX::ceil(TARGET_DURATION * 1.05 / $t));
    }
  }
  return $t / $runs;
}

# about 1.13ms each
print "Tie::TZ\n";
$Tie::TZ::TZ = 'America/New_York';
my $tz_func = sub { local $Tie::TZ::TZ = 'Europe/London'; return 0 };
my $tie_tz_each = speed ($tz_func);

# about 0.36ms each
print "DateTime::TimeZone\n";
my $dttz = DateTime::TimeZone->new (name => 'Europe/London');
my $dt = DateTime->now();
my $dt_func = sub { $dttz->offset_for_datetime($dt) };
my $datetime_each = speed ($dt_func);

if ($tie_tz_each > $datetime_each) {
  printf "DateTime is %.2f times faster\n", $tie_tz_each / $datetime_each;
} else {
  printf "TZ is %.2f times faster\n", $datetime_each / $tie_tz_each;
}


print "\n";
use Benchmark ':hireswallclock';
my $bench = {'Tie::TZ'            => $tz_func,
             'DateTime::TimeZone' => $dt_func,
            };
Benchmark::timethese (-5, $bench);
Benchmark::cmpthese (-5, $bench);


exit 0;
