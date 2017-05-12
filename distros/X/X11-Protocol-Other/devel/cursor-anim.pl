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
use List::Util 'min';

use lib 'devel', '.';

# uncomment this to run the ### lines
use Smart::Comments;

my $X = X11::Protocol->new;
my $depth = $X->root_depth;

if (! $X->init_extension('XFIXES')) {
  print "XFIXES extension not available on the server\n";
  exit 1;
}
{
  local $^W = 0;
  if (! $X->init_extension('RENDER')) {
    print "RENDER extension not available on the server\n";
    exit 1;
  }
}

my $cursor_font = $X->new_rsrc;
$X->OpenFont ($cursor_font, "cursor");

my @cursors;
for (my $i = 0; $i <= 152; $i+=2) {
  my $cursor = $X->new_rsrc;
  $X->CreateGlyphCursor ($cursor,
                         $cursor_font,  # font
                         $cursor_font,  # mask font
                         $i,    # glyph number
                         $i+1,  # and its mask
                         0,0,0,                    # foreground, black
                         0xFFFF, 0xFFFF, 0xFFFF);  # background, white
  push @cursors, $cursor;
}

my $cursor = $X->new_rsrc;
$X->RenderCreateAnimCursor ($cursor, map { [$_,500] } @cursors);

$X->ChangeWindowAttributes ($X->root,
                            cursor => $cursor);

# my $window = $X->new_rsrc;
# $X->CreateWindow ($window,
#                   $X->root,         # parent
#                   'InputOutput',    # class
#                   $X->root_depth,   # depth
#                   'CopyFromParent', # visual
#                   0,0,              # x,y
#                   64,64,            # w,h initial size
#                   0,                # border
#                   background_pixel => $X->black_pixel,
#                   event_mask       => $X->pack_event_mask('Exposure'),
#                  );
# $X->ChangeProperty($window,
#                    X11::AtomConstants::WM_NAME,  # property
#                    X11::AtomConstants::STRING,   # type
#                    8,                            # byte format
#                    'Replace',
#                    'Current Cursor'); # window title
# $X->MapWindow($window);

# $X->XFixesSelectCursorInput ($X->root, 1);

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
