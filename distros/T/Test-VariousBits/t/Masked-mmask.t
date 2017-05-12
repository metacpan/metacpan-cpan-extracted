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
my $test_count = (tests => 14)[1];
plan tests => $test_count;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Devel::Comments;


if (! eval { require Module::Mask; 1 }) {
  MyTestHelpers::diag ('Module::Mask not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('Module::Mask not available', 1, 1);
  }
  exit 0;
}

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


#------------------------------------------------------------------------------
# find_installed()

{
  ok (defined(Module::Util::find_installed('vars')), 1,
      'find_installed() not masked');

  my $mmask = Module::Mask->new;

  ok (defined(Module::Util::find_installed('vars')), 1,
      'find_installed() not masked');

  $mmask->mask_modules('vars');
  ok (Module::Util::find_installed('vars'), undef,
      'find_installed() masked');

  unshift @INC, splice @INC, 1;
  ok (defined(Module::Util::find_installed('vars')), 1,
      'find_installed() not masked when at end of INC');
  push @INC, splice @INC, 0, -1;
}


#------------------------------------------------------------------------------
# all_installed()

{
  { my @filenames = Module::Util::all_installed('vars');
    ok (scalar(@filenames) >= 1, 1); }

  my $mmask = Module::Mask->new;

  { my @filenames = Module::Util::all_installed('vars');
    ok (scalar(@filenames) >= 1, 1); }

  $mmask->mask_modules('vars');
  { my @filenames = Module::Util::all_installed('vars');
    ok (join(',',@filenames), '', 'all_installed() now not found'); }

  unshift @INC, splice @INC, 1;
  { my @filenames = Module::Util::all_installed('vars');
    ok (scalar(@filenames) >= 1, 1); }
  push @INC, splice @INC, 0, -1;
}

#------------------------------------------------------------------------------
# find_in_namespace()

{
  unshift @INC, 't/lib';

  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (scalar(@filenames), 2); }

  my $mmask = Module::Mask->new;

  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (scalar(@filenames), 2); }

  $mmask->mask_modules('Module_Util_Masked_test::Two');
  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (join(',',@filenames), 'Module_Util_Masked_test::One',
        'find_in_namespace() now only one'); }

  $mmask->mask_modules('Module_Util_Masked_test::One');
  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (join(',',@filenames), '',
        'find_in_namespace() now none'); }

  unshift @INC, 'no-such-directory';
  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (join(',',@filenames), '',
        'find_in_namespace() none with no-such-directory'); }
  shift @INC;

  unshift @INC, splice @INC, 1;
  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (scalar(@filenames), 2); }
  push @INC, splice @INC, 0, -1;
}



exit 0;
