#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2012, 2014, 2015, 2019 Kevin Ryde

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

WriteMakefile
  (NAME          => 'Test::MockTime::DateCalc',
   ABSTRACT      => 'Fake date/time for Date::Calc functions.',
   VERSION_FROM  => 'lib/Test/MockTime/DateCalc.pm',
   AUTHOR        => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   SIGN          => 1,
   PREREQ_PM     => { 'Date::Calc' => 4.0,
                    },
   TEST_REQUIRES => { 'Test' => 0,
                    },
   MIN_PERL_VERSION => '5',


   META_MERGE =>
   { 'meta-spec' => { version => 2 },
     resources =>
     { homepage => 'http://user42.tuxfamily.org/test-mocktime-datecalc/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     recommends => {
                    # Test::MockTime version 0.10 and 0.11 included
                    # Test::MockTime::DateCalc, so recommend 0.12
                    'Test::MockTime' => '0.12',
                   },
     no_index => {
                  # use of "package Date::Calc" for mangling
                  package => [ 'Date::Calc' ],
                  directory=>['devel','xt'],
                 },


     prereqs =>
     { test =>
       { suggests =>
         {
          # have "make test" do as much as possible
          'Test::MockTime' => 0,
          'Sub::Identify'  => 0,
         }
       },
     },
   },
  );
