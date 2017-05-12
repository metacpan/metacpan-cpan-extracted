# Copyright 2013, 2014 Kevin Ryde

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


# Maybe:
# KeyboardMapping->new(X=>$X)
# $km->handle_event($ev);
# MappingNotify update() re-read whole $X->GetKeyboardMapping()
# $km->event_to_keysym(\%ev)
# $X->keycode_min
# X11::Protocol::KeyboardMapping->event_to_keysym(\%ev)
#   single $X->GetKeyboardMapping of desired keycode

use 5.004;
use strict;
use Carp;
use X11::Protocol;

my $X = X11::Protocol->new;
my @keysym_arefs =  $X->GetKeyboardMapping
  ($X->{'min_keycode'},
   $X->{'max_keycode'} - $X->{'min_keycode'} + 1);

my $keycode = $X->{'min_keycode'};
my $aref = $keysym_arefs[0];
my $keysyms_per_keycode = scalar(@$aref);

$X->ChangeKeyboardMapping ($keycode, $keysyms_per_keycode, $aref);
$X->QueryPointer($X->{'root'}); # sync
exit 0;
