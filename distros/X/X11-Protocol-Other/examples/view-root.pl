#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2017 Kevin Ryde

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


# Usage: ./view-root.pl
#
# This is a slightly experimental idea to view the contents of the root
# window momentarily.  If you have rotating pictures on the root then this
# can show the current content.
#
# If there's a root pixmap recorded in _XROOTPMAP_ID in the manner of
# xsetroot (see X11::Protocol::XSetRoot) then this is shown in a full-screen
# window.
#
# If not, or if _XROOTPMAP_ID is invalid for some reason, then all windows
# are iconified to reveal the root.  This is probably not particularly good,
# but hope usually _XROOTPMAP_ID is available.
#

use strict;
use FindBin;
use X11::AtomConstants;
use X11::Protocol;
use X11::Protocol::Other;
use X11::Protocol::WM;

# uncomment this to run the ### lines
# use Smart::Comments;


my $view_seconds = 5;

my $X = X11::Protocol->new;
my $root = (X11::Protocol::WM::root_to_virtual_root($X,$X->root)
            || $X->root);
my $xrootpmap_id;
{
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($root, $X->atom('_XROOTPMAP_ID'),
                       X11::AtomConstants::PIXMAP(),    # type
                       0,    # offset
                       1,    # length
                       0);   # delete;
  if ($value) {
    $xrootpmap_id = unpack 'L', $value;
  }
}

if ($xrootpmap_id) {
  # by flashing the _XROOTPMAP_ID
  my ($width, $height) = X11::Protocol::Other::window_size ($X, $root);

  my $error;
  local $X->{'error_handler'} = sub {
    my ($X, $data) = @_;
    $error = 1;
  };
  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $root,            # parent
                    'InputOutput',    # class
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    0,0,              # x,y
                    $width,$height,
                    0,                # border
                    background_pixmap => $xrootpmap_id,
                    # background_pixel  => 0x00FFFF,
                    override_redirect => 1,
                    # save_under        => 1,
                    # backing_store     => 'Always',
                    # bit_gravity       => 'Static',
                    # event_mask        =>
                    # $X->pack_event_mask('Exposure',
                    #                     'ColormapChange',
                    #                     'VisibilityChange',),
                   );
  $X->QueryPointer($root); # sync
  if ($error) {
    undef $xrootpmap_id;
  } else {
    X11::Protocol::WM::set_wm_name ($X, $window, $FindBin::Script);
    X11::Protocol::WM::set_wm_hints
        ($X, $window, input => 0);
    X11::Protocol::WM::set_net_wm_window_type ($X, $window, 'SPLASH');
    $X->MapWindow ($window);
    $X->ClearArea ($window, 0,0,0,0);
    $X->flush;
    sleep $view_seconds;
    exit 0;
  }
}

if (! $xrootpmap_id) {
  # by iconifying everything temporarily

  my ($root, $root_parent, @toplevels) = $X->QueryTree($X->root);

  my ($focus_window, $focus_revert_to) = $X->GetInputFocus;

  my @remap;
  foreach my $frame (@toplevels) {
    my $window = X11::Protocol::WM::frame_window_to_client($X,$frame) || next;

    my ($state, $icon_window) = X11::Protocol::WM::get_wm_state($X,$window);
    if (($state||'') eq 'NormalState') {
      ### WM_NAME: $X->GetProperty($window, $X->atom('WM_NAME'), $X->atom('STRING'), 0, 999, 0)

      X11::Protocol::WM::iconify($X, $window, $root);
      push @remap, $window;
    }

    # my %attr = $X->GetWindowAttributes ($window);
    # if ($attr{'map_state'} eq 'Viewable') {
    #   $X->UnmapWindow ($window);
    #   push @remap, $window;
    # }
  }

  $X->flush;
  $X->QueryPointer($root); # sync
  sleep $view_seconds;

  ### @remap
  foreach my $window (@remap) {
    $X->MapWindow ($window);
  }
  $X->flush;
  $X->QueryPointer($root); # sync

  # nasty hack to try to wait for the window manager to be ready to go to
  # the original focused window
  sleep 1;
  $X->SetInputFocus($focus_window, $focus_revert_to, 0);

  $X->QueryPointer($root); # sync
}

exit 0;
