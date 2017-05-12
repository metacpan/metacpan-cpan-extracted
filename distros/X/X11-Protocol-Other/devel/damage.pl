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
  $X->{'event_handler'} = sub {
    my (%h) = @_;
    ### event_handler: \%h
  };

  $X->init_extension('XFIXES') or die $@;
  $X->init_extension('DAMAGE') or die $@;
  $X->QueryPointer($X->{'root'}); # sync

  # { my @version = $X->DamageQueryVersion (99,99);
  #   ### @version
  # }
  # $X->QueryPointer($X->{'root'}); # sync

  my $damage = $X->new_rsrc;
  $X->DamageCreate ($damage, $X->root, 'NonEmpty');
  $X->QueryPointer($X->{'root'}); # sync

  # my $region = $X->new_rsrc;
  # $X->XFixesCreateRegion ($region);
  # $X->QueryPointer($X->{'root'}); # sync

  $X->DamageSubtract ($damage+1, 'None', 'None');
  $X->QueryPointer($X->{'root'}); # sync

  exit 0;
}


{
  my $X = X11::Protocol->new (':0');
  $X->init_extension('DAMAGE') or die;

  my $pixmap = $X->new_rsrc;
  $X->CreatePixmap ($pixmap,
                    $X->root,
                    $X->{'root_depth'},
                    2,2);  # width,height

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

  my $gc = $X->new_rsrc;
  $X->CreateGC ($gc, $pixmap, foreground => $X->{'white_pixel'});

  my $damage = $X->new_rsrc;
  $X->DamageCreate ($damage, $window, 'NonEmpty');
  # $X->DamageCreate ($damage, $pixmap, );'RawRectangles'

  my $count = 0;
  $X->{'event_handler'} = sub {
    my (%h) = @_;
    ### event_handler: \%h
    if ($h{'name'} eq 'DamageNotify') {
      $X->DamageSubtract ($damage, 'None','None');
      ### $count
      $count++;
      if ($count == 2) {
        ### PolyPoint
        $X->PolyPoint ($window, $gc, 'Origin', 0,1);
      }
    }
  };

  for (;;) { $X->handle_input; }
  exit 0;
}
