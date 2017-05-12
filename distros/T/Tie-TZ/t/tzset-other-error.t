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

sub Tie_TZ_tzset_other_error {
  $Tie_TZ_called = 1;
  $Tie_TZ_argcount += @_;
  die "some other kind of error";
}

# POSIX.xs doesn't autoload its funcs does it? only its constants?
# Give tzset() an initial run just in case.
eval { tzset() };
{ no warnings 'redefine';
  *tzset = \&Tie_TZ_tzset_other_error;
}


package main;
use strict;
use Test::More tests => 11;
use Tie::TZ qw($TZ);

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

is ($Tie_TZ_called, 0, 'Tie_TZ_tzset_other_error() not yet called');

{ eval { $TZ = 'ABC+6' };
  my $err = $@;
  is ($Tie_TZ_called, 1, 'Tie_TZ_tzset_other_error() called');
  is ($Tie_TZ_argcount, 0, 'called with no args');
  like ($err, '/some other kind of error/',
        'error message');
}

{ $Tie_TZ_called = 0;
  $Tie_TZ_argcount = 0;
  eval { $TZ = 'DEF-6' };
  my $err = $@;
  is ($Tie_TZ_called, 1, 'Tie_TZ_tzset_other_error() called second time');
  is ($Tie_TZ_argcount, 0, 'called with no args');
  like ($err, qr/some other kind of error/,
        'error message');
}
{ $Tie_TZ_called = 0;
  eval { $TZ = 'GHI-6' };
  my $err = $@;
  is ($Tie_TZ_called, 1, 'Tie_TZ_tzset_other_error() called third time');
  is ($Tie_TZ_argcount, 0, 'called with no args');
  like ($err, qr/some other kind of error/,
        'error message');
}

is (\&POSIX::tzset,
    \&POSIX::Tie_TZ_tzset_other_error,
    "other-error stuff doesn't change actual POSIX::tzset");

exit 0;
