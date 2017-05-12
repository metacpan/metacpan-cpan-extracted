#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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

use 5.004;
use strict;
use X11::Protocol;
use X11::Protocol::WM;

# uncomment this to run the ### lines
use Smart::Comments;

# icewm
# jwm
# mwm
# olwm, olvwm


{
  my $X = X11::Protocol->new;
  my $root = $X->root;
  my ($root_root, $root_parent, @toplevels) = $X->QueryTree($root);

  foreach my $frame (@toplevels) {
    printf "%X  frame  ", $frame;
    {
      my %geom = $X->GetGeometry($frame);
      print "$geom{'x'},$geom{'y'}, $geom{'width'},$geom{'height'}";
    }
    print "\n";
    my $window = X11::Protocol::WM::frame_window_to_client($X,$frame);
    if (! $window) {
      printf "  no client\n", $frame;
      next;
    }
    printf "  %X  ", $window;
    {
      my ($value, $type, $format, $bytes_after)
        = $X->GetProperty($window, $X->atom('WM_NAME'), $X->atom('STRING'), 0, 999, 0);
      print $value//'undef';
    }
    my %hints = X11::Protocol::WM::get_wm_hints($X,$window);
    {
      my %geom = $X->GetGeometry($frame);
      print " $geom{'width'},$geom{'height'}";
    }
    print "\n";
    {
      my $icon_pixmap = $hints{'icon_pixmap'}||0;
      printf "    pixmap %X  ", $icon_pixmap;
      if ($icon_pixmap) {
        my %geom = $X->GetGeometry($icon_pixmap);
        print "$geom{'width'},$geom{'height'}";
      }
      print "\n";
    }
    {
      my $icon_window = $hints{'icon_window'}||0;
      printf "  window %X\n", $icon_window;
    }
  }
  exit 0;
}
  


{
  my $X = X11::Protocol->new;
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($X->root,
                       X11::AtomConstants::WM_ICON_SIZE(),
                       0,   # AnyPropertyType
                       0,   # offset
                       999, # length
                       0);  # delete;

  ### $value
  exit 0;
}
