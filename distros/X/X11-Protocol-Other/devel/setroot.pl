#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use X11::Protocol;
use X11::AtomConstants;

use Smart::Comments;


{
  require X11::Protocol::XSetRoot;
  {
    X11::Protocol::XSetRoot->set_background
        (
         # root => 0xC00003,
          color => '#F0FF00FFF0FF',
         # color => sprintf('#%06X', rand(0x1000000)),
         # pixel => 0xFFFFFF,
         # pixel => 0xFF0000,
         # allocated_pixels => 1,
         # pixmap => 0,
         use_esetroot => 1,
        );
    # now don't use $X11_protocol_object connection any more
  }
  {
    my $X = X11::Protocol->new;
    my %attr = $X->GetWindowAttributes($X->root);
    ### %attr
  }
  exit 0;
}
{
  require X11::Protocol::XSetRoot;
  {
    my $X = X11::Protocol->new;

    # my $colormap = $X->{'default_colormap'};
    # my @ret = $X->AllocNamedColor($colormap, 'white');
    # ### @ret

    my $width = 100;
    my $height = 100;
    my $pixmap = $X->new_rsrc;
    $X->CreatePixmap ($pixmap,
                      $X->{'root'},
                      $X->{'root_depth'},
                      $width,$height);
    ### pixmap: sprintf '%#X', $pixmap
    my $white_pixel = $X->{'white_pixel'};
    my $black_pixel = $X->{'black_pixel'};
    ### $white_pixel;
    ### $black_pixel
    my $gc = $X->new_rsrc;
    $X->CreateGC ($gc, $pixmap, foreground => $white_pixel);
    $X->PolyFillRectangle ($pixmap, $gc, [0,0, $width,$height]);
    $X->ChangeGC($gc, foreground => $black_pixel);
    my $width_half = int($width *.3);
    my $height_half = int($height *.3);
    $X->PolyFillRectangle ($pixmap, $gc, [0,0, $width_half,$height_half]);
    $X->PolyFillRectangle ($pixmap, $gc,
                           [$width_half,$height_half,
                            $width-$width_half,$height-$height_half]);
    $X->FreeGC($gc);
    X11::Protocol::XSetRoot->set_background
        (X      => $X,
         pixmap => $pixmap,
         use_esetroot => 1);
  }
  {
    my $X = X11::Protocol->new;
    my ($value, $type, $format, $bytes_after)
      = $X->GetProperty($X->root,
                        $X->atom('_XROOTPMAP_ID'),
                        0,  # AnyPropertyType
                        0,  # offset
                        1,  # length
                        0); # delete
    if ($type == X11::AtomConstants::PIXMAP() && $format == 32) {
      my $pixmap = unpack 'L', $value;
      ### _XROOTPMAP_ID: sprintf '%#X', $pixmap
      my %geom = $X->GetGeometry($pixmap);
      ### %geom
    }
  }
  exit 0;
}
{
  # SetCloseDownMode while server grabbed
  require X11::Protocol::WM;
  my $X = X11::Protocol->new (':1');
  $X->GrabServer;
  my $pixmap = $X->new_rsrc;
  $X->CreatePixmap ($pixmap,
                    $X->root,
                    $X->root_depth,
                    4,4);  # width,height
  printf "pixmap %X\n", $pixmap;
  $X->SetCloseDownMode('RetainPermanent');
  $X->flush;
  exit 0;
}

{
  require X11::Protocol::WM;
  my $X = X11::Protocol->new;
  my $root = $X->root;
  ### $root
  my $vroot = X11::Protocol::WM::root_to_virtual_root($X,$root);
  ### $vroot
  exit 0;
}

{
  my $X = X11::Protocol->new;
  $X->FreePixmap(0);
  ### sync: $X->QueryPointer($X->{'root'})
  exit 0;
}


{
  my $X = X11::Protocol->new;
  my $rootwin = $X->{'root'};
  my $atom = $X->atom('_SETROOT_ID');

  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($rootwin, $atom,
                       0,  # AnyPropertyType
                       0,  # offset
                       1,  # length
                       0); # delete;
  ### GetProperty: $X->atom_name($atom)
  ### $value
  ### $type
  ### $format
  ### $bytes_after
  if ($type == X11::AtomConstants::PIXMAP && $format == 32) {
    my $resource_pixmap = unpack 'L', $value;
    ### resource_pixmap: sprintf('%#X', $resource_pixmap)
    ### robust: $X->robust_req('KillClient',$resource_pixmap)
  }
  exit 0;
}



# Esetroot.c
#   get _XROOTPMAP_ID
#   get ESETROOT_PMAP_ID
#   if equal then KillClient
#
#   set _XROOTPMAP_ID
#   set ESETROOT_PMAP_ID
#   XSetCloseDownMode
#
#

# ENHANCE-ME: Don't intern atoms if they doesn't already exist.
sub _kill_current_esetroot {
  my ($class, $X, $root) = @_;
  ### XSetRoot kill_current()
  $root ||= $X->{'root'};

}

  # {
  #   my ($value, $type, $format, $bytes_after)
  #     = $X->GetProperty($root,
  #                       $X->atom('_XROOTPMAP_ID'),
  #                       0,  # AnyPropertyType
  #                       0,  # offset
  #                       1,  # length
  #                       1); # delete
  #   if ($type == X11::AtomConstants::PIXMAP() && $format == 32) {
  #     my $pixmap = unpack 'L', $value;
  #     unless ($pixmap) { # watch out for $xid==0 for none maybe
  #       return;
  #     }
  #   }
  # }

