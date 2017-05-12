#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of constant-defer.
#
# constant-defer is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# constant-defer is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with constant-defer.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

{
  use constant::defer foo => sub { print "foo runs\n"; 123 };
  my $x = \&foo;
  { no warnings 'redefine';
    *foo = sub () { print "new foo runs\n"; 456 };
  }
  require Scalar::Util;
  print "func ",$x//'undef',"\n";
  Scalar::Util::weaken ($x);
  print "func ",$x//'undef',"\n";

  my $y = $constant::defer::DEBUG_LAST_RUNNER;
  undef $constant::defer::DEBUG_LAST_RUNNER;

  print "runner ",($y//'undef'),"\n";
  Scalar::Util::weaken ($y);
  print "runner ",($y//'undef'),"\n";
#   if (defined $y) {
#     print "y value ",$y->(),"\n";
#     print "runner ",($y//'undef'),"\n";
#   }
  if (defined $y) {
    require Devel::FindRef;
    print Devel::FindRef::track($y);
  }
  exit 0;
}

