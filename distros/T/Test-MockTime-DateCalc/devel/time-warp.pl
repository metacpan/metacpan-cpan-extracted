#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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


# Time::Warp is only an export of a time() func, so doesn't get the core
# global override expected by Test::MockTime::DateCalc etc.

use strict;
use warnings;
use Time::HiRes;
use Time::Warp;
use Test::MockTime::DateCalc;
use Date::Calc;

sub tim {
  return Time::HiRes::time();
}

local $,= ' ';
print tim(), " ", Date::Calc::System_Clock(),"\n";
Time::Warp::to(tim()+86400);
print tim(), " ", Date::Calc::System_Clock(),"\n";
Time::Warp::scale(10);
sleep 2;
print tim(), " ", Date::Calc::System_Clock(),"\n";

exit 0;
