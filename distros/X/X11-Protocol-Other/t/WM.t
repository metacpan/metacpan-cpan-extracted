#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2017, 2019 Kevin Ryde

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

my $test_count = (tests => 250)[1];
plan tests => $test_count;

require X11::Protocol::WM;

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
MyTestHelpers::X11_server_info($X);

my $window = $X->new_rsrc;
$X->CreateWindow ($window,
                  $X->{'root'},     # parent
                  'InputOutput',
                  0,                # depth, from parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  1,1,              # width,height
                  0);               # border
$X->MapWindow ($window);
$X->QueryPointer($X->{'root'});  # sync

my $window2 = $X->new_rsrc;
$X->CreateWindow ($window2,
                  $window,          # parent, so sub-window
                  'InputOutput',
                  0,                # depth, from parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  1,1,              # width,height
                  0);               # border

sub to_hex {
  my ($str) = @_;
  return join (' ',
               map {sprintf("%02X", ord(substr($str,$_,1)))}
               0 .. length($str)-1);
}

#------------------------------------------------------------------------------
# VERSION

my $want_version = 31;
ok ($X11::Protocol::WM::VERSION,
    $want_version,
    'VERSION variable');
ok (X11::Protocol::WM->VERSION,
    $want_version,
    'VERSION class method');

ok (eval { X11::Protocol::WM->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { X11::Protocol::WM->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# get_wm_icon_size()

{
  X11::Protocol::WM::get_wm_icon_size($X);
  X11::Protocol::WM::get_wm_icon_size($X, $X->root);

  $X->ChangeProperty($window,
                     $X->atom('WM_ICON_SIZE'),  # property
                     $X->atom('WM_ICON_SIZE'),  # type
                     32,                        # format
                     'Replace',                 # mode
                     pack ('L6', 1,2,3,4,5,6));

  my @ret = X11::Protocol::WM::get_wm_icon_size($X, $window);
  ok (join(',',@ret), '1,2,3,4,5,6', "WM_ICON_SIZE");

  $X->DeleteProperty($window, $X->atom('WM_ICON_SIZE'));
}

#------------------------------------------------------------------------------
# aspect_to_num_den()

{
  my $elem;
  foreach $elem ([1, 1,1],
                 [2, 2,1],
                 ['0.5', 5,10],
                 ['0.33', 33,100],
                 ['.33', 33,100],
                 ['12.34', 1234,100],
                 ['7/17', 7,17],

                 # current code grows in decimal ...
                 ['7.5/17', 75,170],
                 ['7.5/1.0', 75,10],
                 ['1.23/4.5', 123,450],
                 ['12.3/4.56', 1230,456],

                 # chopped down to maximum
                 [0x8000_0000, 0x7FFF_FFFF,1],

                 # not sure about this one
                 ['4294967296/4', 0x7FFF_FFFF,2],
                ) {
    my ($aspect, $want_num, $want_den) = @$elem;
    my ($got_num, $got_den) = X11::Protocol::WM::aspect_to_num_den($aspect);

    ok ($got_num, $want_num);
    ok ($got_den, $want_den);
  }
}

#------------------------------------------------------------------------------
# pack_wm_size_hints()

X11::Protocol::WM::pack_wm_size_hints($X,
                                      user_position => 1);
X11::Protocol::WM::pack_wm_size_hints($X,
                                      user_size => 1);

X11::Protocol::WM::pack_wm_size_hints($X,
                                      program_position => 1);
X11::Protocol::WM::pack_wm_size_hints($X,
                                      program_size => 1);

X11::Protocol::WM::pack_wm_size_hints($X,
                                      min_width => 100,
                                      min_height => 200);

X11::Protocol::WM::pack_wm_size_hints($X,
                                      max_width => 100,
                                      max_height => 200);
X11::Protocol::WM::pack_wm_size_hints($X,
                                      width_inc => 10,
                                      height_inc => 11);
X11::Protocol::WM::pack_wm_size_hints($X,
                                      base_width => 50,
                                      base_height => 60);

{
  my $bytes1 = X11::Protocol::WM::pack_wm_size_hints($X,
                                                     min_aspect => '1/2',
                                                     max_aspect => '3/4');
  my $bytes2 = X11::Protocol::WM::pack_wm_size_hints($X,
                                                     min_aspect_num => 1,
                                                     min_aspect_den => 2,
                                                     max_aspect_num => 3,
                                                     max_aspect_den => 4);
  ok ($bytes1, $bytes2);
}

{
  my $bytes1 = X11::Protocol::WM::pack_wm_size_hints($X,
                                                     win_gravity => 'NorthEast');
  my $bytes2 = X11::Protocol::WM::pack_wm_size_hints($X,
                                                     win_gravity => 4);
  ok ($bytes1, $bytes2);
}


#------------------------------------------------------------------------------
# pack_wm_size_hints()

{
  X11::Protocol::WM::set_wm_normal_hints($X, $window,
                                         user_position => 1,
                                         win_gravity => 'South');

  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window,
                       $X->atom('WM_NORMAL_HINTS'),
                       'AnyPropertyType',
                       0,   # offset
                       100, # length
                       0);  # delete
  ok ($format, 32);
  ok ($type, $X->atom('WM_SIZE_HINTS'));
  require X11::AtomConstants;
  ok ($type, X11::AtomConstants::WM_SIZE_HINTS());
  my $type_name = ($type ? $X->atom_name($type) : 'None');
  ok ($type_name, 'WM_SIZE_HINTS');
  # ok ($value, "...");
  ok ($bytes_after, 0);

  $X->DeleteProperty($window, $X->atom('WM_NORMAL_HINTS'));
}

#------------------------------------------------------------------------------
# unpack_wm_state()

{
  my @ret = X11::Protocol::WM::unpack_wm_state ($X, pack 'L2',0,0);
  ok (scalar(@ret), 2);
  ok ($ret[0], 'WithdrawnState');
  ok ($ret[1], 'None');
}
{
  my @ret = X11::Protocol::WM::unpack_wm_state ($X, pack 'L2',1,123);
  ok (scalar(@ret), 2);
  ok ($ret[0], 'NormalState');
  ok ($ret[1], 123);
}
{
  my @ret = X11::Protocol::WM::unpack_wm_state ($X, pack 'L2',3,123);
  ok (scalar(@ret), 2);
  ok ($ret[0], 'IconicState');
  ok ($ret[1], 123);
}

#------------------------------------------------------------------------------
# get_wm_state()

{
  my $target;
  foreach $target ($window, $X->{'root'}) {
    my @ret = X11::Protocol::WM::get_wm_state ($X, $target);
    ok (scalar(@ret) == 0 || scalar(@ret) == 2, 1,
        'get_wm_state() return 0 or 2 values');
    MyTestHelpers::diag ("WM_STATE: ",join(' ',@ret));
  }
}

{
  my $toplevel = $X->new_rsrc;
  $X->CreateWindow($toplevel,
                   $X->root,           # parent
                   'InputOutput',      # class
                   $X->root_depth,     # depth
                   'CopyFromParent',   # visual
                   0,0,                # x,y
                   100,100,            # width,height
                   10,                 # border
                   background_pixel => $X->{'white_pixel'},
                   override_redirect => 1,
                   colormap => 'CopyFromParent',
                  );

  my $subwin = $X->new_rsrc;
  $X->CreateWindow($subwin,
                   $toplevel,           # parent
                   'InputOutput',       # class
                   $X->root_depth,      # depth
                   'CopyFromParent',    # visual
                   0,0,                 # x,y
                   10,10,               # width,height
                   0,                   # border
                   background_pixel => $X->{'black_pixel'},
                   colormap => 'CopyFromParent',
                  );

  $X->ChangeProperty($subwin,
                     $X->atom('WM_STATE'),  # property
                     $X->atom('WM_STATE'),  # type
                     32,                    # format
                     'Replace',             # mode
                     pack ('L*', 1, 0));
  {
    my @ret = X11::Protocol::WM::get_wm_state ($X, $subwin);
    ok (scalar(@ret), 2);
    ok ($ret[0], 'NormalState');
    ok ($ret[1], 'None');
  }
  {
    local $X->{'do_interp'} = 0;
    my @ret = X11::Protocol::WM::get_wm_state ($X, $subwin);
    ok (scalar(@ret), 2);
    ok ($ret[0], 1);
    ok ($ret[1], 0);
  }

  $X->ChangeProperty($subwin,
                     $X->atom('WM_STATE'),  # property
                     $X->atom('WM_STATE'),  # type
                     32,                    # format
                     'Replace',             # mode
                     pack ('L*', 3, $toplevel));
  {
    my @ret = X11::Protocol::WM::get_wm_state ($X, $subwin);
    ok (scalar(@ret), 2);
    ok ($ret[0], 'IconicState');
    ok ($ret[1], $toplevel);
  }
  {
    local $X->{'do_interp'} = 0;
    my @ret = X11::Protocol::WM::get_wm_state ($X, $subwin);
    ok (scalar(@ret), 2);
    ok ($ret[0], 3);
    ok ($ret[1], $toplevel);
  }

  $X->ChangeProperty($subwin,
                     $X->atom('WM_STATE'),  # property
                     $X->atom('STRING'),    # type
                     8,                     # format
                     'Replace',             # mode
                     'Wrong data type');
  {
    my @ret = X11::Protocol::WM::get_wm_state ($X, $subwin);
    ok (scalar(@ret), 0);
  }

  $X->DeleteProperty($subwin, $X->atom('WM_STATE'));
  {
    my @ret = X11::Protocol::WM::get_wm_state ($X, $subwin);
    ok (scalar(@ret), 0);
  }

  $X->DestroyWindow($subwin);
  $X->DestroyWindow($toplevel);
}


#------------------------------------------------------------------------------
# get_net_frame_extents()

{
  my $target;
  foreach $target ($window, $X->{'root'}) {
    my @ret = X11::Protocol::WM::get_net_frame_extents ($X, $target);
    ok (scalar(@ret) == 0 || scalar(@ret) == 4, 1,
        'get_net_frame_extents() return 0 or 4 values');
    MyTestHelpers::diag ("_NET_FRAME_EXTENTS: ",join(' ',@ret));
  }
}

{
  my $toplevel = $X->new_rsrc;
  $X->CreateWindow($toplevel,
                   $X->root,           # parent
                   'InputOutput',      # class
                   $X->root_depth,     # depth
                   'CopyFromParent',   # visual
                   0,0,                # x,y
                   100,100,            # width,height
                   10,                 # border
                   background_pixel => $X->{'white_pixel'},
                   override_redirect => 1,
                   colormap => 'CopyFromParent',
                  );

  my $subwin = $X->new_rsrc;
  $X->CreateWindow($subwin,
                   $toplevel,           # parent
                   'InputOutput',       # class
                   $X->root_depth,      # depth
                   'CopyFromParent',    # visual
                   0,0,                 # x,y
                   10,10,               # width,height
                   0,                   # border
                   background_pixel => $X->{'black_pixel'},
                   colormap => 'CopyFromParent',
                  );

  $X->ChangeProperty($subwin,
                     $X->atom('_NET_FRAME_EXTENTS'),  # property
                     $X->atom('CARDINAL'),  # type
                     32,                    # format
                     'Replace',             # mode
                     pack ('L*', 11,22,33,44));
  {
    my @ret = X11::Protocol::WM::get_net_frame_extents ($X, $subwin);
    ok (scalar(@ret), 4);
    ok (join(',',@ret), '11,22,33,44');
  }

  $X->ChangeProperty($subwin,
                     $X->atom('_NET_FRAME_EXTENTS'),  # property
                     $X->atom('STRING'),    # type
                     8,                     # format
                     'Replace',             # mode
                     'Wrong data type');
  {
    my @ret = X11::Protocol::WM::get_net_frame_extents ($X, $subwin);
    ok (scalar(@ret), 0);
  }

  $X->DeleteProperty($subwin, $X->atom('_NET_FRAME_EXTENTS'));
  {
    my @ret = X11::Protocol::WM::get_net_frame_extents ($X, $subwin);
    ok (scalar(@ret), 0);
  }

  $X->DestroyWindow($subwin);
  $X->DestroyWindow($toplevel);
}


#------------------------------------------------------------------------------
# set_text_property()

{
  my $name = "hello world";
  X11::Protocol::WM::set_text_property ($X, $window2,
                                        $X->atom('WM_NAME'), $name);

  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('WM_NAME'),
                       'AnyPropertyType',
                       0,   # offset
                       100, # length
                       0);  # delete
  ok ($format, 8);
  ok ($type, $X->atom('STRING'));
  my $type_name = ($type ? $X->atom_name($type) : 'None');
  ok ($type_name, 'STRING');
  ok ($value, $name);
  ok ($bytes_after, 0);
}

#------------------------------------------------------------------------------
# set_wm_class()

{
  X11::Protocol::WM::set_wm_class ($X, $window2, "foo", "Foo");

  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('WM_CLASS'),
                       'AnyPropertyType',
                       0,   # offset
                       100, # length
                       0);  # delete
  ok ($format, 8);
  ok ($type, $X->atom('STRING'));
  my $type_name = ($type ? $X->atom_name($type) : 'None');
  ok ($type_name, 'STRING');
  ok ($value, "foo\0Foo\0");
  ok ($bytes_after, 0);
}


#------------------------------------------------------------------------------
# set_wm_client_machine()

{
  my $hostname = "mymachine";
  X11::Protocol::WM::set_wm_client_machine ($X, $window2, $hostname);

  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('WM_CLIENT_MACHINE'),
                       'AnyPropertyType',
                       0,   # offset
                       100, # length
                       0);  # delete
  ok ($format, 8);
  ok ($type, $X->atom('STRING'));
  my $type_name = ($type ? $X->atom_name($type) : 'None');
  ok ($type_name, 'STRING');
  ok ($value, $hostname);
  ok ($bytes_after, 0);
}
{
  X11::Protocol::WM::set_wm_client_machine_from_syshostname ($X, $window2);

  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('WM_CLIENT_MACHINE'),
                       'AnyPropertyType',
                       0,   # offset
                       100, # length
                       0);  # delete
  ok ($format, 8);
  ok ($type, $X->atom('STRING'));
  my $type_name = ($type ? $X->atom_name($type) : 'None');
  ok ($type_name, 'STRING');
  my $want_hostname = eval { Sys::Hostname::hostname() };
  ok ($value, $want_hostname);
  ok ($bytes_after, 0);
}


#------------------------------------------------------------------------------
# set_wm_command()

{
  X11::Protocol::WM::set_wm_command ($X, $window2, "myprog", "myarg");

  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('WM_COMMAND'),
                       'AnyPropertyType',
                       0,   # offset
                       100, # length
                       0);  # delete
  ok ($format, 8);
  ok ($type, $X->atom('STRING'));
  my $type_name = ($type ? $X->atom_name($type) : 'None');
  ok ($type_name, 'STRING');
  ok ($value, "myprog\0myarg\0");
  ok ($bytes_after, 0);
}

{
  # with some latin-1 chars
  my $command = "\xF7";
  X11::Protocol::WM::set_wm_command ($X, $window2, $command);

  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('WM_COMMAND'),
                       'AnyPropertyType',
                       0,   # offset
                       100, # length
                       0);  # delete
  ok ($format, 8);
  ok ($type, $X->atom('STRING'));
  my $type_name = ($type ? $X->atom_name($type) : 'None');
  ok ($type_name, 'STRING');
  ok (to_hex($value), to_hex("$command\0"));
  ok ($bytes_after, 0);
}


#------------------------------------------------------------------------------
# set_wm_icon_name()

{
  my $icon_name = "hello world";
  X11::Protocol::WM::set_wm_icon_name ($X, $window2, $icon_name);

  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('WM_ICON_NAME'),
                       'AnyPropertyType',
                       0,   # offset
                       100, # length
                       0);  # delete
  ok ($format, 8);
  ok ($type, $X->atom('STRING'));
  my $type_name = ($type ? $X->atom_name($type) : 'None');
  ok ($type_name, 'STRING');
  ok ($value, $icon_name);
  ok ($bytes_after, 0);
}


#------------------------------------------------------------------------------
# set_wm_name()

{
  my $name = "hello world";
  X11::Protocol::WM::set_wm_name ($X, $window2, $name);

  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('WM_NAME'),
                       'AnyPropertyType',
                       0,   # offset
                       100, # length
                       0);  # delete
  ok ($format, 8);
  ok ($type, $X->atom('STRING'));
  my $type_name = ($type ? $X->atom_name($type) : 'None');
  ok ($type_name, 'STRING');
  ok ($value, $name);
  ok ($bytes_after, 0);
}


#------------------------------------------------------------------------------
# set_wm_protocols()

X11::Protocol::WM::set_wm_protocols ($X, $window2, 'WM_DELETE_WINDOW');
{
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('WM_PROTOCOLS'),
                       'AnyPropertyType',
                       0,   # offset
                       100, # max length x CARD32
                       0);  # delete
  ok ($format, 32);
  ok ($type, $X->atom('ATOM'));
  ok ($X->atom_name($type), 'ATOM');
  ok (length($value), 4);
  my ($value_atom) = unpack 'L', $value;
  ok ($value_atom, $X->atom('WM_DELETE_WINDOW'));
  ok (length($value)>=4 && $X->atom_name($value_atom),
      'WM_DELETE_WINDOW');
  ok ($bytes_after, 0);
}

X11::Protocol::WM::set_wm_protocols ($X, $window2,
                                     $X->atom('WM_DELETE_WINDOW'),
                                     'MY_PRIVATE_SOMETHING');
{
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('WM_PROTOCOLS'),
                       'AnyPropertyType',
                       0,   # offset
                       100, # max length x CARD32
                       0);  # delete
  ok ($format, 32);
  ok ($type, $X->atom('ATOM'));
  ok ($X->atom_name($type), 'ATOM');
  ok (length($value), 8);
  my ($value_atom1, $value_atom2) = unpack 'L*', $value;
  ok ($value_atom1, $X->atom('WM_DELETE_WINDOW'));
  ok ($X->atom_name($value_atom1), 'WM_DELETE_WINDOW');
  ok ($value_atom2, $X->atom('MY_PRIVATE_SOMETHING'));
  ok ($X->atom_name($value_atom2), 'MY_PRIVATE_SOMETHING');
  ok ($bytes_after, 0);
}

X11::Protocol::WM::set_wm_protocols ($X, $window2);
{
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('WM_PROTOCOLS'),
                       'AnyPropertyType',
                       0,  # offset
                       2,  # length, 2 x CARD32
                       0); # delete
  ok ($format, 0);
  ok ($type eq 'None' || $type == 0, 1);
}


#------------------------------------------------------------------------------
# set_wm_transient_for()

{
  my $elem;
  foreach $elem ([$window, $window], # a window
                 [0, 0],             # 0==None
                 ['None', 0],        # 0==None
                 [undef, undef],     # delete
                ) {
    my ($transient_for, $want) = @$elem;
    X11::Protocol::WM::set_wm_transient_for ($X, $window2, $transient_for);

    my ($value, $type, $format, $bytes_after)
      = $X->GetProperty ($window2,
                         $X->atom('WM_TRANSIENT_FOR'),
                         'AnyPropertyType',
                         0,  # offset
                         1,  # length, 1 x CARD32
                         0); # delete
    ok ($format, (defined $want ? 32 : 0));
    ok ($type, (defined $want ? $X->atom('WINDOW') : 0));
    my $type_name = ($type ? $X->atom_name($type) : 'None');
    ok ($type_name, (defined $want ? 'WINDOW' : 'None'));
    my ($got) = unpack 'L', $value;
    ok ($got, $want, $window);
    ok ($bytes_after, 0);
  }
}

#------------------------------------------------------------------------------
# get_wm_transient_for()
# ok ($window,
#     X11::Protocol::WM::get_wm_transient_for($X,$window2,$window),
#    'get_wm_transient_for()/set_wm_transient_for()');


#------------------------------------------------------------------------------
# _net_wm_state_num()

{
  my $atom = $X->atom('_NET_WM_STATE_FULLSCREEN');
  X11::Protocol::WM::_net_wm_state_num
      ('FULLSCREEN', $atom,
       '_net_wm_state_num() FULLSCREEN');
  X11::Protocol::WM::_net_wm_state_num
      ('_NET_WM_STATE_FULLSCREEN', $atom,
       '_net_wm_state_num() _NET_WM_STATE_FULLSCREEN');
  X11::Protocol::WM::_net_wm_state_num
      ($atom, $atom,
       '_net_wm_state_num() integer unchanged');

  ok (X11::Protocol::WM::_net_wm_state_interp($X,$atom), 'FULLSCREEN');
  $atom = $X->atom('SOME_BOGOSITY');
  ok (X11::Protocol::WM::_net_wm_state_interp($X,$atom), 'SOME_BOGOSITY');
}

ok (X11::Protocol::WM::_net_wm_state_action_num($X,0), 0);
ok (X11::Protocol::WM::_net_wm_state_action_num($X,1), 1);
ok (X11::Protocol::WM::_net_wm_state_action_num($X,2), 2);
ok (X11::Protocol::WM::_net_wm_state_action_num($X,'remove'), 0);
ok (X11::Protocol::WM::_net_wm_state_action_num($X,'add'),    1);
ok (X11::Protocol::WM::_net_wm_state_action_num($X,'toggle'), 2);

ok (X11::Protocol::WM::_net_wm_source_num($X,0), 0);
ok (X11::Protocol::WM::_net_wm_source_num($X,1), 1);
ok (X11::Protocol::WM::_net_wm_source_num($X,2), 2);
ok (X11::Protocol::WM::_net_wm_source_num($X,'none'),   0);
ok (X11::Protocol::WM::_net_wm_source_num($X,'normal'), 1);
ok (X11::Protocol::WM::_net_wm_source_num($X,'user'),   2);

#------------------------------------------------------------------------------
# set_net_wm_state()

{
  X11::Protocol::WM::set_net_wm_state ($X, $window2, '_NET_WM_STATE_SKIP_PAGER');
  {
    my ($value, $type, $format, $bytes_after)
      = $X->GetProperty ($window2,
                         $X->atom('_NET_WM_STATE'),
                         'AnyPropertyType',
                         0,  # offset
                         1,  # length, 1 x CARD32
                         0); # delete
    ok ($format, 32, 'set_net_wm_state');
    ok ($type, $X->atom('ATOM'));
    my ($got) = unpack 'L*', $value;
    ok ($got, $X->atom('_NET_WM_STATE_SKIP_PAGER'));
    ok ($bytes_after, 0);
  }
  {
    my @ret = X11::Protocol::WM::get_net_wm_state ($X, $window2);
    ok (scalar(@ret), 1);
    ok ($ret[0], 'SKIP_PAGER');
  }
  {
    my @ret = X11::Protocol::WM::get_net_wm_state_atoms ($X, $window2);
    ok (scalar(@ret), 1);
    ok ($ret[0], $X->atom('_NET_WM_STATE_SKIP_PAGER'));
  }
}

{
  X11::Protocol::WM::set_net_wm_state ($X, $window2,
                                       'SKIP_PAGER', 'SKIP_TASKBAR');
  {
    my ($value, $type, $format, $bytes_after)
      = $X->GetProperty ($window2,
                         $X->atom('_NET_WM_STATE'),
                         'AnyPropertyType',
                         0,  # offset
                         2,  # length, 2 x CARD32
                         0); # delete
    ok ($format, 32, 'set_net_wm_state');
    ok ($type, $X->atom('ATOM'));
    ok (length($value), 8);
    my ($got1, $got2) = unpack 'L*', $value;
    ok ($got1, $X->atom('_NET_WM_STATE_SKIP_PAGER'));
    ok ($got2, $X->atom('_NET_WM_STATE_SKIP_TASKBAR'));
    ok ($bytes_after, 0);
  }
  {
    my @ret = X11::Protocol::WM::get_net_wm_state ($X, $window2);
    ok (scalar(@ret), 2);
    ok ($ret[0], 'SKIP_PAGER');
    ok ($ret[1], 'SKIP_TASKBAR');
  }
  {
    my @ret = X11::Protocol::WM::get_net_wm_state_atoms ($X, $window2);
    ok (scalar(@ret), 2);
    ok ($ret[0], $X->atom('_NET_WM_STATE_SKIP_PAGER'));
    ok ($ret[1], $X->atom('_NET_WM_STATE_SKIP_TASKBAR'));
  }
}

#------------------------------------------------------------------------------
# pack_wm_hints()

{
  my $format = 'LLLLLllLL';
  ok (X11::Protocol::WM::pack_wm_hints($X),
      pack($format));

  ok (X11::Protocol::WM::pack_wm_hints ($X,
                                        input => 1),
      pack($format,1,1));

  ok (X11::Protocol::WM::pack_wm_hints ($X,
                                        input => 1,
                                        initial_state => 'IconicState'),
      pack($format,1|2,1,3));

  ok (X11::Protocol::WM::pack_wm_hints ($X,
                                        icon_pixmap => 123,
                                        icon_mask => 456),
      pack($format,4|32,0,0,123,0,0,0,456));

  ok (X11::Protocol::WM::pack_wm_hints ($X,
                                        icon_x  => 123,
                                        icon_y  => 456),
      pack($format,16,0,0,0,0,123,456));

  ok (X11::Protocol::WM::pack_wm_hints ($X,
                                        urgency => 1),
      pack($format,256));
}
{
  my $bytes1 = X11::Protocol::WM::pack_wm_hints
    ($X, initial_state => 'NormalState');
  my $bytes2 = X11::Protocol::WM::pack_wm_hints
    ($X, initial_state => 1);
  ok ($bytes1, $bytes2);
}


#------------------------------------------------------------------------------
# unpack_wm_hints()

{
  my $format = 'LLLLLllLL';
  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,0))),
      '');

  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,1,0))),
      'input,0');
  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,1,123))),
      'input,123');

  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,2,0,1))),
      'initial_state,NormalState');
  { local $X->{'do_interp'} = 0;
    ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,2,0,1))),
        'initial_state,1');
  }

  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,4,0,0,123))),
      'icon_pixmap,123');
  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,4))),
      'icon_pixmap,None');
  { local $X->{'do_interp'} = 0;
    ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,4))),
        'icon_pixmap,0');
  }

  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,8,0,0,0,123))),
      'icon_window,123');
  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,8))),
      'icon_window,None');
  { local $X->{'do_interp'} = 0;
    ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,8))),
        'icon_window,0');
  }

  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,16,0,0,0,0,123,456))),
      'icon_x,123,icon_y,456');

  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,32,0,0,0,0,0,0,123))),
      'icon_mask,123');
  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,32))),
      'icon_mask,None');
  { local $X->{'do_interp'} = 0;
    ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,32))),
        'icon_mask,0');
  }

  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,64,0,0,0,0,0,0,0,123))),
      'window_group,123');
  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,64))),
      'window_group,None');
  { local $X->{'do_interp'} = 0;
    ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,64))),
        'window_group,0');
  }

  # hints from X11R2 only 8 cards with window_group flag but field chopped off
  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack('LLLLLllL',
                                                          64,0,0,0,0,0,0,0))),
      '');

  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,128))),
      'message,1');

  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,256))),
      'urgency,1');

  ok (join(',',X11::Protocol::WM::unpack_wm_hints($X,pack($format,64|256,0,0,0,0,0,0,0,123))),
      'window_group,123,urgency,1');
}

#------------------------------------------------------------------------------
# set_wm_hints() / get_wm_hints() / change_wm_hints()

{
  my $pixmap = $X->new_rsrc;
  $X->CreatePixmap ($pixmap,
                    $X->root,
                    $X->{'root_depth'},
                    16,16);  # width,height

  my $bitmap = $X->new_rsrc;
  $X->CreatePixmap ($bitmap,
                    $X->root,
                    1,       # depth 1 bitmap
                    16,16);  # width,height

  my $icon_window = $X->new_rsrc;
  $X->CreateWindow($icon_window,
                   $X->root,           # parent
                   'InputOutput',      # class
                   $X->root_depth,     # depth
                   'CopyFromParent',   # visual
                   0,0,                # x,y
                   32,32,              # width,height
                   1,                  # border
                   background_pixel => $X->{'black_pixel'},
                   colormap => 'CopyFromParent');
  $X->QueryPointer($X->root);  # sync

  X11::Protocol::WM::set_wm_hints ($X, $window,
                                   input => 1,
                                   initial_state => 'NormalState',
                                   icon_x  => 123,
                                   icon_y  => 456,
                                   urgency => 1);
  ok (join(',',X11::Protocol::WM::get_wm_hints($X,$window)),
      'input,1,initial_state,NormalState,icon_x,123,icon_y,456,urgency,1');

  # individual fields to see others default ...
  X11::Protocol::WM::set_wm_hints ($X, $window, input => 1);
  ok (join(',',X11::Protocol::WM::get_wm_hints($X,$window)),
      'input,1');
  X11::Protocol::WM::set_wm_hints ($X, $window, initial_state => 'IconicState');
  X11::Protocol::WM::set_wm_hints ($X, $window, icon_pixmap => 'None');
  X11::Protocol::WM::set_wm_hints ($X, $window, icon_pixmap => 0);
  ok (join(',',X11::Protocol::WM::get_wm_hints($X,$window)),
      'icon_pixmap,None');
  X11::Protocol::WM::set_wm_hints ($X, $window, icon_pixmap => $pixmap);
  X11::Protocol::WM::set_wm_hints ($X, $window, icon_window => 'None');
  X11::Protocol::WM::set_wm_hints ($X, $window, icon_window => 0);
  X11::Protocol::WM::set_wm_hints ($X, $window, icon_window => $icon_window);
  X11::Protocol::WM::set_wm_hints ($X, $window,
                                   icon_x => 123,
                                   icon_y => 456);
  X11::Protocol::WM::set_wm_hints ($X, $window, icon_mask => 'None');
  X11::Protocol::WM::set_wm_hints ($X, $window, icon_mask => 0);
  X11::Protocol::WM::set_wm_hints ($X, $window, icon_mask => $bitmap);
  X11::Protocol::WM::set_wm_hints ($X, $window, urgency => 1);

  X11::Protocol::WM::set_wm_hints ($X, $icon_window, window_group => 'None');
  X11::Protocol::WM::set_wm_hints ($X, $icon_window, window_group => 0);
  X11::Protocol::WM::set_wm_hints ($X, $icon_window, window_group => $window);

  # change to already set
  X11::Protocol::WM::set_wm_hints    ($X, $window, urgency => 1);
  X11::Protocol::WM::change_wm_hints ($X, $window, urgency => 1);
  ok (join(',',X11::Protocol::WM::get_wm_hints($X,$window)),
      'urgency,1');

  X11::Protocol::WM::change_wm_hints ($X, $window, window_group => $window);
  ok (join(',',X11::Protocol::WM::get_wm_hints($X,$window)),
      "window_group,$window,urgency,1");

  X11::Protocol::WM::change_wm_hints ($X, $window, window_group => undef);
  ok (join(',',X11::Protocol::WM::get_wm_hints($X,$window)),
      'urgency,1');

  X11::Protocol::WM::change_wm_hints ($X, $window,
                                      initial_state => 'IconicState');
  ok (join(',',X11::Protocol::WM::get_wm_hints($X,$window)),
      'initial_state,IconicState,urgency,1');

  X11::Protocol::WM::change_wm_hints ($X, $window,
                                      initial_state => 'NormalState');
  ok (join(',',X11::Protocol::WM::get_wm_hints($X,$window)),
      'initial_state,NormalState,urgency,1');

  $X->FreePixmap($pixmap);
  $X->FreePixmap($bitmap);
  $X->DestroyWindow($icon_window);
  $X->QueryPointer($X->root);  # sync
}


#------------------------------------------------------------------------------
# set_net_wm_pid()

X11::Protocol::WM::set_net_wm_pid ($X, $window2);
{
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('_NET_WM_PID'),
                       'AnyPropertyType',
                       0,  # offset
                       1,  # length, 1 x CARD32
                       0); # delete
  ok ($format, 32);
  ok ($type, $X->atom('CARDINAL'));
  ok ($X->atom_name($type), 'CARDINAL');
  ok (length($value), 4);
  my ($pid) = unpack 'L', $value;
  ok ($pid, $$);
  ok ($bytes_after, 0);
}

X11::Protocol::WM::set_net_wm_pid ($X, $window2, 123);
{
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('_NET_WM_PID'),
                       'AnyPropertyType',
                       0,  # offset
                       1,  # length, 1 x CARD32
                       0); # delete
  ok ($format, 32);
  ok ($type, $X->atom('CARDINAL'));
  ok ($X->atom_name($type), 'CARDINAL');
  ok (length($value), 4);
  my ($pid) = unpack 'L', $value;
  ok ($pid, 123);
  ok ($bytes_after, 0);
}

X11::Protocol::WM::set_net_wm_pid ($X, $window2, undef);
{
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('_NET_WM_PID'),
                       'AnyPropertyType',
                       0,  # offset
                       1,  # length, 1 x CARD32
                       0); # delete
  ok ($format, 0);
  ok ($type eq 'None' || $type == 0, 1);
}

#------------------------------------------------------------------------------
# set_net_wm_user_time()

X11::Protocol::WM::set_net_wm_user_time ($X, $window, 123);
{
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window,
                       $X->atom('_NET_WM_USER_TIME'),
                       'AnyPropertyType',
                       0,  # offset
                       1,  # length, 1 x CARD32
                       0); # delete
  ok ($format, 32);
  ok ($type, $X->atom('CARDINAL'));
  ok ($X->atom_name($type), 'CARDINAL');
  ok (length($value), 4);
  my ($time) = unpack 'L', $value;
  ok ($time, 123);
  ok ($bytes_after, 0);
}

#------------------------------------------------------------------------------
# set_net_wm_window_type()

X11::Protocol::WM::set_net_wm_window_type ($X, $window, 'NORMAL');
{
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window,
                       $X->atom('_NET_WM_WINDOW_TYPE'),
                       'AnyPropertyType',
                       0,  # offset
                       1,  # length, 1 x CARD32
                       0); # delete
  ok ($format, 32);
  ok ($type, $X->atom('ATOM'));
  ok ($X->atom_name($type), 'ATOM');
  ok (length($value), 4);
  my ($value_atom) = unpack 'L', $value;
  ok ($value_atom, $X->atom('_NET_WM_WINDOW_TYPE_NORMAL'));
  ok ($X->atom_name($value_atom), '_NET_WM_WINDOW_TYPE_NORMAL');
  ok ($bytes_after, 0);
}

#------------------------------------------------------------------------------
# get_net_wm_window_type()
# {
#   my $atom_name = $X->atom_name($atom);
#   ok ($atom_name, '_NET_WM_WINDOW_TYPE_NORMAL', 'set_net_wm_window_type');
# 
#   # my $atom = X11::Protocol::WM::_get_net_wm_window_type_atom ($X, $window);
# }

#------------------------------------------------------------------------------
# frame_window_to_client()

{
  my ($root_root, $root_parent, @toplevels) = $X->QueryTree ($X->root);
  my $window;
  my $count_found = 0;
  foreach $window (@toplevels) {
    my $client_window = X11::Protocol::WM::frame_window_to_client($X,$window);
    $count_found += (defined $client_window);
  }
  MyTestHelpers::diag ("frame_window_to_client() found $count_found clients out of ",scalar(@toplevels)," toplevels");
}


#------------------------------------------------------------------------------
# iconify() and withdraw() transitions

{
  my $toplevel = $X->new_rsrc;
  $X->CreateWindow($toplevel,
                   $X->root,           # parent
                   'InputOutput',      # class
                   $X->root_depth,     # depth
                   'CopyFromParent',   # visual
                   0,0,                # x,y
                   100,100,            # width,height
                   10,                 # border
                   background_pixel => $X->{'white_pixel'},
                   event_mask       => $X->pack_event_mask('PropertyChange'));
  $X->MapWindow($toplevel);
  $X->atom_name($X->atom('WM_STATE'));

  my $skip;

  # The tests hare are all skipped because don't want to rely on window
  # manager behaviour.  Some wms don't seem to have a proper withdraw, and
  # several by design don't have an IconicState.
  #
  # Window managers without IconicState include: dwm, evilwm, i3, sapphire,
  # subtle, wmii, xmonad.
  #
  # tritium uses python-plwm and python-plwm (as of its cvs circa 2008) may
  # have some dodginess too in its deiconify() where it leaves WM_STATE
  # saying IconicState even though it has in fact restored the window to
  # normal.
  #
  $skip = 'due to not rely on window manager behaviour';

  my $wm_state;
  unless ($skip) {
    $wm_state = wait_for_wm_state($X,$toplevel);
    if (! $wm_state) {
      $skip = 'due to no window manager running, it seems';
    }
  }
  skip ($skip, $wm_state, 'NormalState');

  {
    X11::Protocol::WM::iconify($X,$toplevel);
    unless ($skip) { $wm_state = wait_for_wm_state($X,$toplevel); }
    skip ($skip, $wm_state, 'IconicState');
  }
  {
    X11::Protocol::WM::withdraw($X,$toplevel);
    unless ($skip) { $wm_state = wait_for_wm_state($X,$toplevel); }
    my $is_withdrawn = (! defined $wm_state || $wm_state eq 'WithdrawnState');
    skip ($skip, $is_withdrawn, 1, 'withdrawn');
    if (! $is_withdrawn) {
      MyTestHelpers::diag ("after withdraw() wm_state is: ", $wm_state);
    }
  }
  {
    $X->MapWindow($toplevel);
    unless ($skip) { $wm_state = wait_for_wm_state($X,$toplevel); }
    skip ($skip, $wm_state, 'NormalState');
  }
  { X11::Protocol::WM::withdraw($X,$toplevel);
    unless ($skip) { $wm_state = wait_for_wm_state($X,$toplevel); }
    my $is_withdrawn = (! defined $wm_state || $wm_state eq 'WithdrawnState');
    skip ($skip, $is_withdrawn, 1, 'withdrawn again');
  }

  $X->DestroyWindow($toplevel);
  $X->QueryPointer($X->root);  # sync
}

sub wait_for_wm_state {
  my ($X, $window) = @_;
  $X->flush;
  my $WM_STATE = $X->atom('WM_STATE');
  my $found = 0;
  local $X->{'event_handler'} = sub {
    my (%h) = @_;
    ### event_handler: \%h
    # MyTestHelpers::diag ("event ", $h{'name'},
    #                      ' ',$h{'window'},
    #                      ' ',$h{'atom'},
    #                      '=', $h{'atom'} && $X->{'atom_names'}->[$h{'atom'}]);
    if ($h{'name'} eq 'PropertyNotify'
        && $h{'window'} == $window
        && $h{'atom'} == $WM_STATE) {
      $found = 1;
    }
  };
  foreach (1 .. 4) {  # attempts
    if (wait_for_readable ($X->{'connection'}->fh)) {
      ### X handle_input ...
      while (fh_readable ($X->{'connection'}->fh)) {
        $X->handle_input;
      }
    }
    if ($found) {
      my ($wm_state, $icon_window)
        = X11::Protocol::WM::get_wm_state ($X, $window);
      return $wm_state;
    }
  }
  return 'timeout waiting for WM_STATE change';
}

sub wait_for_readable {
  my ($fh) = @_;
  my $read_bits = '';
  vec($read_bits,fileno($fh),1) = 1;
  my $err_bits = $read_bits;

  my ($nfound, $timeleft) = select($read_bits, '', $err_bits,
                                   1); # 1 second timeout
  return $nfound;
}

sub fh_readable {
  my ($fh) = @_;
  require IO::Select;
  my $s = IO::Select->new;
  $s->add($fh);
  my @ready = $s->can_read(1);
  return scalar(@ready);
}

#------------------------------------------------------------------------------
$X->QueryPointer($X->{'root'});  # sync

exit 0;
