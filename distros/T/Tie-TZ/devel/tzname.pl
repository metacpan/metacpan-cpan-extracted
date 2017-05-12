#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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


use strict;
use warnings;
use POSIX;

{
  my ($std, $dst) = POSIX::tzname();
  print "initial $std / $dst\n";
}
{
  tzset();
  my ($std, $dst) = POSIX::tzname();
  print "tzset   $std / $dst\n";
}
{
  $ENV{'TZ'} = 'GMT';
  my ($std, $dst) = POSIX::tzname();
  print "GMT     $std / $dst\n";
}
{
  $ENV{'TZ'} = 'America/New_York';
  my ($std, $dst) = POSIX::tzname();
  print "newyork $std / $dst\n";

  tzset();
  ($std, $dst) = POSIX::tzname();
  print "tzset   $std / $dst\n";
}
exit 0;
