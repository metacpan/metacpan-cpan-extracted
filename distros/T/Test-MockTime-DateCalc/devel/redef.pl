#!/usr/bin/perl -w

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


package Foo;
use strict;

use Date::Calc ('Today');

sub foo_today {
  return Today();
}

package main;
use Date::Calc;
*Date::Calc::Today = sub {
  print "fake\n";
  return (1980, 1, 1);
};

print Foo::foo_today(),"\n";


my $orig = \&Foo::foo_today;
*Foo::foo_today = sub {
  print "redef\n";
  return 'x';
};
print Foo::foo_today(),"\n";
print &$orig(),"\n";

use Devel::Peek;
Dump($orig);
Dump(\&Foo::foo_today);

exit 0;
