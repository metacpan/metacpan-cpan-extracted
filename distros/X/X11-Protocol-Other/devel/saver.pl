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
  # MitScreenSaverSetAttributes() initial window contents

  my $X = X11::Protocol->new (':0');
  $X->init_extension('MIT-SCREEN-SAVER') or die;

  $X->MitScreenSaverSelectInput ($X->root, 0x03);
  $X->QueryPointer($X->root); # sync

  $X->MitScreenSaverSetAttributes
    ($X->root,
     'InputOutput',    # class
     0,                # depth, from parent
     'CopyFromParent', # visual
     100,100,          # x,y
     1000,500,         # width,height
     0,                # border
     # background_pixmap => "None",
      background_pixel => $X->white_pixel,
    );
  $X->QueryPointer($X->root); # sync

  $X->{'event_handler'} = sub {
    my (%h) = @_;
    ### event_handler: \%h

    if ($h{'name'} eq 'MitScreenSaverNotify') {
      ### %h
    }
  };

  $X->ForceScreenSaver ('Activate');
  for (;;) {
    $X->handle_input;
  }

  exit 0;
}

{
  # MitScreenSaverSetAttributes()

  my $X = X11::Protocol->new (':0');
  $X->init_extension('MIT-SCREEN-SAVER') or die;

  $X->MitScreenSaverSelectInput ($X->root, 0x03);
  $X->QueryPointer($X->root); # sync

  $X->MitScreenSaverSetAttributes
    ($X->root,
     'InputOutput',    # class
     0,                # depth, from parent
     'CopyFromParent', # visual
     0,0,              # x,y
     1000,500,         # width,height
     0,                # border
     background_pixel => $X->white_pixel,
    );
  $X->QueryPointer($X->root); # sync

  $X->{'event_handler'} = sub {
    my (%h) = @_;
    ### event_handler: \%h

    if ($h{'name'} eq 'MitScreenSaverNotify') {
      my @info = $X->MitScreenSaverQueryInfo ($X->root);
      ### @info
    }
  };

  for (;;) {
    $X->handle_input;
  }

  exit 0;
}

{
  # conflicting MitScreenSaverSetAttributes()

  my $X1 = X11::Protocol->new (':0');
  my $X2 = X11::Protocol->new (':0');
  $X1->init_extension('MIT-SCREEN-SAVER') or die;
  $X2->init_extension('MIT-SCREEN-SAVER') or die;

  $X1->MitScreenSaverSetAttributes
    ($X1->root,
     'InputOutput',    # class
     0,                # depth, from parent
     'CopyFromParent', # visual
     0,0,              # x,y
     1000,500,         # width,height
     0,                # border
     background_pixel => $X1->white_pixel,
    );
  $X1->QueryPointer($X1->root); # sync

  $X2->MitScreenSaverSetAttributes
    ($X2->root,
     'InputOutput',    # class
     0,                # depth, from parent
     'CopyFromParent', # visual
     0,0,              # x,y
     1000,500,         # width,height
     0,                # border
     background_pixel => $X2->white_pixel,
    );
  $X2->QueryPointer($X2->root); # sync

  exit 0;
}


{
  my $X = X11::Protocol->new (':0');
  $X->init_extension('MIT-SCREEN-SAVER') or die;
  ### root: $X->root

  { my @version = $X->MitScreenSaverQueryVersion (99,99);
    ### @version
  }
  $X->QueryPointer($X->root); # sync

  { my @info = $X->MitScreenSaverQueryInfo ($X->root);
    ### @info
  }
  $X->QueryPointer($X->root); # sync

  $X->MitScreenSaverSelectInput ($X->root, 0x03);
  $X->QueryPointer($X->root); # sync


  $X->MitScreenSaverUnsetAttributes ($X->root);
  $X->QueryPointer($X->root); # sync

  $X->MitScreenSaverSetAttributes
    ($X->root,
     'InputOutput',    # class
     0,                # depth, from parent
     'CopyFromParent', # visual
     0,0,              # x,y
     1000,500,         # width,height
     0,                # border
     background_pixel => $X->white_pixel,
    );
  $X->QueryPointer($X->root); # sync

  { my @info = $X->MitScreenSaverQueryInfo ($X->root);
    ### @info
  }
  $X->QueryPointer($X->root); # sync

  exit 0;


  $X->{'event_handler'} = sub {
    my (%h) = @_;
    ### event_handler: \%h

    if ($h{'name'} eq 'MitScreenSaverNotify') {
      my @info = $X->MitScreenSaverQueryInfo ($X->root);
      ### @info
    }
  };

  $X->ForceScreenSaver ('Activate');
  $X->QueryPointer($X->root); # sync


  foreach (1 .. 20) {
    $X->handle_input;
  }

  exit 0;
}
