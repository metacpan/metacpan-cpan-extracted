#!/usr/bin/perl -w

# Copyright 2011, 2012, 2017 Kevin Ryde

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


# Try Module::Util::Masked mangling of Module::Util with Devel::Unplug
# removing available modules.

use 5.004;
use strict;
use Test;
my $test_count = (tests => 11)[1];
plan tests => $test_count;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Devel::Comments;

if (! eval { require Devel::Unplug; 1 }) {
  MyTestHelpers::diag ('Devel::Unplug not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('Devel::Unplug not available', 1, 1);
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
  ok (defined(Module::Util::find_installed('SelectSaver')), 1,
      'find_installed() not masked');

  Devel::Unplug::unplug('SelectSaver');

  ok (Module::Util::find_installed('SelectSaver'), undef,
      'find_installed() when unplug');

  Devel::Unplug::insert('SelectSaver');

  ok (defined(Module::Util::find_installed('SelectSaver')), 1,
      'find_installed() when re-insert');
}


#------------------------------------------------------------------------------
# all_installed()

{
  { my @filenames = Module::Util::all_installed('SelectSaver');
    ok (scalar(@filenames) >= 1, 1); }

  Devel::Unplug::unplug('SelectSaver');

  { my @filenames = Module::Util::all_installed('SelectSaver');
    ok (join(',',@filenames), '', 'all_installed() when unplug'); }

  Devel::Unplug::insert('SelectSaver');

  { my @filenames = Module::Util::all_installed('SelectSaver');
    ok (scalar(@filenames) >= 1, 1); }
}


#------------------------------------------------------------------------------
# find_in_namespace()

{
  unshift @INC, 't/lib';

  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (scalar(@filenames), 2); }

  Devel::Unplug::unplug('Module_Util_Masked_test::Two');

  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (join(',',@filenames), 'Module_Util_Masked_test::One',
        'find_in_namespace() now only one'); }

  Devel::Unplug::unplug('Module_Util_Masked_test::One');

  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (join(',',@filenames), '',
        'find_in_namespace() now none'); }

  unshift @INC, 'no-such-directory';
  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (join(',',@filenames), '',
        'find_in_namespace() none with no-such-directory'); }
  shift @INC;

  Devel::Unplug::insert('Module_Util_Masked_test::One',
                        'Module_Util_Masked_test::Two');

  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (scalar(@filenames), 2); }
}


exit 0;
