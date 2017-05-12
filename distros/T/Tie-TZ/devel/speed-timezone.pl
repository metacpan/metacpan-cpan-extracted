#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Tie-TZ.
#
# Tie-TZ is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Tie-TZ is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Tie-TZ.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl speed-timezone.pl
#
# Measure the relative speeds of Time::TZ, raw Tie::TZ, and
# DateTime::TimeZone.
#

use strict;
use warnings;
use List::Util qw(min max);
use Time::HiRes;

use Tie::TZ;
use Time::TZ;
use DateTime;
use DateTime::TimeZone;

sub speed {
  my ($subr) = @_;
  my $t = 0;
  my $runs = 1;

  for (;;) {
    print "  $runs runs";
    my $s = Time::HiRes::time();
    foreach (1 .. $runs) {
      &$subr();
    }
    my $e = Time::HiRes::time();
    $t = $e - $s;
    my $each = $t/$runs;
    my $ms = $each * 1000.0;
    printf " took %.6f, is %.3f milliseconds each\n", $t, $ms;

    if ($t > 2) {
      last;
    }
    if ($t == 0) {
      $runs *= 5;
    } else {
      $runs = max ($runs * 2, int (3.0 / $t + 0.5));
    }
  }
  return $t / $runs;
}

# about 1.24ms each (used to be 0.17ms each without tzset)
{
  print "Time::TZ\n";
  my $timezone = Time::TZ->new (tz => 'Europe/London');
  speed (sub { $timezone->call (sub { return 0; }); });
}

# about 1.15ms each
{
  print "Tie::TZ\n";
  my $tz = 'Europe/London';
  speed (sub { local $Tie::TZ::TZ = $tz; return 0; });
}

# about 0.32ms each
{
  print "DateTime::TimeZone\n";
  my $tz = DateTime::TimeZone->new (name => 'Europe/London');
  my $dt = DateTime->now();
  speed (sub { $tz->offset_for_datetime($dt) });
  exit 0;
}


{
  print "known:",Time::TZ::tz_known('EST+10'),"\n";
  exit 0;
}
{
  my $timezone = Time::TZ->loco;
  print $timezone->iso_date,"\n";
}
{
  my $timezone = Time::TZ->london;
  print $timezone->iso_date,"\n";
}

exit 0;
