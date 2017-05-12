#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Encode;

my $str = "\x85";

for (my $i = 0; $i < length($str); $i++) {
  printf " %02X", ord(substr($str,$i,1));
}
print "\n";

my $charset = 'shift-jis';
Encode::from_to ($str, $charset, $charset);

for (my $i = 0; $i < length($str); $i++) {
  printf " %02X", ord(substr($str,$i,1));
}
print "\n";
