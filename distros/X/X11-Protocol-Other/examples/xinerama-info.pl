#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl xinerama-info.pl
#
# Print some information from the XINERAMA extension, including the layout
# of monitors making up the screen.
#

use 5.004;
use strict;
use X11::Protocol;

my $X = X11::Protocol->new;
if (! $X->init_extension('XINERAMA')) {
  print "No XINERAMA on the server\n";
  exit 0;
}

my ($major, $minor) = $X->PanoramiXQueryVersion (99,99);
print "Xinerama extension version $major.$minor\n";

my $flag = $X->PanoramiXGetState ($X->root);
print "state $flag\n";

my $count = $X->PanoramiXGetScreenCount ($X->root);
print "$count physical monitors\n";

foreach my $i (0 .. $count-1) {
  my ($width, $height) = $X->PanoramiXGetScreenSize ($X->root, $i);
  print "  monitor $i size ${width}x${height}\n";
}

if (($major <=> 1 || $minor <=> 1) >= 0) {
  # Xinerama 1.1 available

  my $active = $X->XineramaIsActive ();
  print "is active $active\n";

  my @rectangles = $X->XineramaQueryScreens ();
  if (@rectangles) {
    print "rectangular areas\n";
    foreach my $i (0 .. $#rectangles) {
      my ($x, $y, $width, $height) = @{$rectangles[$i]};
      print "  monitor $i rectangle at $x,$y size ${width}x${height}\n";
    }
  } else {
    print "no rectangular areas\n";
  }
}

exit 0;
