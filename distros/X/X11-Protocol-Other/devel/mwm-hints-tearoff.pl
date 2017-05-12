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
use X11::AtomConstants;
use Carp;

# uncomment this to run the ### lines
use Smart::Comments;

# {
# 
# 
# 
#   #        # motif has the name "MWM_INPUT_APPLICATION_MODAL" as an alias for
#   #        # "MWM_INPUT_PRIMARY_APPLICATION_MODAL", but says prefer the latter
#   #        MwmModal => ['modeless',                  # 0
#   #                     'primary_application_modal', # 1
#   #                     'system_modal',              # 2
#   #                     'full_application_modal',    # 3
#   #                    ],
#   #        MwmStatus => ['tearoff_window',           # 0
#   #                    ],
# 
# 
# 
#   #
#   # The key/value arguments are
#   #
#   #     functions       arrayref, or integer bits
#   #     decorations     arrayref, or integer bits
#   #     input_mode      enum string or integer
#   #     status          arrayref, or integer bits
#   #
#   # C<functions> is what operations the window manager should offer on the
#   # window in a drop-down menu or similar.  The default is "all".
#   #
#   #     "all"         all functions
#   #     "resize"      to resize the window
#   #     "move"        to move the window
#   #     "minimize"    to iconify
#   #     "maximize"    to make full-screen (but still with a frame)
#   #     "close"       to close the window
#   #
#   # C<decorations> is what visual decorations the window manager should show
#   # around the window.  The default is "all".
#   #
#   #     "all"          show all decorations
#   #     "border"       a border around the window
#   #     "resizeh"      handles to resize by dragging
#   #     "title"        title bar showing WM_NAME
#   #     "menu"         drop-down menu of the "functions" above
#   #     "minimize"     button to minimize, ie. iconify
#   #     "maximize"     button to maximize, ie. full-screen
#   #
#   # C<input_mode> allows a window to be "modal", meaning the user should
#   # interact only with that window.  The window manager will generally keep
#   # it on top, not set the focus to other windows, etc.  The value is one of
#   # the following strings,
#   #
#   #     "modeless"                    0    not modal (the default)
#   #     "primary_application_modal"   1    modal to its "transient for"
#   #     "system_modal"                2    modal to the whole display
#   #     "full_application_modal"      3    modal to the current client
#   #
#   # C<status> field is an arrayref of some of the following strings, though
#   # currently there's just one,
#   #
#   #     "tearoff_window"     is a tearoff menu
#   #
#   # In Motif C<mwm>, C<tearoff_window> means the C<WM_NAME> in window's
#   # title bar is not truncated to the window size but instead the window
#   # expanded as necessary to show it in full.  This might be good for
#   # tearoff menus.  (Don't be surprised if other window managers ignore this
#   # flag though.)
#   #
#   #     X11::Protocol::WM::set_motif_wm_hints
#   #       ($X, $my_tearoff_win,
#   #        status => ['tearoff_window']);
#   #
#   # {
#   #   # /usr/include/Xm/MwmUtil.h
#   #
#   #   my $format = 'L5';
#   #   my %key_to_flag = (functions   => 1,
#   #                      decorations => 2,
#   #                      input_mode  => 4,
#   #                      status      => 8,
#   #                     );
#   #   my %arefargs = (functions => { all      => 1,
#   #                                  resize   => 2,
#   #                                  move     => 4,
#   #                                  minimize => 8,
#   #                                  maximize => 16,
#   #                                  close    => 32 },
#   #                   decorations => { all      => 1,
#   #                                    border   => 2,
#   #                                    resizeh  => 4,
#   #                                    title    => 8,
#   #                                    menu     => 16,
#   #                                    minimize => 32,
#   #                                    maximize => 64 },
#   #                   status => { tearoff_window => 1,
#   #                             },
#   #                  );
#   #   sub pack_motif_wm_hints {
#     #     my ($X, %hint) = @_;
#     #
#     #     my $flags = 0;
#     #     foreach my $key (keys %hint) {
#     #       if (defined $hint{$key}) {
#     #         $flags |= $key_to_flag{$key};
#     #       } else {
#     #         croak "Unrecognised MOTIF_WM_HINTS field: ",$key;
#     #       }
#     #     }
#     #     foreach my $field (keys %arefargs) {
#     #       my $bits = 0;
#     #       my $h;
#     #       if ($h = $hint{$field}) {
#     #         if (ref $h) {
#     #           foreach my $key (@$h) {
#     #             if (defined (my $bit = $arefargs{$field}->{$key})) {
#     #               $bits |= $bit;
#     #             } else {
#     #               croak "Unrecognised MOTIF_WM_HINTS ",$field," field: ",$key;
#     #             }
#     #           }
#     #         }
#     #       }
#     #       $hint{$field} = $bits;
#     #     }
#     #     pack ($format,
#     #           $flags,
#     #           $hint{'functions'},
#     #           $hint{'decorations'},
#     #           _motif_input_mode_num($hint{'input_mode'}) || 0,
#     #           $hint{'status'});
#     #   }
#     # }
# 
#   }


my $X = X11::Protocol->new;

my $w1 = $X->new_rsrc;
$X->CreateWindow ($w1,
                  $X->root,         # parent
                  'InputOutput',
                  0,                # depth, from parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  100,100,          # width,height
                  0,                # border
                  background_pixel => $X->black_pixel,
                 );
$X->ChangeProperty($w1,
                   X11::AtomConstants::WM_NAME,  # property
                   X11::AtomConstants::STRING,   # type
                   8,                            # byte format
                   'Replace',
                   'ssssssssssssssssss ssssssssssssssssssssss sssssssssssssssssss'); # window title
X11::Protocol::WM::set_motif_wm_hints ($X, $w1,
                                       functions => 4+32,
                                       decorations => 32);
$X->MapWindow ($w1);

my $w2 = $X->new_rsrc;
$X->CreateWindow ($w2,
                  $X->root,         # parent
                  'InputOutput',
                  0,                # depth, from parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  100,100,          # width,height
                  0,                # border
                  background_pixel => $X->black_pixel,
                 );
X11::Protocol::WM::set_motif_wm_hints ($X, $w2, status => 1);
$X->ChangeProperty($w2,
                   X11::AtomConstants::WM_NAME,  # property
                   X11::AtomConstants::STRING,   # type
                   8,                            # byte format
                   'Replace',
                   'jfksl jksd fjskl fjskl fjskl fjksl fjkls dlfjk slkf'); # window title
$X->MapWindow ($w2);

$X->flush;
sleep 2;
X11::Protocol::WM::set_motif_wm_hints ($X, $w1);
print "set again\n";

while (1) {
  $X->handle_input;
}
exit 0;




