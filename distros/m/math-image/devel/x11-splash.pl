#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;

use X11::Protocol;
use App::MathImage::X11::Protocol::Splash;


# uncomment this to run the ### lines
use Smart::Comments;

{
  my $X = X11::Protocol->new;
  {
    my $e = $X->num('EventMask','Exposure');
    ### $e
  }
  my $pixmap = $X->new_rsrc;
  ### $pixmap
  $X->CreatePixmap ($pixmap,
                    $X->{'root'}, # parent
                    $X->{'root_depth'},
                    100,20);  # width, height
  my $gc = $X->new_rsrc;
  $X->CreateGC ($gc, $pixmap, foreground => 0xAAAAAA); # $X->{'white_pixel'}); #
  $X->PolyFillRectangle ($pixmap, $gc, [0,0,100,20]);

  my $splash = App::MathImage::X11::Protocol::Splash->new
    (X      => $X,
     pixmap => $pixmap,
     # pixmap => 'ParentRelative',
     width => 100,
     height => 20,
    );
  $splash->popup;
  my %attrs = $X->GetWindowAttributes ($splash->{'window'});
  ### %attrs
  printf "your_event_mask 0x%X: ", $attrs{'your_event_mask'};
  foreach (my $bit = 31; $bit; $bit--) {
    if ((1<<$bit) & $attrs{'your_event_mask'}) {
      print ",",$X->interp('EventMask',$bit);
    }
  }
  print " ", join($X->unpack_event_mask($attrs{'your_event_mask'})),"\n";
  printf "all_event_masks 0x%X: ", $attrs{'all_event_masks'};
  foreach (my $bit = 31; $bit; $bit--) {
    if ((1<<$bit) & $attrs{'all_event_masks'}) {
      print ",",($X->interp('EventMask',$bit)||$bit);
    }
  }
  print " ", join($X->unpack_event_mask($attrs{'all_event_masks'})),"\n";
  system "xwininfo -events -id $splash->{'window'}";
  sleep 1;

  my $pixmap2 = $X->new_rsrc;
  $X->CreatePixmap ($pixmap2,
                    $X->{'root'}, # parent
                    $X->{'root_depth'},
                    20,100);  # width, height
  my $gc2 = $X->new_rsrc;
  $X->CreateGC ($gc2, $pixmap, foreground => $X->{'black_pixel'});
  $X->PolyFillRectangle ($pixmap2, $gc2, [0,0,100,20]);
  my $splash2;
  if (1) {
    $splash2 = App::MathImage::X11::Protocol::Splash->new
      (X      => $X,
       pixmap => $pixmap2);
    $splash2->popup;
  }
  my $window2;
  if (0) {
    $window2 = $X->new_rsrc;
    $X->CreateWindow ($window2,
                      $X->root,     # parent
                      # $splash->{'window'},     # parent
                      'InputOutput',    # class
                      0,                # depth, from parent
                      'CopyFromParent', # visual
                      5,5,
                      300,10,
                      0,                # border
                      # background_pixmap => $pixmap2,
                      background_pixel  => 0x00FFFF,
                      override_redirect => 1,
                      # save_under        => 1,
                      # backing_store     => 'Always',
                      # bit_gravity       => 'Static',
                      event_mask        =>
                      $X->pack_event_mask(# 'Exposure',
                                          'ColormapChange',
                                          'VisibilityChange',));
    $X->MapWindow($window2);
    $X->flush;
  }

  {
    require Time::HiRes;
    my $t = Time::HiRes::time();
    while (Time::HiRes::time() - $t < 1) {
      if (fh_readable ($X->{'connection'}->fh)) {
        $X->handle_input;
      }
    }
  }

  $splash2->popdown;
  # $X->UnmapWindow($window2);
  $X->flush;

  {
    require Time::HiRes;
    my $t = Time::HiRes::time();
    while (Time::HiRes::time() - $t < 3) {
      if (fh_readable ($X->{'connection'}->fh)) {
        $X->handle_input;
      }
    }
  }
  exit 0;
}

{
  use FindBin;
  my $program = File::Spec->catfile ($FindBin::Bin, $FindBin::Script);
  ### $0
  ### $program
  ### @ARGV

  my $X = X11::Protocol->new;
  my $root = $X->{'root'};

  ### maximum_request_length: $X->{'maximum_request_length'}
  my $str = 'A' x (16384*1000);
  X11::Protocol::WM::set_text_property
      ($X, $root, $X->atom('MY_FOO'), $str);

  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($root,
                       $X->atom('MY_FOO'),
                       'AnyPropertyType',
                       0,  # offset
                       length($str),  # length
                       0); # delete;
  ### value length: length($value)
  ### $type
  ### $format
  ### $bytes_after
  exit 0;
}

{
  require App::MathImage::X11::Protocol::Splash;
  my $X = X11::Protocol->new;
  my $rootwin = $X->{'root'};
  my $pixmap = $X->new_rsrc;
  $X->CreatePixmap ($pixmap,
                    $rootwin, # parent
                    $X->{'root_depth'},
                    800, 100);  # width, height
  ### sync: $X->QueryPointer($X->{'root'})

  my $splash = App::MathImage::X11::Protocol::Splash->new (X => $X,
                                                           pixmap => $pixmap);
  $splash->popup;
  $X->QueryPointer($rootwin);  # sync

  system "xwininfo -events -id $splash->{'window'}";

  #  $X->flush;
  sleep 10;
  $splash->popdown;
  exit 0;
}

sub fh_readable {
  my ($fh) = @_;
  require IO::Select;
  my $s = IO::Select->new;
  $s->add($fh);
  my @ready = $s->can_read(1);
  return scalar(@ready);
}
