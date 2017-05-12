#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Distlinks.
#
# Distlinks is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Distlinks is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Distlinks.  If not, see <http://www.gnu.org/licenses/>.

use strict;
symlink ('/tmp', '/tmp/foo');

my $dir = '/tmp/foo';
my $count = 1;
for (;;) {
  print "$count $dir\n";
  opendir my $fh, $dir or die $!;
  $dir .= '/foo';
  $count++;
}
