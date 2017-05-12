#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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

use strict;
use warnings;

{
  require Sub::Identify;
  require Test::MockTime::DateCalc;
  print Sub::Identify::sub_name(\&Date::Calc::System_Clock),"\n";
  print Sub::Identify::sub_name(\&Date::Calc::Gmtime),"\n";
}

exit 0;
