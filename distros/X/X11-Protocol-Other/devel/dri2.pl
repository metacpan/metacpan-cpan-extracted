#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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


use lib 'devel/lib';
$ENV{'DISPLAY'} ||= ":0";



use strict;
use X11::Protocol;

# uncomment this to run the ### lines
use Smart::Comments;


my $X = X11::Protocol->new;

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
### $window

$X->init_extension('DRI2') or die $@;
{
  my @version = $X->DRI2QueryVersion (1,3);
  ### @version
}
{
  my @auth = $X->DRI2Authenticate($window,123);
  ### @auth
}
{
  my @connect = $X->DRI2Connect($window,'DRI');
  ### @connect
}
# {
#   my @connect = $X->DRI2Connect($window,'VDPAU');
#   ### @connect
# }
{
  my @buffers = $X->DRI2GetBuffers($window,2);
  ### @buffers
  $X->QueryPointer($X->{'root'}); # sync
}
{
  my @counters = $X->DRI2GetMSC($window);
  ### @counters
  $X->QueryPointer($X->{'root'}); # sync
}
exit 0;


$X->flush;
sleep 1;

{
  $X->WarpPointer ('None', $window, 0,0,0,0, 10,10);
  ### ButtonPress ...
  $X->SetPointerMapping(3, 2, 1, 4 .. 10);
  $X->Dri2FakeInput ([ name   => 'ButtonPress',
                        detail => 1 ]);
  $X->Dri2FakeInput (name   => 'ButtonRelease',
                      time   => 2000,
                      detail => 1);
  $X->SetPointerMapping(1 .. 10);
  for (;;) {
    $X->handle_input;
  }
  exit 0;
}

{
  ### MotionNotify ...
  $X->Dri2FakeInput ({ name   => 'MotionNotify',
                        detail => 0,
                        root_x => 20,
                        root_y => 20,
                      });
  for (;;) {
    $X->handle_input;
  }
  exit 0;
}


# my $window = $X->root;
# my $status = $X->GrabPointer
#   ($window,          # window
#    0,              # owner events
#    $X->pack_event_mask('ButtonPress','ButtonRelease','PointerMotion'),
#    'Synchronous',  # pointer mode
#    'Asynchronous', # keyboard mode
#    0,          # confine window
#    0,          # cursor
#    0);         # time
# ### $status
# $X->QueryPointer($X->{'root'}); # sync
#
# $X->AllowEvents ('SyncPointer', 'CurrentTime');
# $X->QueryPointer($X->{'root'}); # sync

# $X->ChangeWindowAttributes
#   ($window,
#    event_mask => $X->pack_event_mask('ButtonPress','ButtonRelease'));
# $X->QueryPointer($X->{'root'}); # sync

$X->flush;
sleep 1;
$X->Dri2FakeInput ($X->pack_event
                     (name    => 'ButtonPress',
                      detail  => 3,
                      time    => 0,
                      root    => 0,
                      event   => 0,
                      child   => 'None',
                      root_x  => 0,
                      root_y  => 0,
                      event_x => 0,
                      event_y => 0,
                      state   => 0,
                      same_screen => 0));
$X->flush;
sleep 10;
$X->Dri2FakeInput ($X->pack_event
                     (name   => 'ButtonRelease',
                      detail => 3,
                      time   => 0,
                      root   => 0,
                      event  => 0,
                      child => 'None',
                      root_x => 0,
                      root_y => 0,
                      event_x => 0,
                      event_y => 0,
                      state   => 0,
                      same_screen => 0));

for (;;) {
  $X->handle_input;
}
exit 0;
