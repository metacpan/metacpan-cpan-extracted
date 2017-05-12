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


# Usage: perl xresource-pairwise.pl
#
# This is an example using mapp() from List::Pairwise to step through the
# XResourceQueryClientResources() return list, in this case for the
# resources of the current client -- creating a few so something shows up
# (or ought to).
#

use strict;
use X11::Protocol;
use List::Pairwise 'mapp';

my $X = X11::Protocol->new;
if (! $X->init_extension('X-Resource')) {
  print "X-Resource extension not available on the server\n";
  exit 0;
}

my $window = $X->new_rsrc;
$X->CreateWindow ($window,
                  $X->root,         # parent
                  'InputOutput',
                  0,                # depth, from parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  100,100,          # width,height
                  0);               # border

my $pixmap = $X->new_rsrc;
$X->CreatePixmap ($pixmap,
                  $X->root,
                  $X->root_depth,
                  100,100);  # width,height

$X->GrabKey ($X->max_keycode - 2,  # random keycode
             0,                    # modifiers
             $X->root,
             0, # owner events
             'Asynchronous', 'Asynchronous');


mapp {
  # $a is atom, $b is count
  print $X->atom_name($a), "  $b\n";
} $X->XResourceQueryClientResources($X->resource_id_base);

print "PixmapBytes  ",
  $X->XResourceQueryClientPixmapBytes($X->resource_id_base),"\n";

exit 0;
