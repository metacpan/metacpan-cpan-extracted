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

use 5.004;
use strict;
use X11::Protocol;
use X11::Protocol::WM;

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $X = X11::Protocol->new;

  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $X->root,         # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    500,0,              # x,y
                    100,100,          # width,height
                    0,                # border
                    background_pixel => $X->black_pixel,
                   );
  X11::Protocol::WM::set_wm_normal_hints
      ($X, $window,

       user_position => 1,
       # program_position => 1,
       # program_size => 1,
       user_size => 1,

       min_width => 20,
       min_width => 40,
       max_width => 400,
       max_height => 800,

       base_width => 5,
       width_inc => 10,

       base_height => 15,
       height_inc => 20,

       min_aspect => '1/3',
       max_aspect => '3/1',
      );

  $X->MapWindow ($window);
  for (;;) { $X->handle_input }
  exit 0;
}

