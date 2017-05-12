#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2015 Kevin Ryde

# This file is part of constant-defer.
#
# constant-defer is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# constant-defer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with constant-defer.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl instance.pl
#
# This program is an example of how to press constant::defer into service
# for a once-only "singleton" object instance creation.
#
# The creation code here is entirely within the instance() routine so after
# it's run it's discarded, which may save a few bytes of memory.  If you
# wanted other non-singleton object instances as well as the shared one then
# you'd make a separate new() in the usual way.
#
# The $class parameter can help subclassing.  A call like
#
#     MyClass::SubClass->instance
#
# blesses into the given subclass name.  But effectively there's only one
# instance behind the two MyClass and MyClass::SubClass and whichever runs
# first is the class created.  If you only ever want one of the two then
# that can be fine, otherwise it might be very confusing.
#
# Further arguments could be passed to the instance() creation, but they
# affect the first call, so may be more confusing than flexible.
#
# Generally Class::Singleton or Class::Singleton::Weak are better for this
# sort of thing, but if you have constant::defer for other uses anyway then
# this is compact and cute.
#

package MyClass;
use strict;

use constant::defer instance => sub {
  my ($class) = @_;
  return bless { foo => 123 }, $class;
};
sub do_something {
  print "do something ...\n";
}

package main;
printf "instance %s\n", MyClass->instance;
printf "instance %s\n", MyClass->instance;

my $obj = MyClass->instance;
$obj->do_something;

exit 0;
