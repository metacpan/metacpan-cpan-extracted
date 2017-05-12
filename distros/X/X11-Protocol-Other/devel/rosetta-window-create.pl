#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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


#!/usr/bin/perl -w
use strict;
use X11::Protocol;

my $X = X11::Protocol->new;

my $window = $X->new_rsrc;
$X->CreateWindow ($window,
                  $X->root,         # parent window
                  'InputOutput',    # class
                  0,                # depth, copy from parent
                  0,                # visual, copy from parent
                  0,0,              # X,Y (window manager will override)
                  300,100,          # width,height
                  0,                # border width
                  background_pixel => $X->black_pixel,
                  event_mask       => $X->pack_event_mask('Exposure',
                                                          'ButtonPress'),
                 );

my $gc = $X->new_rsrc;
$X->CreateGC ($gc, $window,
              foreground => $X->white_pixel);

$X->{'event_handler'} = sub {
  my %event = @_;
  my $event_name = $event{'name'};

  if ($event_name eq 'Expose') {
    $X->PolyRectangle ($window, $gc, [ 10,10,     # x,y top-left corner
                                       30,20 ]);  # width,height
    $X->PolyText8 ($window, $gc,
                   10, 55,    # X,Y of text baseline
                   [ 0,  # delta for X
                     'Hello ... click mouse button to exit.' ]);

  } elsif ($event_name eq 'ButtonPress') {
    exit 0;
  }
};

$X->MapWindow ($window);
for (;;) {
  $X->handle_input;
}
