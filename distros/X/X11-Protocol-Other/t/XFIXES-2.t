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

BEGIN { require 5 }
use strict;
use X11::Protocol;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
END { MyTestHelpers::diag ("END"); }

# uncomment this to run the ### lines
#use Smart::Comments;

my $test_count = (tests => 108)[1];
plan tests => $test_count;

require X11::Protocol;
MyTestHelpers::diag ("X11::Protocol version ", X11::Protocol->VERSION);

my $display = $ENV{'DISPLAY'};
if (! defined $display) {
  foreach (1 .. $test_count) {
    skip ('No DISPLAY set', 1, 1);
  }
  exit 0;
}

# pass display arg so as not to get a "guess" warning
my $X;
if (! eval { $X = X11::Protocol->new ($display); }) {
  MyTestHelpers::diag ('Cannot connect to X server -- ',$@);
  foreach (1 .. $test_count) {
    skip ('Cannot connect to X server', 1, 1);
  }
  exit 0;
}
$X->QueryPointer($X->{'root'});  # sync

{
  my ($major_opcode, $first_event, $first_error)
    = $X->QueryExtension('XFIXES');
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no XFIXES on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("XFIXES extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('XFIXES')) {
  die "QueryExtension says XFIXES avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync

{
  my $client_major = 2;
  my $client_minor = 0;
  my ($server_major, $server_minor) = $X->XFixesQueryVersion ($client_major, $client_minor);
  MyTestHelpers::diag ("XFixesQueryVersion ask for $client_major.$client_minor got server version $server_major.$server_minor");
  if ($server_major < $client_major) {
    foreach (1 .. $test_count) {
      skip ("QueryVersion() no XFIXES $client_major.$client_minor on the server", 1, 1);
    }
    exit 0;
  }
}


#------------------------------------------------------------------------------
# XFixesCreateRegion()

{
  my $region = $X->new_rsrc;

  $X->XFixesCreateRegion ($region);
  $X->QueryPointer($X->root); # sync
  $X->XFixesDestroyRegion ($region);
  $X->QueryPointer($X->root); # sync

  $X->XFixesCreateRegion ($region, [0,0,10,5], [100,100,1,1]);
  $X->QueryPointer($X->root); # sync
  $X->XFixesDestroyRegion ($region);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# XFixesCreateRegionFromBitmap()

{
  my $bitmap = $X->new_rsrc;
  $X->CreatePixmap ($bitmap,
                    $X->root,
                    1,
                    10,10);  # width,height

  my $region = $X->new_rsrc;
  $X->XFixesCreateRegionFromBitmap ($region, $bitmap);
  $X->QueryPointer($X->root); # sync

  $X->FreePixmap ($bitmap);
  $X->QueryPointer($X->root); # sync
  $X->XFixesDestroyRegion ($region);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# XFixesCreateRegionFromWindow()

{
  my $region = $X->new_rsrc;

  $X->XFixesCreateRegionFromWindow ($region, $X->root, 'Bounding');
  $X->QueryPointer($X->root); # sync

  my ($bounding, @rects) = $X->XFixesFetchRegion ($region);
  ### @rects
  ok ($bounding->[0], 0, 'x');
  ok ($bounding->[1], 0, 'y');
  ok ($bounding->[2], $X->width_in_pixels, 'width');
  ok ($bounding->[3], $X->height_in_pixels, 'height');

  ok (scalar(@rects), 1);
  ok ($rects[0]->[0], 0, 'x');
  ok ($rects[0]->[1], 0, 'y');
  ok ($rects[0]->[2], $X->width_in_pixels, 'width');
  ok ($rects[0]->[3], $X->height_in_pixels, 'height');

  $X->XFixesDestroyRegion ($region);
  $X->QueryPointer($X->root); # sync

  $X->XFixesCreateRegionFromWindow ($region, $X->root, 'Clip');
  $X->QueryPointer($X->root); # sync
  $X->XFixesDestroyRegion ($region);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# XFixesCreateRegionFromGC()

my $gc = $X->new_rsrc;
$X->CreateGC ($gc, $X->root);

{
  $X->SetClipRectangles ($gc, 6,7, 'UnSorted', [1,2,30,40]);
  $X->QueryPointer($X->root); # sync

  my $region = $X->new_rsrc;
  $X->XFixesCreateRegionFromGC ($region, $gc);
  $X->QueryPointer($X->root); # sync

  my ($bounding, @rects) = $X->XFixesFetchRegion ($region);
  ### @rects
  ok ($bounding->[0], 1, 'x');
  ok ($bounding->[1], 2, 'y');
  ok ($bounding->[2], 30, 'width');
  ok ($bounding->[3], 40, 'height');

  ok (scalar(@rects), 1);
  ok ($rects[0]->[0], 1, 'x');
  ok ($rects[0]->[1], 2, 'y');
  ok ($rects[0]->[2], 30, 'width');
  ok ($rects[0]->[3], 40, 'height');

  $X->XFixesDestroyRegion ($region);
  $X->QueryPointer($X->root); # sync
}


#------------------------------------------------------------------------------
# XFixesCreateRegionFromPicture() - in XFIXES-2-render.t


#------------------------------------------------------------------------------

my $region = $X->new_rsrc;
$X->XFixesCreateRegion ($region);

my $r2 = $X->new_rsrc;
$X->XFixesCreateRegion ($r2);

my $r3 = $X->new_rsrc;
$X->XFixesCreateRegion ($r3);

#------------------------------------------------------------------------------
# XFixesSetRegion()

{
  $X->QueryPointer($X->root); # sync

  $X->XFixesSetRegion ($region, [1,2, 12,13], [21,20,9,12]);
  $X->QueryPointer($X->root); # sync

  my ($bounding, @rects) = $X->XFixesFetchRegion ($region);
  ### @rects
  ok ($bounding->[0], 1, 'x');
  ok ($bounding->[1], 2, 'y');
  ok ($bounding->[2], 29, 'width');
  ok ($bounding->[3], 30, 'height');

  ok (scalar(@rects), 2);
  ok ($rects[0]->[0], 1, 'x');
  ok ($rects[0]->[1], 2, 'y');
  ok ($rects[0]->[2], 12, 'width');
  ok ($rects[0]->[3], 13, 'height');

  ok ($rects[1]->[0], 21, 'x');
  ok ($rects[1]->[1], 20, 'y');
  ok ($rects[1]->[2], 9, 'width');
  ok ($rects[1]->[3], 12, 'height');
}

#------------------------------------------------------------------------------
# XFixesCopyRegion()

{
  my $region = $X->new_rsrc;
  $X->XFixesCreateRegion ($region, [1,2,3,4]);
  $X->QueryPointer($X->root); # sync

  my $r2 = $X->new_rsrc;
  $X->XFixesCreateRegion ($r2);

  $X->XFixesCopyRegion ($region, $r2);
  $X->QueryPointer($X->root); # sync

  my ($bounding, @rects) = $X->XFixesFetchRegion ($r2);
  ### @rects
  ok ($bounding->[0], 1, 'x');
  ok ($bounding->[1], 2, 'y');
  ok ($bounding->[2], 3, 'width');
  ok ($bounding->[3], 4, 'height');

  ok (scalar(@rects), 1);
  ok ($rects[0]->[0], 1, 'x');
  ok ($rects[0]->[1], 2, 'y');
  ok ($rects[0]->[2], 3, 'width');
  ok ($rects[0]->[3], 4, 'height');
}


#------------------------------------------------------------------------------
# XFixesUnionRegion()

{
  $X->XFixesSetRegion ($r2, [0,0,1,1]);
  $X->XFixesSetRegion ($r3, [1,0,1,1]);

  $X->XFixesUnionRegion ($r2, $r3, $region);
  $X->QueryPointer($X->root); # sync

  my ($bounding, @rects) = $X->XFixesFetchRegion ($region);
  ### @rects
  ok ($bounding->[0], 0, 'x');
  ok ($bounding->[1], 0, 'y');
  ok ($bounding->[2], 2, 'width');
  ok ($bounding->[3], 1, 'height');

  ok (scalar(@rects), 1);
  ok ($rects[0]->[0], 0, 'x');
  ok ($rects[0]->[1], 0, 'y');
  ok ($rects[0]->[2], 2, 'width');
  ok ($rects[0]->[3], 1, 'height');
}


#------------------------------------------------------------------------------
# XFixesIntersectRegion()

{
  $X->XFixesSetRegion ($r2, [1,2,3,4]);
  $X->XFixesSetRegion ($r3, [2,3,4,5]);

  $X->XFixesIntersectRegion ($r2, $r3, $region);
  $X->QueryPointer($X->root); # sync

  my ($bounding, @rects) = $X->XFixesFetchRegion ($region);
  ### @rects
  ok ($bounding->[0], 2, 'x');
  ok ($bounding->[1], 3, 'y');
  ok ($bounding->[2], 2, 'width');
  ok ($bounding->[3], 3, 'height');

  ok (scalar(@rects), 1);
  ok ($rects[0]->[0], 2, 'x');
  ok ($rects[0]->[1], 3, 'y');
  ok ($rects[0]->[2], 2, 'width');
  ok ($rects[0]->[3], 3, 'height');
}

#------------------------------------------------------------------------------
# XFixesSubtractRegion()

{
  $X->XFixesSetRegion ($r2, [0,0,10,10]);
  $X->XFixesSetRegion ($r3, [5,0,10,10]);

  $X->XFixesSubtractRegion ($r2, $r3, $region);
  $X->QueryPointer($X->root); # sync

  my ($bounding, @rects) = $X->XFixesFetchRegion ($region);
  ### @rects
  ok ($bounding->[0], 0, 'x');
  ok ($bounding->[1], 0, 'y');
  ok ($bounding->[2], 5, 'width');
  ok ($bounding->[3], 10, 'height');

  ok (scalar(@rects), 1);
  ok ($rects[0]->[0], 0, 'x');
  ok ($rects[0]->[1], 0, 'y');
  ok ($rects[0]->[2], 5, 'width');
  ok ($rects[0]->[3], 10, 'height');
}


#------------------------------------------------------------------------------
# XFixesInvertRegion()

{
  $X->XFixesSetRegion ($r2, [0,0,5,100]);
  $X->QueryPointer($X->root); # sync

  $X->XFixesInvertRegion ($r2, [0,0,10,10], $region);
  $X->QueryPointer($X->root); # sync

  my ($bounding, @rects) = $X->XFixesFetchRegion ($region);
  ### @rects
  ok ($bounding->[0], 5, 'x');
  ok ($bounding->[1], 0, 'y');
  ok ($bounding->[2], 5, 'width');
  ok ($bounding->[3], 10, 'height');

  ok (scalar(@rects), 1);
  ok ($rects[0]->[0], 5, 'x');
  ok ($rects[0]->[1], 0, 'y');
  ok ($rects[0]->[2], 5, 'width');
  ok ($rects[0]->[3], 10, 'height');
}


#------------------------------------------------------------------------------
# XFixesTranslateRegion()

{
  $X->XFixesSetRegion ($region, [1,2,3,4]);
  $X->QueryPointer($X->root); # sync

  $X->XFixesTranslateRegion ($region, 10,20);
  $X->QueryPointer($X->root); # sync

  my ($bounding, @rects) = $X->XFixesFetchRegion ($region);
  ### @rects
  ok ($bounding->[0], 11, 'x');
  ok ($bounding->[1], 22, 'y');
  ok ($bounding->[2], 3, 'width');
  ok ($bounding->[3], 4, 'height');

  ok (scalar(@rects), 1);
  ok ($rects[0]->[0], 11, 'x');
  ok ($rects[0]->[1], 22, 'y');
  ok ($rects[0]->[2], 3, 'width');
  ok ($rects[0]->[3], 4, 'height');
}


#------------------------------------------------------------------------------
# XFixesRegionExtents()

{
  $X->XFixesSetRegion ($r2, [1,2,1,1], [3,5,1,1]);
  $X->QueryPointer($X->root); # sync

  $X->XFixesRegionExtents ($r2, $region);
  $X->QueryPointer($X->root); # sync

  my ($bounding, @rects) = $X->XFixesFetchRegion ($region);
  ### @rects
  ok ($bounding->[0], 1, 'x');
  ok ($bounding->[1], 2, 'y');
  ok ($bounding->[2], 3, 'width');
  ok ($bounding->[3], 4, 'height');

  ok (scalar(@rects), 1);
  ok ($rects[0]->[0], 1, 'x');
  ok ($rects[0]->[1], 2, 'y');
  ok ($rects[0]->[2], 3, 'width');
  ok ($rects[0]->[3], 4, 'height');
}

#------------------------------------------------------------------------------
# XFixesSetGCClipRegion()

{
  $X->XFixesSetGCClipRegion ($gc, 3,4, $region);
  $X->QueryPointer($X->root); # sync

  my $rr = $X->new_rsrc;
  $X->XFixesCreateRegionFromGC ($rr, $gc);
  my ($bounding, @rects) = $X->XFixesFetchRegion ($region);
  ok ($bounding->[0], 1, 'x');
  ok ($bounding->[1], 2, 'y');
  ok ($bounding->[2], 3, 'width');
  ok ($bounding->[3], 4, 'height');
  $X->XFixesDestroyRegion ($rr);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# XFixesSetWindowShapeRegion() - in XFIXES-2-shape.t


#------------------------------------------------------------------------------
# XFixesSetPictureClipRegion() - in XFIXES-2-render.t


#------------------------------------------------------------------------------
# XFixesSetCursorName()

my $bitmap1 = $X->new_rsrc;
$X->CreatePixmap ($bitmap1,
                  $X->root,
                  1,
                  28,32);
my $bitmap2 = $X->new_rsrc;
$X->CreatePixmap ($bitmap2,
                  $X->root,
                  1,
                  28,32);
my $cursor = $X->new_rsrc;
$X->CreateCursor ($cursor, $bitmap1, $bitmap2,
                  0,0,0xFFFF,
                  0xFFFF,0,0,
                  0,0);

# ### XFixesSetCursorName: $X->{'ext_request_num'}->{'XFixesSetCursorName'}
# ### XFixesSetCursorName: $X->{'ext_request'}->{147}->[23]

$X->XFixesSetCursorName ($cursor, 'my test cursor');
$X->QueryPointer($X->root); # sync

#------------------------------------------------------------------------------
# XFixesGetCursorName()

{
  ### XFixesGetCursorName
  my @ret = $X->XFixesGetCursorName ($cursor);
  ### @ret
  $X->QueryPointer($X->root); # sync

  ok (scalar(@ret), 2);
  my ($atom, $str) = @ret;
  ok ($X->GetAtomName($atom), 'my test cursor',
      'XFixesGetCursorName atom name');
  ok ($str, 'my test cursor',
      'XFixesGetCursorName string');
}

#------------------------------------------------------------------------------
# XFixesGetCursorImageAndName()

{
  # Set a cursor before attempting to read back the image.  With xvfb of
  # x.org 1.11.4 at startup an attempt to XFixesGetCursorImage() or
  # XFixesGetCursorImageAndName() before a cursor has been set results in a
  # BadCursor error.

  my $cursor_font = $X->new_rsrc;
  $X->OpenFont ($cursor_font, "cursor");
  my $cursor = $X->new_rsrc;
  $X->CreateGlyphCursor ($cursor,
                         $cursor_font,  # cursor font
                         $cursor_font,  # mask font
                         0,  # X_cursor glyph
                         1,  # X_cursor mask
                         0,0,0,
                         0xFFFF, 0xFFFF, 0xFFFF);
  $X->CloseFont ($cursor_font);
  $X->QueryPointer($X->root); # sync

  my $screen_info;
  foreach $screen_info (@{$X->{'screens'}}) {
    $X->ChangeWindowAttributes ($screen_info->{'root'},
                                cursor => $cursor);
  }
  $X->FreeCursor ($cursor);
  $X->QueryPointer($X->root); # sync
}

{
  my ($root_x,$root_y, $width,$height, $xhot,$yhot, $serial, $pixels,
      $atom, $str)
    = $X->XFixesGetCursorImageAndName ();
  $X->QueryPointer($X->root); # sync

  ok (length($pixels), 4*$width*$height);

  ok ($atom eq 'None' || $atom =~ /^\d+$/, 1,
      'XFixesGetCursorImageAndName atom numeric or None');
  ok (defined $str, 1,
      'XFixesGetCursorImageAndName string');
}

#------------------------------------------------------------------------------
# XFixesChangeCursor()

{
  my $b1 = $X->new_rsrc;
  $X->CreatePixmap ($b1,
                    $X->root,
                    1,
                    1,1);
  my $b2 = $X->new_rsrc;
  $X->CreatePixmap ($b2,
                    $X->root,
                    1,
                    1,1);
  my $c2 = $X->new_rsrc;
  $X->CreateCursor ($c2, $bitmap1, $bitmap2,
                    0,0,0xFFFF,
                    0xFFFF,0,0,
                    0,0);
  {
    ### XFixesGetCursorName
    my ($atom, $str) = $X->XFixesGetCursorName ($c2);
    ok ($str, '');
  }
  ### XFixesChangeCursor
  $X->XFixesChangeCursor ($cursor, $c2);
  $X->QueryPointer($X->root); # sync
  {
    ### XFixesGetCursorName
    my ($atom, $str) = $X->XFixesGetCursorName ($c2);
    ok ($str, 'my test cursor');
  }
}

#------------------------------------------------------------------------------
# XFixesChangeCursorByName()

{
  my $b1 = $X->new_rsrc;
  $X->CreatePixmap ($b1,
                    $X->root,
                    1,
                    1,1);
  my $b2 = $X->new_rsrc;
  $X->CreatePixmap ($b2,
                    $X->root,
                    1,
                    1,1);
  my $c3 = $X->new_rsrc;
  $X->CreateCursor ($c3, $bitmap1, $bitmap2,
                    0,0,0xFFFF,
                    0xFFFF,0,0,
                    0,0);

  {
    my ($atom, $str) = $X->XFixesGetCursorName ($cursor);
    ok ($str, 'my test cursor');
  }

  ### XFixesChangeCursorByName
  $X->XFixesChangeCursorByName ($c3, 'my test cursor');
  $X->QueryPointer($X->root); # sync

  # name copied from $c3 to $cursor, so it loses its "my test cursor"
  {
    my ($atom, $str) = $X->XFixesGetCursorName ($cursor);
    ok ($str, '');
  }
  # how to check it had any effect ?
}

exit 0;
