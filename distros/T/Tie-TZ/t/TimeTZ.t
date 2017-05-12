#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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
use Test::More tests => 14;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Time::TZ;


#------------------------------------------------------------------------------
# name()

{
  my $tz = Time::TZ->new (name => 'Greenwich Mean Time',
                          tz => 'GMT');
  is ($tz->name, 'Greenwich Mean Time', 'GMT name');
}


#------------------------------------------------------------------------------
# choose

{
  my $tz = Time::TZ->new (choose => [ 'some bogosity', 'GMT' ]);
  is ($tz->tz, 'GMT', 'choose not some bogosity');
}
{
  my $tz = Time::TZ->new (choose => [ 'EST-10', 'GMT' ]);
  is ($tz->tz, 'EST-10', 'choose EST-10');
}

{
  require POSIX;
  foreach ('GMT',
           'EST-10',
           'first bogosity',
           'second bogosity',
           'America/New_York',
           'Europe/London') {
    my $tz = $_;
    local $ENV{'TZ'} = $tz;
    diag "ctime ",POSIX::ctime(time())," in TZ='$tz'";
  }
}

#------------------------------------------------------------------------------
# call()

{
  local $ENV{'TZ'} = 'BST+1';
  my $tz = Time::TZ->new (name => 'test GMT',
                          tz => 'GMT');

  $tz->call (sub { is ($ENV{'TZ'}, 'GMT'); });
  is ($ENV{'TZ'}, 'BST+1', "restored after normal return");

  ## no critic (RequireCheckingReturnValueOfEval)
  eval {
    $tz->call (sub {
                 is ($ENV{'TZ'}, 'GMT');
                 die "foo";
               });
  };
  is ($ENV{'TZ'}, 'BST+1', "restored after die");
}

#------------------------------------------------------------------------------
# tz_known()

foreach (['GMT', 1],
         ['UTC', 1],
         ['EST+10',    1],
         ['EST+10EDT', 1],
         ['CST+6CDT,M3.2.0,M11.1.0', 1],
         ['CST+6,M3.2.0,M11.1.0',    1],
         ['some bogosity', 0],
        ) {
  my $elem = $_;
  my ($tz, $want) = @$elem;
  is (Time::TZ->tz_known($tz) ? 1 : 0, $want,
      "tz_known() $tz");
}

foreach ('Africa/Accra',
         ':Africa/Accra',
         ':/usr/share/zoneinfo/Africa/Accra',
         'BlahBlah') {
  my $tz = $_;
  diag "tz_known('$tz') is ",(Time::TZ->tz_known($tz) ? 1 : 0);
}

exit 0;
