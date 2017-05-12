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

my $root_pictformat;
{
  my ($formatinfos, $screeninfos, $subpixels) = $X->RenderQueryPictFormats;
  # ### $formatinfos
  foreach my $info (@$formatinfos) {
    my ($pictformat, $type, $depth, $direct, $colormap) = @$info;
    if ($type eq 'Direct'
        && $depth == $X->{'root_depth'}
       ) {
      $root_pictformat = $pictformat;
      ### $info
      last;
    }
  }
  if (! defined $root_pictformat) {
    die "Oops, cannot find pictformat for root depth ",$X->root_depth;
  }
}

my $alpha_pictformat;
my $alpha_depth = 8;
{
  my ($formatinfos, $screeninfos, $subpixels) = $X->RenderQueryPictFormats;
  # ### $formatinfos
  ### $screeninfos
  ### $subpixels
  foreach my $info (@$formatinfos) {
    my ($pictformat, $type, $depth,
        $red_pos, $red_mask,
        $green_pos, $green_mask,
        $blue_pos, $blue_mask,
        $alpha_pos, $alpha_mask,
        $colormap) = @$info;
    ### $alpha_pos
    ### $alpha_mask
    if ($type eq 'Direct' && $depth == $alpha_depth && $alpha_mask == 255) {
      $alpha_pictformat = $pictformat;
      ### $info
      last;
    }
  }
  if (! defined $alpha_pictformat) {
    die "Oops, cannot find pictformat for alpha depth ",$alpha_depth;
  }
}

{
  my @info = $X->RenderQueryFilters ($X->root);
  ### @info
}

my $width = 32;
my $height = 32;


my $bitmap1 = $X->new_rsrc;
$X->CreatePixmap ($bitmap1,
                  $X->root,
                  1,
                  $width,$height);

my $gc_on = $X->new_rsrc;
$X->CreateGC ($gc_on, $bitmap1,
              foreground => 1,
              background => 0);

my $gc_off = $X->new_rsrc;
$X->CreateGC ($gc_off, $bitmap1,
              foreground => 0,
              background => 1);

$X->PolyFillRectangle ($bitmap1, $gc_off, [0,0, $width,$height]);
$X->PolyFillRectangle ($bitmap1, $gc_on, [0,0, $width/2,$height]);


my $alpha_pixmap = $X->new_rsrc;
$X->CreatePixmap ($alpha_pixmap,
                  $X->root,
                  $alpha_depth,
                  $width,$height);
$X->QueryPointer($X->root); # sync

my $alpha_gc = $X->new_rsrc;
$X->CreateGC ($alpha_gc, $alpha_pixmap,
              foreground => 1,
              background => 0);
$X->QueryPointer($X->root); # sync

my $half_width = int($width/2);
my $half_height = int($height/2);
foreach my $x (0 .. $width-1) {
  foreach my $y (0 .. $height-1) {
    my $x_alpha = ($x <= $half_width ? $x : $width-1-$x);
    $x_alpha = $x_alpha / $half_width;
    my $y_alpha = ($y <= $half_height ? $y : $height-1-$y);
    $y_alpha = $y_alpha / $half_height;
    my $pixel = $x_alpha * $y_alpha;
    $pixel *= 1.5;
    $pixel = min ($pixel, 1.0);
    $pixel = int ($pixel * 255);
    # $pixel *= 0x1010101;
    # $pixel *= 0x1000000;
    $X->ChangeGC ($alpha_gc, foreground => $pixel);
    $X->PolyPoint ($alpha_pixmap, $alpha_gc, 'Origin', $x,$y);
  }
}
$X->QueryPointer($X->root); # sync

my $alpha_picture = $X->new_rsrc;
$X->RenderCreatePicture ($alpha_picture,
                         $alpha_pixmap,
                         $alpha_pictformat,
                         dither => 'None',
                         clip_mask => $bitmap1,
                        );
$X->QueryPointer($X->root); # sync

my $cursor_pixmap = $X->new_rsrc;
$X->CreatePixmap ($cursor_pixmap,
                  $X->root,
                  $X->root_depth,
                  $width,$height);
$X->QueryPointer($X->root); # sync

my $cursor_gc = $X->new_rsrc;
$X->CreateGC ($cursor_gc, $cursor_pixmap);

$X->ChangeGC ($cursor_gc, foreground => 0xFF0000);
$X->PolyFillRectangle ($cursor_pixmap, $cursor_gc,
                       [0,0, $width,$height/2]);
$X->ChangeGC ($cursor_gc, foreground => 0x00FF00);
$X->PolyFillRectangle ($cursor_pixmap, $cursor_gc,
                       [0,$height/2, $width,$height/2]);
$X->QueryPointer($X->root); # sync


my $cursor_picture = $X->new_rsrc;
$X->RenderCreatePicture ($cursor_picture,
                         $cursor_pixmap,
                         $root_pictformat,
                         dither => 'None',
                         clip_mask => $bitmap1,
                         alpha_map => $alpha_picture,
                        );
# $X->RenderSetPictureFilter ($cursor_picture, "best");
# $X->RenderSetPictureFilter ($cursor_picture, "fast");
$X->QueryPointer($X->root); # sync

my $cursor = $X->new_rsrc;
$X->RenderCreateCursor ($cursor, $cursor_picture, $width,$height);

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

$X->XFixesSelectCursorInput ($X->root, 1);

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
