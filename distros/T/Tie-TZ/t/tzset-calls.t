#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

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


use POSIX ();
package POSIX;
use strict;

my $Tie_TZ_called = 0;
my $Tie_TZ_argcount = 0;

sub Tie_TZ_tzset_call {
  $Tie_TZ_called = 1;
  $Tie_TZ_argcount += @_;
}

# POSIX.xs doesn't autoload its funcs does it? only its constants?
# Give tzset() an initial run just in case.
eval { tzset() };
{ no warnings 'redefine';
  *tzset = \&Tie_TZ_tzset_call;
}

package main;
use strict;
use Test::More tests => 10;
use Tie::TZ qw($TZ);

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

$ENV{'TZ'} = 'UTC';
{ $Tie_TZ_called = 0;
  $Tie_TZ_argcount = 0;
  $Tie::TZ::TZ = 'UTC';
  is ($Tie_TZ_called, 0, 'UTC -> UTC, should not tzset');
  is ($Tie_TZ_argcount, 0, 'no args to tzset');
}
{ $Tie_TZ_called = 0;
  $Tie_TZ_argcount = 0;
  $Tie::TZ::TZ = 'GMT';
  is ($Tie_TZ_called, 1, 'UTC -> GMT, should tzset');
  is ($Tie_TZ_argcount, 0, 'no args to tzset');
}
{ $Tie_TZ_called = 0;
  $Tie_TZ_argcount = 0;
  $Tie::TZ::TZ = undef;
  is ($Tie_TZ_called, 1, 'GMT -> undef, should tzset');
  is ($Tie_TZ_argcount, 0, 'no args to tzset');
}
{ $Tie_TZ_called = 0;
  $Tie_TZ_argcount = 0;
  $Tie::TZ::TZ = undef;
  is ($Tie_TZ_called, 0, 'undef -> undef, should not tzset');
  is ($Tie_TZ_argcount, 0, 'no args to tzset');
}
{ $Tie_TZ_called = 0;
  $Tie_TZ_argcount = 0;
  $Tie::TZ::TZ = 'UTC';
  is ($Tie_TZ_called, 1, 'undef -> UTC, should tzset');
  is ($Tie_TZ_argcount, 0, 'no args to tzset');
}

exit 0;
