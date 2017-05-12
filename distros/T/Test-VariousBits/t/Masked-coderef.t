#!/usr/bin/perl -w

# Copyright 2011, 2015 Kevin Ryde

# This file is part of Test-VariousBits.
#
# Test-VariousBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Test-VariousBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Test-VariousBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
my $test_count = (tests => 3)[1];
plan tests => $test_count;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Devel::Comments;


if (! eval { require Scalar::Util; 1 }) {
  MyTestHelpers::diag ('Scalar::Util not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('Scalar::Util not available', 1, 1);
  }
  exit 0;
}

if (! eval { require Module::Util; 1 }) {
  MyTestHelpers::diag ('Module::Util not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('Module::Util not available', 1, 1);
  }
  exit 0;
}

require Module::Util::Masked;


sub my_inc_subr {
  my ($self, $filename) = @_;
  return;
}
unshift @INC, \&my_inc_subr;

#------------------------------------------------------------------------------
# find_installed()

{
  ok (defined(Module::Util::find_installed('vars')), 1,
      'find_installed() not masked');
}


#------------------------------------------------------------------------------
# all_installed()

{
  { my @filenames = Module::Util::all_installed('vars');
    ok (scalar(@filenames) >= 1, 1); }
}

#------------------------------------------------------------------------------
# find_in_namespace()

{
  unshift @INC, 't/lib';

  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (scalar(@filenames), 2); }
}

exit 0;
