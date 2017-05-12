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

sub Tie_TZ_tzset_not_implemented {
  $Tie_TZ_called = 1;
  $Tie_TZ_argcount += @_;
  require Carp;
  Carp::croak("POSIX::tzset not implemented on this architecture");
}

# POSIX.xs doesn't autoload its funcs does it? only its constants?
# Give tzset() an initial run just in case.
eval { tzset() };
{ no warnings 'redefine';
  *tzset = \&Tie_TZ_tzset_not_implemented;
}


package main;
use strict;
use Test::More tests => 5;
use Tie::TZ qw($TZ);

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

is ($Tie_TZ_called, 0,
    'Tie_TZ_tzset_not_implemented() not yet called');

eval { $TZ = 'ABC+6' };
is ($Tie_TZ_called, 1, 'Tie_TZ_tzset_not_implemented() called');
is ($Tie_TZ_argcount, 0, 'called with no args');

$Tie_TZ_called = 0;
eval { $TZ = 'DEF-6' };
is ($Tie_TZ_called, 0,
    'Tie_TZ_tzset_not_implemented() not called second time');


is (\&POSIX::tzset,
    \&POSIX::Tie_TZ_tzset_not_implemented,
    "not-implemented stuff doesn't change actual POSIX::tzset");

exit 0;
