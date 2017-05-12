#!/usr/bin/perl -w

# Copyright 2015 Kevin Ryde

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
use Smart::Comments;

{
  package Foo;
  use constant FOO => 123;
  use constant BAR => 456;
  print FOO +1;
  print "\n";
}
{
  package Foo;
  use constant::lexical FOO => 123;
  use constant::lexical BAR => 456;
  print FOO +1;
  print "\n";

  sub S { 456 };
  sub T () { 456 };
  ### proto FOO: prototype(\&FOO)
  ### proto S: prototype(\&S)
  ### proto T: prototype(\&T)
  exit 0;
}
