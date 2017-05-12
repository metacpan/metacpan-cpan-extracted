#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

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

use Smart::Comments;

{
  require X11::Protocol;
  my $X = X11::Protocol->new;
  my $visual_id = 0x41;
  ### vis: $X->{'visuals'}->{$visual_id}

  my $colormap = $X->new_rsrc;
  $X->CreateColormap ($colormap, $visual_id, $X->root, 'None');
  $X->QueryPointer($X->{'root'});  # sync

  my $depth = $X->{'visuals'}->{$visual_id}->{'depth'};
  # $depth = 24;
  ### $depth

  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $X->root,         # parent
                    'InputOutput',    # class
                    $depth,           # depth
                    $visual_id,       # visual ID
                    0,0,              # x,y
                    100,100,          # w,h initial size
                    0,                # border
                    colormap         => $colormap,
                    # background_pixel  => $X->white_pixel,
                    background_pixmap => 0,
                    border_pixmap     => 0,
                    # event_mask       => $X->pack_event_mask('Exposure'),
                   );
  $X->QueryPointer($X->{'root'});  # sync

  $X->MapWindow ($window);
  $X->QueryPointer($X->{'root'});  # sync

  for (;;) { $X->handle_input; }
  exit;
}

{
  #!/usr/bin/perl -w
  use strict;
  use X11::Protocol;

  # Return a list of three values ($red, $green, $blue) each 16-bits 0 to
  # 0xFFFF which is the colour at $root_x,$root_y on the given $root window.
  # $root must be a root window.  $root_x,$root_y must be within its
  # width,height.
  #
  # The pixel is read from the top-most window at $root_x,$root_y rather
  # than from the root.  This is since it's possible, at least in principle,
  # for a child window to have a different depth than its parent.  Using the
  # colormap from the window ensures the colour fetched is what the window
  # intends to display, even if the currently installed colormap is
  # something different.
  #
  sub rgb_at_root_xy {
    my ($X, $root, $root_x,$root_y) = @_;

    # It would be prudent to grab the server to prevent window changes
    # occurring while we fetch.  X11::Protocol::GrabServer would be one way
    # to do that.
    #    my $grab = X11::Protocol::GrabServer->new($X);

    # the window at $root_x,$root_y
    (undef, my $window)
      = $X->TranslateCoordinates($root, $root, $root_x,$root_y);
    if ($window eq 'None') {
      $window = $root;     # root window if nothing else at $x,$y
    }

    # window-relative coordinates
    my (undef, undef, $win_x,$win_y)
      = $X->TranslateCoordinates($root, $window, $root_x,$root_y);

    my ($depth, $visual, $pixel_bytes)
      = $X->GetImage($window, $win_x,$win_y, 1,1, 0xFFFF_FFFF, 'ZPixmap');

    # ensure $pixel_bytes is big-endian
    if ($X->interp('Significance', $X->{'image_byte_order'})
        eq 'LeastSignificant') {
      $pixel_bytes = reverse $pixel_bytes;
    }

    my $pixel = unpack 'N', $pixel_bytes;

    # mask out any bits above $depth
    $pixel &= (1 << $depth) - 1;

    # lookup $pixel in the window's colormap
    my %attrs = $X->GetWindowAttributes ($window);
    my ($rgb_aref) = $X->QueryColors ($attrs{'colormap'}, $pixel);
    return @$rgb_aref;
  }

  my $X = X11::Protocol->new;

  my %pointer = $X->QueryPointer($X->root);
  my $root = $pointer{'root'};     # root window containing mouse
  my $root_x = $pointer{'root_x'}; # X,Y location
  my $root_y = $pointer{'root_y'};
  print "pixel at $root_x,$root_y\n";

  my ($red, $green, $blue) = rgb_at_root_xy($X, $root, $root_x,$root_y);
  printf "RGB 4-digit hexadecimal #%04X%04X%04X\n", $red, $green, $blue;
  exit 0;
}

{
  # Xnest -scrns 2 :1
  $ENV{'DISPLAY'} ||= ":1.0";

  require IPC::Run;
  require File::Spec;
  IPC::Run::start(['Xnest',
                   '-scrns','2',
                   '-geometry','300x100+900+20',
                   # '-geometry','300x100+900+150',
                   ':1'],
                  '<', File::Spec->devnull);
  sleep 1;
  IPC::Run::start(['xclock',
                   '-display',':1.0'],
                  '<', File::Spec->devnull);

  IPC::Run::start(['xterm', '-display',':1.1', '-geometry','30x5'],
                  '<', File::Spec->devnull);

  require X11::Protocol;
  my $X = X11::Protocol->new (":1.1");
  print "vendor $X->{'vendor'}\n";

  printf "root    %X\n", $X->root;
  printf "root 0  %X\n", $X->screens->[0]->{'root'};
  printf "root 1  %X\n", $X->screens->[1]->{'root'};
  {
    my %pointer = $X->QueryPointer($X->root);
    printf "pointer root  %X\n", $pointer{'root'};
  }

  my $prev = '';
  for (;;) {
    sleep 1;
    my %pointer = $X->QueryPointer($X->root);
    my ($red, $green, $blue) = rgb_at_root_xy($X, $pointer{'root'},
                                              $pointer{'root_x'}, $pointer{'root_y'});
    my $str = sprintf "%d,%d is #%04X%04X%04X\n",
      $pointer{'root_x'}, $pointer{'root_y'}, $red, $green, $blue;
    if ($str ne $prev) {
      $prev = $str;
      print $str;
    }
  }
  exit 0;
}

# ### $colormap
# ### pixel: sprintf '%X', $pixel

use Time::HiRes 'usleep';
sleep 1;
goto MORE;
exit 0;

# uncomment this to run the ### lines
use Smart::Comments;

# mouse pointer location and top-most window
# (if fetching from an arbitrary X,Y rather than QueryPointer() then would
# do $X->TranslateCoordinates() to find the window at that X,Y)
#
# If getting the pixel at an arbitrary $x,$y then the window at $x,$y could
# be found with $X->TranslateCoordinates().
#   my ($same_screen, $window)
#     = $X->TranslateCoordinates($X->root, $X->root, $x,$y);

# my $visual_info = $X->{'visuals'}->{$visual_id}
#   || die "Oops, Unknown visual ID $visual_id";
# my $visual_class = $visual_info->{'class'};
# my $visual_class_is_dynamic = ($X->num('VisualClass',$visual_class) & 1);
#
# if ($visual_class_is_dynamic) {
#
# }
# return $pixel;
