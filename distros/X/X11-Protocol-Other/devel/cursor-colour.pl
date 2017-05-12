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

use strict;
use X11::Protocol;
use X11::AtomConstants;

use lib 'devel', '.';

# uncomment this to run the ### lines
#use Smart::Comments;

my $X = X11::Protocol->new;
if (! $X->init_extension('XFIXES')) {
  print "XFIXES extension not available on the server\n";
  exit 1;
}


my $bitmap1 = $X->new_rsrc;
$X->CreatePixmap ($bitmap1,
                  $X->root,
                  1,
                  32,32);
my $bitmap2 = $X->new_rsrc;
$X->CreatePixmap ($bitmap2,
                  $X->root,
                  1,
                  32,32);

my $gc_on = $X->new_rsrc;
$X->CreateGC ($gc_on, $bitmap1,
              foreground => 1,
              background => 0);

my $gc_off = $X->new_rsrc;
$X->CreateGC ($gc_off, $bitmap1,
              foreground => 0,
              background => 1);

$X->PolyFillRectangle ($bitmap1, $gc_off, [0,0, 32,32]);
$X->PolyFillRectangle ($bitmap1, $gc_on, [3,3, 5,5]);

$X->PolyFillRectangle ($bitmap2, $gc_on, [0,0, 32,32]);
# $X->PolyFillRectangle ($bitmap2, $gc_off, [16,0, 2,32]);
$X->PolyFillRectangle ($bitmap2, $gc_off, [0,2, 32,2]);

my $cursor = $X->new_rsrc;
$X->CreateCursor ($cursor, $bitmap1, $bitmap2,
                  0,0xAAAA,0,
                  0,0x5555,0,
                  # 0,0,0xFFFF,
                  # 0xFFFF,0,0,
                  # 128, 0, 0,
                  # 0, 128, 0,
                  0,0);

$X->ChangeWindowAttributes ($X->root,
                            cursor => $cursor);

my $window = $X->new_rsrc;
$X->CreateWindow ($window,
                  $X->root,         # parent
                  'InputOutput',    # class
                  $X->root_depth,   # depth
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  64,64,            # w,h initial size
                  0,                # border
                  background_pixel => $X->black_pixel,
                  event_mask       => $X->pack_event_mask('Exposure'),
                 );
$X->ChangeProperty($window,
                   X11::AtomConstants::WM_NAME,  # property
                   X11::AtomConstants::STRING,   # type
                   8,                            # byte format
                   'Replace',
                   'Current Cursor'); # window title
$X->MapWindow($window);

for (;;) {
  $X->handle_input;
  {
    my ($rootx,$rooty, $width,$height, $xhot,$yhot, $serial, $pixels)
      = $X->XFixesGetCursorImage ();
    my @words = unpack 'L*', $pixels;
    foreach my $y (0 .. $height-1) {
      my @row = splice @words, 0,$width;
      delete @row[5 .. $#row];
      print map {sprintf '%08X ',$_} @row;
      print "\n";
    }
  }
}

exit 0;
