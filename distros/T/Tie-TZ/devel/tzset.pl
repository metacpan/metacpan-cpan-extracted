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


use POSIX ();
package POSIX;
use strict;
use warnings;

sub no_good_reason {
  require Data::Dumper;
  print "fake tzset no_good_reason():", Data::Dumper->Dump([\@_],['args']);
  require Carp;
  Carp::croak("no good reason");
}

sub not_implemented {
  require Data::Dumper;
  print "fake tzset not_implemented():", Data::Dumper->Dump([\@_],['args']);
  require Carp;
  Carp::croak("POSIX::tzset not implemented on this architecture");
}

sub success {
  require Data::Dumper;
  print "fake tzset success():", Data::Dumper->Dump([\@_],['args']);
  require Carp;
  Carp::croak("POSIX::tzset not implemented on this architecture");
}

package main;
use strict;
use warnings;
use Tie::TZ qw($TZ);


{ no warnings 'redefine';
  # *POSIX::tzset = \&POSIX::no_good_reason;
  *POSIX::tzset = \&POSIX::not_implemented;
}
eval { $TZ = 'ABC+6' }; print $@;
eval { $TZ = 'DEF-6' }; print $@;
$TZ = 'GHI+0';
print "done\n";
exit 0;

