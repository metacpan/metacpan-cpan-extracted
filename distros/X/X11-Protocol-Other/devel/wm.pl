#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2018, 2019 Kevin Ryde

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
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # sample code in the POD

  my $display = $ENV{DISPLAY} || ':0';
  my $X = X11::Protocol->new ($display);
    my @net_supported = X11::Protocol::Other::get_property_atoms
                         ($X, $X->root, $X->atom('_NET_SUPPORTED'));
    if (grep {$_ == $X->atom('_NET_WM_STATE_FULLSCREEN')}
             @net_supported) {
      print "Have _NET_WM_STATE_FULLSCREEN\n";
    } else {
      print "Do not have _NET_WM_STATE_FULLSCREEN\n";
    }

  exit 0;
}
{
  # Maybe:
  my $display = $ENV{DISPLAY} || ':0';
  my $X = X11::Protocol->new ($display);

  system('xprop','-d',$display,'-root','_NET_SUPPORTED');

  my @supported = X11::Protocol::Other::get_property_atoms ($X, $X->root, $X->atom('_NET_SUPPORTED'));
  ### len: scalar(@supported)
  ### @supported
  foreach my $atom (@supported) {
    print $X->atom_name($atom),"\n";
  }

  @supported = X11::Protocol::Other::get_property_atoms ($X, $X->root, $X->atom('NOSUCH'));
  ### len: scalar(@supported)

  @supported = X11::Protocol::Other::get_property_atoms ($X, 0xa0001b, $X->atom('_NET_SUPPORTED'));
  ### len: scalar(@supported)

  exit 0;
}
{
  # urgency hint
  # cf fvwm hints_test.c program for making a window with some hints

  my $X = X11::Protocol->new (':0');
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
  $X->QueryPointer($X->root); # sync
  sleep 1;
  X11::Protocol::WM::set_wm_hints ($X, $window,
                                   # input => 1,
                                   urgency => 1);
  $X->QueryPointer($X->root); # sync
  sleep 30;
  print "urgency\n";
  X11::Protocol::WM::change_wm_hints ($X, $window, urgency => 1);
  # $X->QueryPointer($X->root); # sync
  $X->flush;
  sleep 30;

  # my %hints = X11::Protocol::WM::get_wm_hints($X,$window);
  # ### %hints

  exit 0;
}

{
  my $X = X11::Protocol->new ($ENV{DISPLAY} || ':0');
  $X->MapWindow($ARGV[0] || $ENV{WINDOWID});
  $X->QueryPointer($X->root); # sync
  exit 0;
}

{
  # apply _NET_WM_STATE change
  my $X = X11::Protocol->new (':0');

  {
    my ($value, $type, $format, $bytes_after)
      = $X->GetProperty ($X->root, $X->atom('_NET_SUPPORTED'),
                         0,    # AnyPropertyType
                         0,    # offset
                         999,  # length
                         0);   # delete;
    foreach my $atom (unpack('L*', $value)) {
      my $atom_name = $X->atom_name($atom);
      if ($atom_name =~ /STATE/) {
        print "$atom_name\n";
      }
    }
  }

  my $window = $ARGV[0] || do {
    print "click to choose window\n";
    require X11::Protocol::ChooseWindow;
    X11::Protocol::ChooseWindow->choose(X=>$X)
    };
  X11::Protocol::WM::change_net_wm_state
      ($X,$window,'toggle',
       # '_NET_WM_STATE_MAXIMIZED_SKIP_TASKBAR',
        '_NET_WM_STATE_MAXIMIZED_VERT',
       # state2 => '_NET_WM_STATE_MAXIMIZED_HORZ',
      );
  # '_NET_WM_STATE_FULLSCREEN',
  $X->flush;
  sleep 1;
  { my @states = X11::Protocol::WM::get_net_wm_state($X,$window);
    ### @states
  }
  { my @atoms = X11::Protocol::WM::get_net_wm_state_atoms($X,$window);
    ### @atoms
  }
  system ("xprop -id $window | grep STATE");
  exit 0;
}
{
  # default WM_HINTS

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
  $X->QueryPointer($X->root); # sync
  sleep 100;
  exit 0;
}

{
  # withdraw()

  my $X = X11::Protocol->new;

  my $event = $X->pack_event (name           => 'UnmapNotify',
                              event          => $X->root,
                              window         => $X->root,
                              from_configure => 0);
  ### $event

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
  $X->QueryPointer($X->root); # sync
  sleep 1;
  print "iconify\n";
  X11::Protocol::WM::iconify($X,$window);
  $X->QueryPointer($X->root); # sync
  sleep 1;
  print "withdraw\n";
  X11::Protocol::WM::withdraw($X,$window);
  $X->QueryPointer($X->root); # sync
  sleep 1;

  exit 0;
}

{
  # _NET_VIRTUAL_ROOTS

  my $X = X11::Protocol->new;
  my $atom = $X->atom('_NET_VIRTUAL_ROOTS');
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($X->root, $atom,
                       0,    # AnyPropertyType
                       0,    # offset
                       999,  # length
                       0);   # delete;
  ### $value, $type, $format, $bytes_after)
  ### $value
  ### $type
  ### $format
  ### $bytes_after
  exit 0;
}

{
  # WM_CHANGE_STATE exists
  my $X = X11::Protocol->new;
  my $atom = $X->InternAtom("WM_CHANGE_STATE",1);
  ### $atom
  exit 0;
}


{
  # get_net_frame_extents()

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
  $X->flush;
  sleep 1;
  my @extents = X11::Protocol::WM::get_net_frame_extents ($X, $window);
  ### @extents
  exit 0;
}

{
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
  X11::Protocol::WM::set_wm_name ($X, $window, "\x{2202}");
  # require Encode;
  # $x->changeproperty($window,
  #                    $X->atom('_NET_WM_NAME'),
  #                    $X->atom('UTF8_STRING'),   # type
  #                    8,                         # byte format
  #                    'Replace',
  #                    Encode::encode_utf8("\x{2202}"));
  $X->MapWindow ($window);

  for (;;) { $X->handle_input }
  exit 0;
}

{
  require Gtk2;
  Gtk2->init;
  my $toplevel = Gtk2::Window->new;
  $toplevel->set_title ("\x{2202}");
  $toplevel->show;
  $toplevel->get_display->flush;

  my $X = X11::Protocol->new;
  my $root = $X->{'root'};
  my ($root_root, $root_parent, @toplevels) = $X->QueryTree($root);
  ### $root_root
  ### $root_parent
  foreach my $window ($toplevel->window->XID,
                      # @toplevels
                     ) {
    ### window: sprintf '%X', $window

    if (1) {
      my @atoms = $X->ListProperties ($window);
      foreach my $atom (@atoms) {
        my ($value, $type, $format, $bytes_after)
          = $X->GetProperty ($window,
                             $atom,
                             0,  # AnyPropertyType
                             0,  # offset
                             0x7FFF_FFFF,  # length
                             0); # delete
        if (length($value)) {
          ### atom: $X->atom_name($atom)
          ### window: sprintf '%X', $window
          ### $value
          ### $type
          ### type: $type && $X->atom_name($type)
          ### $format
          ### $bytes_after
          # my @atoms = unpack 'L*', $value;
          # foreach my $atom (@atoms) {
          #   ### atom: $X->atom_name($atom)
          # }

          if ($type == $X->atom('ATOM')) {
            foreach my $at (unpack 'L*', $value) {
              ### atom: $X->atom_name($at)
            }
          }
        }
      }
    }

    if (0) {
      my ($value, $type, $format, $bytes_after)
        = $X->GetProperty ($window,
                           $X->atom('WM_PROTOCOLS'),
                           0,  # AnyPropertyType
                           0,  # offset
                           1,  # length
                           0); # delete
      ### $value
      ### $type
      ### type: $type && $X->atom_name($type)
      ### $format
      ### $bytes_after
      my @atoms = unpack 'L*', $value;
      foreach my $atom (@atoms) {
        ### atom: $X->atom_name($atom)
      }
    }
    if (0) {
      my ($value, $type, $format, $bytes_after)
        = $X->GetProperty ($window,
                           $X->atom('WM_HINTS'),
                           0,  # AnyPropertyType
                           0,  # offset
                           1,  # length
                           0); # delete
      if (length($value)) {
        ### WM_HINTS
        ### window: sprintf '%X', $window
        ### $value
        ### $type
        ### type: $type && $X->atom_name($type)
        ### $format
        ### $bytes_after
        # my @atoms = unpack 'L*', $value;
        # foreach my $atom (@atoms) {
        #   ### atom: $X->atom_name($atom)
        # }
      }
    }

    if (0) {
      my ($value, $type, $format, $bytes_after)
        = $X->GetProperty ($window,
                           $X->atom('WM_NORMAL_HINTS'),
                           0,  # AnyPropertyType
                           0,  # offset
                           1,  # length
                           0); # delete
      if (length($value)) {
        ### WM_NORMAL_HINTS
        ### window: sprintf '%X', $window
        ### $value
        ### value length: length($value)
        ### $type
        ### type: $type && $X->atom_name($type)
        ### $format
        ### $bytes_after
        # my @atoms = unpack 'L*', $value;
        # foreach my $atom (@atoms) {
        #   ### atom: $X->atom_name($atom)
        # }
      }
    }
  }

  # ### nosuch: $X->atom_name(73281947)
  exit 0;
}


