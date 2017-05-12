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
use Time::HiRes 'sleep';

use lib 'devel', '.';

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $X = X11::Protocol->new (':0');
  $X->{'event_handler'} = sub {
    my (%h) = @_;
    ### event_handler: \%h
  };

  $X->init_extension('MIT-SHM') or die;
  $X->QueryPointer($X->{'root'}); # sync

  { my @version = $X->MitShmQueryVersion;
    ### @version
  }
  $X->QueryPointer($X->{'root'}); # sync

  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $X->root,         # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    0,0,              # x,y
                    200,200,          # width,height
                    0,                # border
                    background_pixel => $X->white_pixel,
                   );
  $X->MapWindow ($window);
  $X->QueryPointer($X->{'root'}); # sync
  sleep .5;

  require IPC::SharedMem;
  require IPC::SysV;
  my $shmid = shmget (IPC::SysV::IPC_PRIVATE(),
                      5000,
                      IPC::SysV::IPC_CREAT() | 0666); # world read/write
  # $shmid = 122550155;
  ### $shmid


  my $addr = IPC::SysV::shmat ($shmid, undef, 0);
  ### $addr

  my $shmseg = $X->new_rsrc;
  $X->MitShmAttach ($shmseg,
                    $shmid,
                    0); # readonly or read/write
  $X->QueryPointer($X->{'root'}); # sync

  {
    ### MitShmGetImage
    my ($depth, $visual, $size) = my @ret =  $X->MitShmGetImage
      ($window,
       0,0, 10,10,
       0xFFFFFFFF,
       'ZPixmap',
       $shmseg,
       0);
    ### $depth
    ### $visual
    ### $size
    # ### vis: $X->{'visuals'}->{$visual}
    $X->QueryPointer($X->{'root'}); # sync
  }

  {
    my $gc = $X->new_rsrc;
    $X->CreateGC ($gc, $X->root, foreground => $X->{'white_pixel'});
    $X->QueryPointer($X->{'root'}); # sync

    shmwrite ($shmid, "\xAA" x 1000, 0, 1000);
    $X->MitShmPutImage ($window,
                        $gc,
                        $X->root_depth,  # depth
                        10,10,
                        0,0,
                        10,10,
                        0,0,
                        'ZPixmap',
                        1,               # send event
                        $shmseg, 0);
    ### PutImage sent
    $X->QueryPointer($X->{'root'}); # sync
  }
  sleep 1;
  {
    my $shpixmap = $X->new_rsrc;
    $X->MitShmCreatePixmap ($shpixmap,
                            $X->root,         # drawable
                            $X->root_depth,   # depth
                            5,5,
                            $shmseg, 0);
    $X->QueryPointer($X->{'root'}); # sync

    shmwrite ($shmid, "\0"x100, 0, 100) || die "$!";

    my $gc = $X->new_rsrc;
    $X->CreateGC ($gc, $X->root, foreground => $X->{'white_pixel'});
    $X->QueryPointer($X->{'root'}); # sync
    #
    $X->CopyArea ($shpixmap, $window, $gc,
                  0,0,
                  5,5,
                  100,100); # dst x,y
    $X->QueryPointer($X->{'root'}); # sync

    $X->init_extension('DAMAGE') or die $@;
    $X->QueryPointer($X->{'root'}); # sync

    my $damage = $X->new_rsrc;
    $X->DamageCreate ($damage, $shpixmap, 'RawRectangles');
    $X->QueryPointer($X->{'root'}); # sync

    shmwrite ($shmid, "0xAA"x100, 0, 100) || die "$!";
  }
  {
    my $buff;
    IPC::SysV::memread($addr, $buff, 0, 10) || die $!;
    ### $buff
  }
  {
    my $buff;
    shmread ($shmid, $buff, 0, 10) || die "$!";
    ### $buff
  }

  $X->handle_input;
  sleep 1;
  exit 0;
}

