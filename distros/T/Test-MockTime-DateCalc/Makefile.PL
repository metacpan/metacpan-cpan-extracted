#!/usr/bin/perl

# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of Test-MockTime-DateCalc.
#
# Test-MockTime-DateCalc is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Test-MockTime-DateCalc is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Test-MockTime-DateCalc.  If not, see <http://www.gnu.org/licenses/>.

require 5; # maybe 5.004 actually
use strict;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Test-MockTime-DateCalc',
   ABSTRACT     => 'Fake date/time for Date::Calc functions.',
   VERSION_FROM => 'lib/Test/MockTime/DateCalc.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   SIGN         => 1,
   PREREQ_PM    => {
                    'Date::Calc' => 4.0,
                    'Test' => 0,
                   },
   MIN_PERL_VERSION => '5',


   META_MERGE =>
   { resources =>
     { homepage =>
       'http://user42.tuxfamily.org/test-mocktime-datecalc/index.html',
     },
     recommends => {
                    # Test::MockTime version 0.10 and 0.11 included
                    # Test::MockTime::DateCalc, so recommend 0.12
                    'Test::MockTime' => '0.12',
                   },
     no_index => {
                  # use of "package Date::Calc" for mangling
                  package => [ 'Date::Calc' ],
                 },

     optional_features =>
     { maximum_tests =>
       { description => 'Have "make test" do as much as possible.',
         requires => { 'Test::MockTime'   => 0,
                       'Sub::Identify'    => 0,
                     },
       },
       maximum_devel =>
       { description => 'Stuff used variously for development.',
         requires => { 'base'          => 0,
                       'constant'      => 0,
                       'Time::Fake'    => 0,
                       'Time::HiRes'   => 0,
                       'Time::Mock'    => 0,
                       'Time::Warp'    => 0,
                       'Devel::Peek'   => 0,
                       'Sub::Identify' => 0,
                     },
       },
     },
   },
  );
