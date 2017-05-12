#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
use Tie::TZ;
use Test::More tests => 40;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $want_version = 9;
is ($Tie::TZ::VERSION, $want_version, 'VERSION variable');
is (Tie::TZ->VERSION,  $want_version, 'VERSION class method');
{ ok (eval { Tie::TZ->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Tie::TZ->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

diag "perl $]";

diag ('set: delete ENV');
{ delete $ENV{'TZ'};
  my $got = $Tie::TZ::TZ;
  is ($ENV{'TZ'}, undef);
  ok (! exists $ENV{'TZ'});
  is ($got, undef);
  is ($Tie::TZ::TZ, undef);
}

diag ('set: $ENV = GMT');
{ $ENV{'TZ'} = 'GMT';
  my $got = $Tie::TZ::TZ;
  is ($ENV{'TZ'}, 'GMT');
  is ($got, 'GMT');
  is ($Tie::TZ::TZ, 'GMT');
}

# Assigning undef into %ENV provokes a warning "Use of uninitialized value
# in scalar assignment" prior to perl 5.10, or some such.  Guess undef has
# no meaning for putenv, though the Tie::TZ code should be ok on it.
#
# diag ('set: $ENV = undef');
# { $ENV{'TZ'} = undef;
#   my $got = $Tie::TZ::TZ;
#   is ($ENV{'TZ'}, undef);
#   is ($got, undef);
#   is ($Tie::TZ::TZ, undef);
# }

diag ('set: $TZ = UTC');
{ $Tie::TZ::TZ = 'UTC';
  my $got = $Tie::TZ::TZ;
  is ($ENV{'TZ'}, 'UTC');
  is ($got, 'UTC');
  is ($Tie::TZ::TZ, 'UTC');
}

diag ('set: $TZ = GMT');
{ $Tie::TZ::TZ = 'GMT';
  my $got = $Tie::TZ::TZ;
  is ($ENV{'TZ'}, 'GMT');
  is ($got, 'GMT');
  is ($Tie::TZ::TZ, 'GMT');
}

diag ('set: $TZ = undef');
{ $Tie::TZ::TZ = undef;
  my $got = $Tie::TZ::TZ;
  ok (! exists $ENV{'TZ'},
     'assigning undef to $TZ deletes from $ENV');
  is ($got, undef);
  is ($Tie::TZ::TZ, undef);
}

diag ('set ENV = UTC, then local TZ = GMT, then local TZ = EST');
$ENV{'TZ'} = 'UTC';
{ { local $Tie::TZ::TZ = 'GMT';
    my $got = $Tie::TZ::TZ;
    is ($ENV{'TZ'}, 'GMT');
    is ($got, 'GMT');
    is ($Tie::TZ::TZ, 'GMT');

    { local $Tie::TZ::TZ = 'EST+10';
      $got = $Tie::TZ::TZ;
      is ($ENV{'TZ'}, 'EST+10');
      is ($got, 'EST+10');
      is ($Tie::TZ::TZ, 'EST+10');
    }

    $got = $Tie::TZ::TZ;
    is ($ENV{'TZ'}, 'GMT');
    is ($got, 'GMT');
    is ($Tie::TZ::TZ, 'GMT');
  }
  my $got = $Tie::TZ::TZ;
  is ($ENV{'TZ'}, 'UTC');
  is ($got, 'UTC');
  is ($Tie::TZ::TZ, 'UTC');
}

diag ('set ENV = UTC, then local TZ = GMT, with die out of eval');
{ $ENV{'TZ'} = 'UTC';
  eval { local $Tie::TZ::TZ = 'GMT';
         my $got = $Tie::TZ::TZ;
         is ($ENV{'TZ'}, 'GMT');
         is ($got, 'GMT');
         is ($Tie::TZ::TZ, 'GMT');
         die; };
  my $got = $Tie::TZ::TZ;
  is ($ENV{'TZ'}, 'UTC');
  is ($got, 'UTC');
  is ($Tie::TZ::TZ, 'UTC');
}


#------------------------------------------------------------------------------

# Return true if setting $ENV{'TZ'} affects what localtime() returns.  As
# noted in the "perlport" pod, on some systems TZ might have no effect at
# all.
#
sub tz_affects_localtime {
  require POSIX;
  $ENV{'TZ'} = 'GMT';
  eval { POSIX::tzset() };
  my (undef, undef, $gmt_hour) = localtime (0);

  $ENV{'TZ'} = 'BST+1';
  eval { POSIX::tzset() };
  my (undef, undef, $bst_hour) = localtime (0);

  diag "tz_affects_localtime(): GMT hour $gmt_hour, BST+1 hour $bst_hour";
  return ($gmt_hour != $bst_hour);
}

SKIP: {
  if (! tz_affects_localtime()) {
    skip 'due to TZ variable having no effect on localtime()', 2;
  }

  # This could be slightly rash on very weird systems, but if BST+1 is
  # different from GMT then it seems fair to assume it's by 1 hour.  The
  # benefit of the test is that it's a real actual run to see assigning
  # through Tie::TZ has the intended effect on localtime().
  #
  $Tie::TZ::TZ = 'GMT';
  my (undef, undef, $gmt_hour) = localtime (0);
  { local $Tie::TZ::TZ = 'BST+1';
    my (undef, undef, $bst_hour) = localtime (0);
    is ($bst_hour, ($gmt_hour - 1 + 24) % 24,
        'BST+1 within local Tie::TZ setting');
  }
  my (undef, undef, $gmt_again_hour) = localtime (0);
  is ($gmt_again_hour, $gmt_hour,
      'GMT hour before and after local Tie::TZ setting');
}

exit 0;
