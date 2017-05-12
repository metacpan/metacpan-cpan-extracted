#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

BEGIN { require 5 }
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $test_count = (tests => 4)[1];
plan tests => $test_count;

use X11::Protocol::WM
  'frame_window_to_client',
  'root_to_virtual_root',
  'change_wm_hints',
  'change_net_wm_state',
  'get_wm_icon_size',
  'get_wm_hints',
  'get_wm_state',
  'get_net_frame_extents',
  'get_net_wm_state',
  'set_text_property',
  'set_wm_class',
  'set_wm_client_machine',
  'set_wm_client_machine_from_syshostname',
  'set_wm_command',
  'set_wm_hints',
  'set_wm_icon_name',
  'set_wm_name',
  'set_wm_normal_hints',
  'set_wm_protocols',
  'set_wm_transient_for',
  'set_motif_wm_hints',
  'set_net_wm_pid',
  'set_net_wm_state',
  'set_net_wm_user_time',
  'set_net_wm_window_type',
  'pack_wm_hints',
  'pack_wm_size_hints',
  'pack_motif_wm_hints',
  'unpack_wm_hints',
  'unpack_wm_state',
  'aspect_to_num_den',
  'iconify',
  'withdraw',
  ;

require X11::Protocol;
MyTestHelpers::diag ("X11::Protocol version ", X11::Protocol->VERSION);

my $display = $ENV{'DISPLAY'};
if (! defined $display) {
  MyTestHelpers::diag ('No DISPLAY set');
  foreach (1 .. $test_count) {
    skip ('No DISPLAY set', 1, 1);
  }
  exit 0;
}
MyTestHelpers::diag ("DISPLAY $display");

# pass display arg so as not to get a "guess" warning
my $X;
if (! eval { $X = X11::Protocol->new ($display); }) {
  MyTestHelpers::diag ("Cannot connect to X server -- $@");
  foreach (1 .. $test_count) {
    skip ("Cannot connect to X server", 1, 1);
  }
  exit 0;
}

$X->QueryPointer($X->{'root'});  # sync

my $window = $X->new_rsrc;
$X->CreateWindow ($window,
                  $X->{'root'},     # parent
                  'InputOutput',
                  0,                # depth, from parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  1,1,              # width,height
                  0);               # border
my $window2 = $X->new_rsrc;
$X->CreateWindow ($window2,
                  $window,          # parent
                  'InputOutput',
                  0,                # depth, from parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  1,1,              # width,height
                  0);               # border


change_wm_hints($X,$window, input => 0);
{ my $client_window = frame_window_to_client($X,$window); }
{ my $vroot = root_to_virtual_root($X,$X->root); }
{ get_wm_icon_size($X);
  get_wm_icon_size($X,$X->root); }
{ my %hash = get_wm_hints($X,$window); }
{ my ($state, $icon_window) = get_wm_state($X,$window); }
{ my ($left,$right,$top,$bottom) = get_wm_state($X,$window); }
set_text_property($X, $window, $X->atom('WM_NAME'), 'hello');
set_wm_class($X,$window,"foo","Foo");
set_wm_client_machine($X,$window,"mymachine");
set_wm_client_machine_from_syshostname($X,$window);
set_wm_command($X,$window,"");
set_wm_hints($X,$window,input=>1);
set_wm_icon_name($X,$window,"myicon");
set_wm_name($X,$window,"my title!");
set_wm_normal_hints($X,$window);
set_wm_protocols($X,$window,'WM_DELETE_WINDOW');
set_net_wm_state($X,$window2,'_NET_WM_STATE_SKIP_PAGER');
set_wm_transient_for($X,$window2,$window);
{
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('WM_TRANSIENT_FOR'),
                       'AnyPropertyType',
                       0,  # offset
                       1,  # length, 1 x CARD32
                       0); # delete
  ok ($format, 32);
  ok ($type, $X->atom('WINDOW'));
  my ($unpack) = unpack 'L', $value;
  ok ($unpack, $window);

  # ok ($window, get_wm_transient_for($X,$window2,$window));
}
set_motif_wm_hints($X,$window);
set_net_wm_pid($X,$window);
set_net_wm_user_time($X,$window,0);
set_net_wm_window_type($X,$window,'SPLASH');

pack_motif_wm_hints($X);
pack_wm_hints($X);
pack_wm_size_hints($X);
unpack_wm_state($X, pack('LL',0,0));
aspect_to_num_den('1/3');

iconify($X,$window);
iconify($X,$window,$X->root);
withdraw($X,$window);
withdraw($X,$window,$X->root);

$X->QueryPointer($X->{'root'});  # sync
ok (1, 1);

exit 0;
