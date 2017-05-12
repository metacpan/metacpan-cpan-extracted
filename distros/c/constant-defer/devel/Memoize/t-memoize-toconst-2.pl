#!/usr/bin/perl

# Copyright 2008, 2009 Kevin Ryde

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

sub foo {
  print "foo runs\n";
  return (123, 456);
}
my $got = foo();
print "got $got\n";

print "\n";

sub bar {
  print "bar runs\n";
  return (123, 456);
}
use Memoize::ToConstant 'bar';
$got = bar();
print "got $got\n";
$got = bar();
print "got $got\n";

exit 0;
