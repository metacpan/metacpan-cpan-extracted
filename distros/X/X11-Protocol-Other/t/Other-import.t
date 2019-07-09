#!/usr/bin/perl -w

# Copyright 2011, 2019 Kevin Ryde

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

use X11::Protocol::Other qw(root_to_screen
                            root_to_screen_info
                            default_colormap_to_screen
                            default_colormap_to_screen_info
                            visual_is_dynamic
                            visual_class_is_dynamic
                            window_size
                            window_visual
                            get_property_atoms
                            hexstr_to_rgb
                          );

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

root_to_screen($X,$X->{'root'});
root_to_screen_info($X,$X->{'root'});

default_colormap_to_screen($X,$X->{'default_colormap'});
default_colormap_to_screen_info($X,$X->{'default_colormap'});

visual_class_is_dynamic($X,'PseudoColor');
my $visual_id = (keys %{$X->{'visuals'}})[0];
visual_is_dynamic($X,$visual_id);

window_size($X,$X->{'root'});
window_visual($X,$X->{'root'});
get_property_atoms($X,$X->{'root'},$X->atom('WM_PROTOCOLS'));

my @rgb = hexstr_to_rgb('#FAB');
ok ($rgb[0],0xFFFF);
ok ($rgb[1],0xAAAA);
ok ($rgb[2],0xBBBB);

$X->QueryPointer($X->{'root'});  # sync
ok (1, 1);

exit 0;
