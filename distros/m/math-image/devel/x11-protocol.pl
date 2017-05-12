#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use X11::Protocol;
use App::MathImage::X11::Protocol::Splash;

use Smart::Comments;

{
  require Gtk2;
  Gtk2->init;
  require App::MathImage::Gtk2::Main;
  my $main = App::MathImage::Gtk2::Main->new;
  require App::MathImage::Gtk2::X11;
  my $x11 = App::MathImage::Gtk2::X11->new
    (gdk_window => $main->get_root_window,
     gen        => $main->{'draw'}->gen_object);
  Gtk2->main;
  exit 0;
}

{
  my $X = X11::Protocol->new;
  require App::MathImage::X11::Generator;
  x_resource_dump($X);

  my $x11gen = App::MathImage::X11::Generator->new
    (X => $X,
     window => $X->root);
  x_resource_dump($X);
  $x11gen->draw;

  x_resource_dump($X);
  exit 0;
}


{
  my $X = X11::Protocol->new;
  my $window = $X->new_rsrc;
  my $pixmap = $X->new_rsrc;
  ### $pixmap
  $X->CreatePixmap ($pixmap,
                    $X->{'root'}, # parent
                    1,
                    100,10);  # width, height
  x_resource_dump($X);
  $X->CreateWindow ($window,
                    $X->{'root'},     # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    0,0,              # x,y
                    1,1,              # width,height
                    0);               # border
  X11::Protocol::WM::set_wm_hints ($X, $window,
                                   input => 1,
                                   initial_state => 'IconicState',
                                   icon_pixmap => $pixmap,
                                  );
  { my @ret = App::MathImage::X11::Protocol::Splash::_get_wm_hints ($X, $window);
    ### @ret
  }
  $X->MapWindow ($window);
  $X->flush;
  sleep 1;
  my @ret = App::MathImage::X11::Protocol::Splash::_get_wm_state($X,$window);
  ### @ret
  exit 0;
}




use constant XA_PIXMAP => 20;  # pre-defined atom
{
  my $X = X11::Protocol->new;
  my $rootwin = $X->{'root'};
  my $atom = $X->InternAtom('_MATH_IMAGE_SETROOT_ID', 0);

  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($rootwin, $atom,
                       0,  # AnyPropertyType
                       0,  # offset
                       1,  # length
                       0); # delete;
  ### $value
  ### $type
  ### $format
  ### $bytes_after
  if ($type == XA_PIXMAP && $format == 32) {
    my $resource_pixmap = unpack 'L', $value;
    ### resource_pixmap: sprintf('%#X', $resource_pixmap)
    ### robust: $X->robust_req('KillClient',$resource_pixmap)
  }
  exit 0;
}
{
  my $X = X11::Protocol->new;
  my $rootwin = $X->{'root'};
  my $atom = $X->InternAtom('_MATH_IMAGE_SETROOT_ID', 0);

  my $resource_pixmap = $X->new_rsrc;
  ### resource_pixmap: sprintf('%#X', $resource_pixmap)
  $X->CreatePixmap ($resource_pixmap, $rootwin,
                    1,      # depth, bitmap
                    1, 1);  # width x height
  my $data = pack ('L', $resource_pixmap);

  $X->ChangeProperty($rootwin, $atom, XA_PIXMAP, 32, 'Replace', $data);
  $X->SetCloseDownMode('RetainPermanent');
  $X->QueryPointer($rootwin);  # sync
  undef $X; # close
  exit 0;
}









sub x_resource_dump {
  my ($X) = @_;
  $X->init_extension ('X-Resource');
  my $xid_base = $X->resource_id_base;

  printf "client 0x%X is using\n", $xid_base;

  my $ret = $X->robust_req('XResourceQueryClientResources', $xid_base);
  if (ref $ret) {
    my @resources = @$ret;
    while (@resources) {
      my $atom = shift @resources;
      my $count = shift @resources;
      my $atom_name = $X->atom_name($atom);
      printf "%6d  %s\n", $count, $atom_name;
    }
  } else {
    print "  error getting client resources\n";
  }

  $ret = $X->robust_req ('XResourceQueryClientPixmapBytes', $xid_base);
  if (ref $ret) {
    my ($bytes) = @$ret;
    printf "%6s  PixmapBytes\n", $bytes;
  } else {
    print "  error getting pixmap bytes\n";
  }

  print "\n";
}
