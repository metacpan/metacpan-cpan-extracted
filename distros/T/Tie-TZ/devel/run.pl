#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

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
use Tie::TZ qw($TZ);
use Devel::Peek;
use Data::Dumper;

{
  require Time::TZ;
  foreach my $str ('GMT',
                   'EST+10',
                   'EST+10EDT',
                   'Africa/Accra',
                   ':Africa/Accra',
                   ':/usr/share/zoneinfo/Africa/Accra') {
    print "$str: ",Time::TZ->tz_known($str),"\n";
  }
  exit 0;
}

{
  print Dump($TZ);
  print Dumper(\$TZ);

  $ENV{'TZ'} = 'EST+10';
  print Dumper($TZ);
  print Dump($TZ);

  exit 0;
}
