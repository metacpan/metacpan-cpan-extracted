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


# Try Module::Util::Masked mangling of Module::Util with
# Test::Without::Module removing available modules.

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

if (! eval { require Test::Without::Module; 1 }) {
  MyTestHelpers::diag ('Test::Without::Module not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('Test::Without::Module not available', 1, 1);
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
# find_in_namespace()

{
  unshift @INC, 't/lib';

  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (scalar(@filenames), 2); }

  eval 'use Test::Without::Module q{Module_Util_Masked_test::Two}; 1' or die;

  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (join(',',@filenames), 'Module_Util_Masked_test::One',
        'find_in_namespace() now only one'); }

  eval 'use Test::Without::Module q{Module_Util_Masked_test::One}; 1' or die;

  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (join(',',@filenames), '',
        'find_in_namespace() now none'); }

  unshift @INC, 'no-such-directory';
  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (join(',',@filenames), '',
        'find_in_namespace() none with no-such-directory'); }
  shift @INC;

  while (ref $INC[0]) { push @INC, shift @INC; }
  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (scalar(@filenames), 2); }
  while (ref $INC[-1]) { unshift @INC, pop @INC; }

  eval 'no Test::Without::Module q{Module_Util_Masked_test::One}, q{Module_Util_Masked_test::Two}; 1' or die;

  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ok (scalar(@filenames), 2); }
}


#------------------------------------------------------------------------------
# find_installed()

{
  ok (defined(Module::Util::find_installed('SelectSaver')), 1,
      'find_installed() not masked');

  eval 'use Test::Without::Module q{SelectSaver}; 1' or die;

  ok (Module::Util::find_installed('SelectSaver'), undef,
      'find_installed() masked');

  while (ref $INC[0]) { push @INC, shift @INC; }
  ### shuffle INC: @INC
  ok (defined(Module::Util::find_installed('SelectSaver')), 1,
      'find_installed() not masked when at end of INC');
  while (ref $INC[-1]) { unshift @INC, pop @INC; }
  ### restore INC: @INC

  eval 'no Test::Without::Module q{SelectSaver}; 1' or die;

  ok (defined(Module::Util::find_installed('SelectSaver')), 1,
      'find_installed() not masked');
}


#------------------------------------------------------------------------------
# all_installed()

{
  { my @filenames = Module::Util::all_installed('SelectSaver');
    ok (scalar(@filenames) >= 1, 1); }

  eval 'use Test::Without::Module q{SelectSaver}; 1' or die;

  { my @filenames = Module::Util::all_installed('SelectSaver');
    ok (join(',',@filenames), '', 'all_installed() now not found'); }

  while (ref $INC[0]) { push @INC, shift @INC; }
  ### shuffle INC: @INC
  { my @filenames = Module::Util::all_installed('SelectSaver');
    ok (scalar(@filenames) >= 1, 1,
       'all_installed() with INC shuffled'); }
  while (ref $INC[-1]) { unshift @INC, pop @INC; }
  ### restore INC: @INC

  eval 'no Test::Without::Module q{SelectSaver}; 1' or die;
  my @forbidden = Test::Without::Module::get_forbidden_list();
  ### @forbidden

  { my @filenames = Module::Util::all_installed('SelectSaver');
    ok (scalar(@filenames) >= 1, 1); }
}

exit 0;
