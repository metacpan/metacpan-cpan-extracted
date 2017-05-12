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

use strict;
use X11::Protocol;

use lib 'devel', '.';

# uncomment this to run the ### lines
use Smart::Comments;



{
  $ENV{'DISPLAY'} = ':1';
  my $X = X11::Protocol->new ($ENV{'DISPLAY'} || ':0');
  $X->init_extension('XFIXES') or die;

  my $cursor_font = $X->new_rsrc;
  $X->OpenFont ($cursor_font, "cursor");
  my $cursor = $X->new_rsrc;
  $X->CreateGlyphCursor ($cursor,
                         $cursor_font,
                         'None',  # mask font
                         3,
                         0,
                         0xFFFF, 0xFFFF, 0xFFFF,
                         0,0,0);
  $X->CloseFont ($cursor_font);
  $X->QueryPointer($X->root); # sync

  $X->ChangeWindowAttributes ($X->root,
                              cursor => $cursor);
  $X->QueryPointer($X->root); # sync

  my ($rootx,$rooty, $width,$height, $xhot,$yhot, $serial, $pixels)
    = $X->XFixesGetCursorImage ();

  # {
  #   my @bytes = unpack 'C*', $pixels;
  #   foreach my $y (0 .. $height-1) {
  #     my @row = splice @bytes, 0,$width*4;
  #     print map {sprintf '%02X ',$_} @row;
  #     print "\n";
  #   }
  # }
  {
    my @words = unpack 'L*', $pixels;
    foreach my $y (0 .. $height-1) {
      my @row = splice @words, 0,$width;
      delete @row[5 .. $#row];
      print map {sprintf '%08X ',$_} @row;
      print "\n";
    }
  }
  exit 0;
}

{
  my $display = $ENV{'DISPLAY'} || ':0';
  my $X = X11::Protocol->new ($display);
  $X->{'event_handler'} = sub {
    my (%h) = @_;
    ### event_handler: \%h
  };

  { my @query = $X->QueryExtension('XFIXES');
    ### @query
  }
  $X->QueryPointer($X->{'root'}); # sync

  $X->init_extension('XFIXES') or die;
  $X->QueryPointer($X->{'root'}); # sync

  { my @version = $X->XFixesQueryVersion (99,0);
    ### @version
  }
  $X->QueryPointer($X->{'root'}); # sync

  my $cursor_font = $X->new_rsrc;
  $X->OpenFont ($cursor_font, "cursor");

  my $cursor = $X->new_rsrc;
  $X->CreateGlyphCursor ($cursor,
                         $cursor_font,
                         'None',  # mask font
                         3,
                         0,
                         0xFFFF, 0xFFFF, 0xFFFF,
                         0,0,0);
  $X->QueryPointer($X->{'root'}); # sync

  # { my @reqdata = $X->get_request('XFixesGetCursorName');
  #   ### @reqdata
  # }
  { my @cursorname = $X->XFixesGetCursorName ($cursor);
    ### XFixesGetCursorName: @cursorname
  }
  $X->QueryPointer($X->{'root'}); # sync

  my $region = $X->new_rsrc;
  $X->XFixesCreateRegion ($region);
  $X->QueryPointer($X->{'root'}); # sync

  my $region_dst = $X->new_rsrc;
  $X->XFixesCreateRegion ($region_dst);
  $X->XFixesExpandRegion ($region, $region_dst, 1,1,1,1);
  $X->QueryPointer($X->{'root'}); # sync

  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $X->root,         # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    0,0,              # x,y
                    100,100,          # width,height
                    0,                # border
                    background_pixel => $X->black_pixel,
                   );
  $X->MapWindow ($window);
  sleep 1;
  $X->QueryPointer($X->{'root'}); # sync

  $region = $X->new_rsrc;
  # $X->XFixesCreateRegionFromWindow ($region, $window, 'Bounding');
  $X->XFixesCreateRegion ($region);
  $X->QueryPointer($X->root); # sync
  { my @rects = $X->XFixesFetchRegion ($region);
    ### @rects
  }


  $X->XFixesSelectCursorInput ($X->root, 1);
  $X->QueryPointer($X->{'root'}); # sync
  $X->handle_input;

  exit 0;
}



{
  my $X = X11::Protocol->new (':0');
  $X->init_extension('XFIXES') or die;

  $X->XFixesHideCursor ($X->root);
  $X->QueryPointer($X->{'root'}); # sync

  sleep 1;

  $X->XFixesShowCursor ($X->root);
  $X->QueryPointer($X->{'root'}); # sync
  $X->XFixesShowCursor ($X->root);
  $X->QueryPointer($X->{'root'}); # sync

  sleep 1;
 
  exit 0;
}

{
  my $X = X11::Protocol->new (':0');
  $X->init_extension('XFIXES') or die;

  my $region = $X->new_rsrc;
  $X->XFixesCreateRegion ($region, [1,2,1,1], [4,6,1,1]);
  { my @rects = $X->XFixesFetchRegion ($region);
    ### @rects
  }

  my $r2 = $X->new_rsrc;
  $X->XFixesCreateRegion ($r2);
  $X->XFixesRegionExtents ($region, $r2);
  { my @rects = $X->XFixesFetchRegion ($r2);
    ### @rects
  }
 
  exit 0;
}



{
  my $X = X11::Protocol->new (':0');
  $X->init_extension('XFIXES') or die;
  { my @version = $X->XFixesQueryVersion (1,0);
    ### @version
  }
  $X->QueryPointer($X->{'root'}); # sync


  exit 0;
}

sub atom_name_maybe {
  my ($X, $atom) = @_;
  my $ret = $X->robust_req ('GetAtomName', $atom);
  if (ref $ret) {
    return @$ret;
  }
  return '[not-atom]';
}
