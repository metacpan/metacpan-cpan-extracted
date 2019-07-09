#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde

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


# Listen to WM_DELETE_WINDOW messages on a top-level client window.
#

use strict;
use FindBin;
use X11::Protocol;
use X11::Protocol::WM;

use lib 'devel', '.';

# uncomment this to run the ### lines
# use Smart::Comments;

$|=1;
my $X = X11::Protocol->new;

my $window = $X->new_rsrc;
$X->CreateWindow ($window,
                  $X->root,         # parent
                  'InputOutput',    # class
                  $X->root_depth,   # depth
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  128,128,          # w,h initial size
                  0,                # border
                  background_pixel => $X->black_pixel,
                 );
X11::Protocol::WM::set_wm_name ($X, $window, $FindBin::Script);
X11::Protocol::WM::set_wm_hints ($X, $window, input => 1);
X11::Protocol::WM::set_wm_protocols ($X, $window,
                                     'WM_SAVE_YOURSELF',
                                     'WM_DELETE_WINDOW');
$X->MapWindow ($window);
$X->ClearArea ($window, 0,0,0,0);

my $WM_PROTOCOLS = $X->atom('WM_PROTOCOLS');
printf "WM_PROTOCOLS = %d 0x%X  %s\n", $WM_PROTOCOLS, $WM_PROTOCOLS,
  $X->atom_name($WM_PROTOCOLS);

my $WM_DELETE_WINDOW = $X->atom('WM_DELETE_WINDOW');
printf "WM_DELETE_WINDOW = %d 0x%X  %s\n", $WM_DELETE_WINDOW, $WM_DELETE_WINDOW,
  $X->atom_name($WM_DELETE_WINDOW);

{
  my $a = 0x1c0;
  printf "a = %d 0x%X  %s\n", $a, $a, $X->atom_name($a);
}

$X->{'event_handler'} = sub {
  my (%h) = @_;
  ### event_handler: \%h

  if ($h{'name'} eq 'ClientMessage') {
    print "ClientMessage from window $h{'window'}\n";
    my $type = $h{'type'};
    printf "  type %d 0x%X  %s\n", $type, $type, $X->atom_name($type);
    if ($h{'type'} == $WM_PROTOCOLS) {
      my @values = unpack 'L', $h{'data'};
      ### @values
      foreach my $value (@values) {
        printf "  data %d 0x%X  %s\n", $value, $value, $X->atom_name($value);
      }
    } else {
    }
  }
};

for (;;) {
  $X->handle_input;
}
exit 0;
