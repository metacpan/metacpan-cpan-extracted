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

use lib 'devel', '.';

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $X = X11::Protocol->new (':0');
  $X->init_extension('Composite') or die;

  my @version = $X->CompositeQueryVersion (0,0);
  ### @version
  $X->QueryPointer($X->{'root'}); # sync
  exit 0;
}

{
  my $X = X11::Protocol->new (':0');
  $X->init_extension('Composite') or die $@;
  $X->QueryPointer($X->{'root'}); # sync

  my $X2 = X11::Protocol->new (':0');
  $X2->init_extension('Composite') or die $@;
  $X2->QueryPointer($X->{'root'}); # sync

  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $X->root,         # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    0,0,              # x,y
                    100,100,          # width,height
                    0,                # border
                   );

  # my $window2 = $X->new_rsrc;
  # $X->CreateWindow ($window2,
  #                   $X->root,         # parent
  #                   'InputOutput',
  #                   0,                # depth, from parent
  #                   'CopyFromParent', # visual
  #                   0,0,              # x,y
  #                   100,100,          # width,height
  #                   0,                # border
  #                  );
  # $X->MapWindow ($window2);
  # $X->QueryPointer($X->{'root'}); # sync

  # $X->CompositeRedirectWindow ($window, 'Automatic');
  # $X->QueryPointer($X->{'root'}); # sync
  #
  # $X->CompositeRedirectWindow ($window, 'Automatic');
  # $X->QueryPointer($X->{'root'}); # sync
  #
  # $X->CompositeUnredirectWindow ($window, 'Automatic');
  # $X->QueryPointer($X->{'root'}); # sync
  #
  # $X->CompositeUnredirectWindow ($window, 'Automatic');
  # $X->QueryPointer($X->{'root'}); # sync

  # $X->CompositeUnredirectWindow ($window, 'Automatic');
  # $X->QueryPointer($X->{'root'}); # sync

  # my $region = $X->new_rsrc;
  # $X->CompositeCreateRegionFromBorderClip ($region, $window);
  # $X->QueryPointer($X->{'root'}); # sync


  $X->MapWindow ($window);
  $X->QueryPointer($X->{'root'}); # sync
  sleep 1;

  $X->CompositeRedirectWindow ($window, 'Automatic');
  $X->QueryPointer($X->{'root'}); # sync

  # $X->CreatePixmap ($pixmap,
  #                   $X->root,
  #                   $X->root_depth,
  #                   100,100);  # width,height

  {
    my $pixmap = $X->new_rsrc;
    $X->CompositeNameWindowPixmap ($window, $pixmap);
    $X->QueryPointer($X->{'root'}); # sync
  }
  {
    my $pixmap = $X2->new_rsrc;
    $X2->CompositeNameWindowPixmap ($window, $pixmap);
    $X2->QueryPointer($X->{'root'}); # sync
  }

  my $overlay_window = $X->CompositeGetOverlayWindow ($window);
  $X->QueryPointer($X->{'root'}); # sync
  ### overlay_window: sprintf '%X', $overlay_window

  {
    my $overlay_window = $X2->CompositeGetOverlayWindow ($window);
    $X2->QueryPointer($X2->{'root'}); # sync
    ### overlay_window: sprintf '%X', $overlay_window
  }

  $X->CompositeReleaseOverlayWindow ($overlay_window);
  $X->QueryPointer($X->{'root'}); # sync


  exit 0;
}
