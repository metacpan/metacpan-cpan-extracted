#!/usr/bin/perl

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


# Usage: perl cursor-font-anim.pl
#
# This is a bit of nonsense using the RENDER extension to make an annoying
# animated cursor for the root window, cycling through each of the standard
# cursor font shapes.
#
# The size of the X11::CursorFont module @CURSOR_NAME array is used for how
# many cursors are available in the cursor font.
#
# When you get sick of this put it back to something sensible with for
# instance
#
#     xsetroot -cursor_name left_ptr
#


use strict;
use X11::Protocol;
use X11::CursorFont '@CURSOR_NAME';

my $X = X11::Protocol->new;
if (! $X->init_extension('RENDER')) {
  print "RENDER extension not available on the server\n";
  exit 1;
}

my $cursor_font = $X->new_rsrc;
$X->OpenFont ($cursor_font, "cursor");

my @cursors;
for (my $i = 0; $i < @CURSOR_NAME; $i+=2) {
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
print "total ",scalar(@cursors)," cursors animated";

my $milliseconds = 500;

my $cursor = $X->new_rsrc;
$X->RenderCreateAnimCursor ($cursor, map { [$_,$milliseconds] } @cursors);

$X->ChangeWindowAttributes ($X->root, cursor => $cursor);
exit 0;
