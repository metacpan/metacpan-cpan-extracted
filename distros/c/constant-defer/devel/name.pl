#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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
use Sub::Identify;
use Data::Dumper;

use constant foo => 123;
BEGIN {
  my $symtab = \%main::;
  print Data::Dumper->Dump([$symtab->{'foo'}], ['foo']);
}
print "foo    ",Sub::Identify::sub_fullname(\&foo),"\n";
BEGIN {
  my $symtab = \%main::;
  print Data::Dumper->Dump([$symtab->{'foo'}], ['foo']);
}

our $exglob = 999;
use constant exglob => 123;
print "exglob ",Sub::Identify::sub_fullname(\&exglob),"\n";

use constant::defer bar => sub { 456 };
print "bar    ",Sub::Identify::sub_fullname(\&bar),"\n";

require Glib;
print "FALSE         ",Sub::Identify::sub_fullname(\&Glib::FALSE),"\n";
print "MAJOR_VERSION ",Sub::Identify::sub_fullname(\&Glib::MAJOR_VERSION)," ",Glib::MAJOR_VERSION(),"\n";

1;

