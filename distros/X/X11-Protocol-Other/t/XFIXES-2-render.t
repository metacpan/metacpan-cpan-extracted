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

my $test_count = (tests => 13)[1];
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
  # suppress warnings from X11::Protocol 0.56 when
  # X11::Protocol::Ext::RENDER 0.01 passes undef entries in array to
  # make_num_hash()
  local $^W = 0;

  if (! $X->init_extension ('RENDER')) {
    MyTestHelpers::diag ('Server RENDER extension not available');
    foreach (1 .. $test_count) {
      skip ('Server RENDER extension not available', 1, 1);
    }
    exit 0;
  }
}

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
# XFixesCreateRegionFromPicture()

my $region = $X->new_rsrc;

my $root_pictformat;
{
  my ($formatinfos, $screeninfos, $subpixels) = $X->RenderQueryPictFormats;
  ### $formatinfos
  my $info;
  foreach $info (@$formatinfos) {
    my ($pictformat, $type, $depth, @rgba) = @$info;
    if ($depth == $X->root_depth) {
      $root_pictformat = $pictformat;
    }
  }
  if (! defined $root_pictformat) {
    die "Oops, cannot find pictformat for root depth ",$X->root_depth;
  }
}
# at least one attribute arg to RenderCreatePicture() or
# X11::Protocol::Ext::RENDER 0.01 gives warnings for uninitialized $mask
my $picture = $X->new_rsrc;
$X->RenderCreatePicture ($picture, $X->root, $root_pictformat,
                         dither => 'None');
$X->QueryPointer($X->root); # sync

{
  $X->RenderSetPictureClipRectangles ($picture, 6,7, [1,2,30,40]);
  $X->QueryPointer($X->root); # sync

  $X->XFixesCreateRegionFromPicture ($region, $picture);
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
}

#------------------------------------------------------------------------------
# XFixesSetPictureClipRegion()

{
  $X->XFixesSetPictureClipRegion ($picture, 3,4, $region);
  $X->QueryPointer($X->root); # sync

  my $r2 = $X->new_rsrc;
  $X->XFixesCreateRegionFromPicture ($r2, $picture);
  my ($bounding, @rects) = $X->XFixesFetchRegion ($region);
  ok ($bounding->[0], 1, 'x');
  ok ($bounding->[1], 2, 'y');
  ok ($bounding->[2], 30, 'width');
  ok ($bounding->[3], 40, 'height');
  $X->XFixesDestroyRegion ($r2);
  $X->QueryPointer($X->root); # sync
}

exit 0;
