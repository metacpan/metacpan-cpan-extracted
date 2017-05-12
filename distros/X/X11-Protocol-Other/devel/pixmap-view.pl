#!/usr/bin/perl -w

# Copyright 2016, 2017 Kevin Ryde

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


# Usage: ./pixmap-view.pl XID
#
# XID is an id (an integer) of a pixmap.  Display that pixmap in a window.
# XID is interpreted using oct() so can be decimal digits or hex 0x123 etc.
#
# The pixmap is just made the background of a new window.  There's no
# attempt to find its size, and it's assumed to be for the default root
# visual.  There's nothing to specify what visual it is meant to be for.


use strict;
use FindBin;
use X11::Protocol;
use X11::Protocol::WM;

use lib 'devel', '.';

# uncomment this to run the ### lines
#use Smart::Comments;

my $pixmap = shift @ARGV;
$pixmap = oct($pixmap);
printf "pixmap %d 0x%x\n", $pixmap, $pixmap;

my $X = X11::Protocol->new;

my $window = $X->new_rsrc;
$X->CreateWindow ($window,
                  $X->root,         # parent
                  'InputOutput',    # class
                  $X->root_depth,   # depth
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  64,64,            # w,h initial size
                  0,                # border
                  background_pixmap => $pixmap,
                 );
X11::Protocol::WM::set_wm_name ($X, $window, $FindBin::Script);
X11::Protocol::WM::set_wm_hints ($X, $window, input => 1);
$X->MapWindow ($window);
$X->ClearArea ($window, 0,0,0,0);

for (;;) {
  $X->handle_input;
}
exit 0;
