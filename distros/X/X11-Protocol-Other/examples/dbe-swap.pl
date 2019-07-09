#!/usr/bin/perl -w

# Copyright 2011, 2017 Kevin Ryde

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


# Usage: perl dbe-swap.pl
#
# This is a simple example of double buffer swapping for drawing.  In the
# loop below drawing is done to the back buffer then swapped to the front to
# display.
#
# The drawing shows alternately a circle and square.  The new figure is
# drawn to the back buffer and then swapped to the front so it changes
# immediately, without a separate clear and draw which the user might see as
# a flash or flicker.  Of course a circle or square will draw fast enough
# that double buffering is hardly needed, but more complex contents can
# benefit.
#
# When a window gets an "expose", as happens here on the initial MapWindow,
# the back buffer is cleared to the window background the same as the window
# itself.  So if the buffer is allocated before the first expose then
# there's no need to explicitly erase the back buffer.
#
# In a realistic program of course you'd listen and read events from the
# server in between drawing, and might wait for at least one server
# round-trip between drawing so as not to hammer the server it it's under a
# heavy load.  Could wait a certain time or certain number of frames for a
# synchronizing reply, in case it's network latency rather than server load.
#

use strict;
use X11::Protocol;

my $X = X11::Protocol->new;
if (! $X->init_extension('DOUBLE-BUFFER')) {
  print "DOUBLE-BUFFER not available on the server\n";
  exit 1;
}

my $visual = $X->root_visual;
my ($info_aref) = $X->DbeGetVisualInfo ($X->root);
my %hash = @$info_aref;
if (! $hash{$visual}) {
  print "DOUBLE-BUFFER not available for root visual\n";
  exit 1;
}

my $window = $X->new_rsrc;
$X->CreateWindow ($window,
                  $X->root,         # parent
                  'InputOutput',    # class
                  0,                # depth, from parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  50,50,            # width,height
                  0,                # border
                  background_pixel => $X->black_pixel);

my $gc = $X->new_rsrc;
$X->CreateGC ($gc, $window, foreground => $X->white_pixel);

my $buffer = $X->new_rsrc;
$X->DbeAllocateBackBufferName ($window, $buffer, 'Background');

$X->MapWindow ($window);
sleep 1;

for (;;) {
  $X->PolyRectangle ($buffer, $gc, [ 10,10, 29,29 ]);
  $X->DbeSwapBuffers ($window, 'Background');
  $X->flush;
  sleep 1;

  $X->PolyArc ($buffer, $gc, [7,7, 35,35, 0, 360*64]);
  $X->DbeSwapBuffers ($window, 'Background');
  $X->flush;
  sleep 1;
}

exit 0;
