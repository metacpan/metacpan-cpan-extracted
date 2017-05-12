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



# my $symtab = do { no strict 'refs';
#                   \%{"${package}::"} };

BEGIN {
  my $symtab = \%main::;
  my $basename = 'foo';
  print "symtab ",$symtab->{$basename},"\n"; }

sub foo {
  print "foo\n";
  return (123, 456);
}
BEGIN {
  my $symtab = \%main::;
  my $basename = 'foo';
  print "symtab ",$symtab->{$basename},"\n";
}

print "prototype: '",prototype(\&foo)//'undef',"'\n";
print Dumper (\&foo);

use Memoize::ToConstant 'foo';

print "prototype: '",prototype(\&foo)//'undef',"'\n";
print Dumper (\&foo);

print "foo(): ",scalar(foo()),"\n";
print "prototype: '",prototype(\&foo)//'undef',"'\n";
print Dumper (\&foo);
print "foo(): ",scalar(foo()),"\n";
print "prototype: '",prototype(\&foo)//'undef',"'\n";
print Dumper (\&foo);

# wantarray
# return

print "\n";

sub bar {
  print "bar runs\n";
  return (123, 456);
}
BEGIN {
print "\n";
  { my $x = bar(); print "bar() x: $x\n"; }
  print "bar() scalar: ",scalar(bar()),"\n";
}
use Memoize::ToConstant 'bar';
print "bar(): ",bar(),"\n";
print "bar(): ",bar(),"\n";

print "\n";

sub quux {
  print "quux runs\n";
  my @x = (123, 456);
  return @x;
}
BEGIN {
  print "\n";
  { my $x = quux(); print "quux() x: $x\n"; }
  print "quux() scalar: ",scalar(quux()),"\n";
  print "\n";
}
use Memoize::ToConstant 'quux';
print "quux(): ",quux(),"\n";
print "quux(): ",quux(),"\n";

exit 0;
