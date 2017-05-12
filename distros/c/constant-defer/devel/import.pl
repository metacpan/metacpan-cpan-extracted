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
use Data::Dumper;
use Scalar::Util;
use FindBin;
use lib::abs $FindBin::Bin;

use MyConstantDeferExport ('my_ctime');

{
  my $orig   = \&my_ctime;
  my $orig_m = \&MyConstantDeferExport::my_ctime;
  print my_ctime(),"\n";
  print MyConstantDeferExport::my_ctime(),"\n";
  my $const   = \&my_ctime;
  my $const_m = \&MyConstantDeferExport::my_ctime;

  print "orig    $orig\n";
  print "orig_m  $orig_m\n";
  print "const   $const\n";
  print "const_m $const_m\n";

  if (defined $constant::defer::DEBUG_LAST_SUBR) {
    print "subr  ",$constant::defer::DEBUG_LAST_SUBR//'undef',"\n";
    Scalar::Util::weaken($constant::defer::DEBUG_LAST_SUBR);
    print "subr  ",$constant::defer::DEBUG_LAST_SUBR//'undef',"\n";
  }
  exit 0;
}
