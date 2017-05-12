#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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
use List::Util 'min', 'max';

#use Devel::Comments;


# roygbiv
{
  my $w = 256*3;
  #   $w = 16;
  my $h = 100;
  require Convert::Color::HSV;
  require Graphics::Color::HSV;
  require App::MathImage::Generator;

  # require Image::Base::GD;
  # my $image = Image::Base::GD->new (-width => $w,
  #                                   -height => $h,
  #                                   -truecolor => 1);

  require Image::Base::PNGwriter;
  my $image = Image::Base::PNGwriter->new (-width => $w,
                                           -height => $h,
                                           -truecolor => 1);

  # require Image::Base::Gtk2::Gdk::Pixbuf;
  # my $image = Image::Base::Gtk2::Gdk::Pixbuf->new (-width => $w,
  #                                                  -height => $h);

  foreach my $x (0 .. $w-1) {
    my $hue = $x/$w;
    # my $hue = ($w-1 - $x)/$w;

    # $hue = int($hue * 7) / 7 + .5/7;  # quantize
    # my $colour = hsv($hue);
    my $colour = App::MathImage::Generator->colour_heat($hue);
    ### $hue
    ### $colour

    $image->add_colours ($colour);
    $image->line ($x,0, $x,$h-1, $colour);
  }
  $image->save('/tmp/x.png');
  system ('xzgv /tmp/x.png');
  exit 0;
}

sub hsv {
  my ($alpha) = @_;
  my $hsv = Graphics::Color::HSV->new ({ hue => $alpha*360,
                                         saturation => .9,
                                         value => 1, # $alpha/2,
                                       });
  my $rgb = $hsv->to_rgb;
  return $rgb->as_hex_string('#');
}

sub redblue {
  my ($alpha) = @_;
  return sprintf("#%02XCC%02x", $alpha * 51 + 204, (1 - $alpha) * 51 + 204);
}

sub grad {
  my ($alpha) = @_;

  # Color.WHITE, Color.RED, Color.YELLOW, Color.GREEN.darker(), Color.CYAN, Color.BLUE, new Color(0, 0, 0x33));
  #       white red  yel   dgreen cyan  blue  blackish
  my @r = (1.0, 1.0, 1.0,       0,   0,   0, 0);
  my @g = (1.0,   0, 1.0, 100/255, 1.0,   0, 0);
  my @b = (1.0,   0,   0,       0, 1.0, 1.0, 0x33/255);

  my $s = $alpha * 6.01;
  my $i = int($s);
  my $frac = $s - $i;
  my $r = $r[$i] * (1-$frac) + $r[$i+1] * $frac;
  my $g = $g[$i] * (1-$frac) + $g[$i+1] * $frac;
  my $b = $b[$i] * (1-$frac) + $b[$i+1] * $frac;
  $r *= 255;
  $g *= 255;
  $b *= 255;
  return sprintf ('#%02X%02X%02X', $r, $b, $g);
}

sub three {
  my ($alpha) = @_;
  $alpha *= 255;
  my $r = 0;
  my $g = 0;
  my $b = 0;
  ### $alpha
  if($alpha <= 255 && $alpha >= 235){
    my $tmp = 255-$alpha;
    $r=255-$tmp;
    $g=$tmp*12;
  } elsif($alpha <= 234 && $alpha >= 200){
    my $tmp = 234-$alpha;
    $r=255-($tmp*8);
    $g=255;
  } elsif($alpha <= 199 && $alpha >= 150){
    my $tmp = 199-$alpha;
    $g=255;
    $b=$tmp*5;
  } elsif($alpha <= 149 && $alpha >= 100){
    my $tmp = 149-$alpha;
    $g=255-($tmp*5);
    $b=255;
  } else {
    $b=255;
  }
  return sprintf ('#%02X%02X%02X', $r, $b, $g);
}


# black
# blue    = B
# green   = G
# cyan    = B+G
# red     = R
# orange  = R+G/2
# pink    = R+G
# yellow  = R+B
# white   = R+B+G
#
# ----------------------                   --------
#           -----------------------        --------
#                       ---------------------------
{
  my $w = 256*3;
  my $h = 100;
  require Image::Base::Gtk2::Gdk::Pixbuf;
  my $image = Image::Base::Gtk2::Gdk::Pixbuf->new (-width => $w,
                                                   -height => $h);
  my $gs = int ($w * 1/3);
  my $gw = $w - $gs;
  my $rs = int ($w * 2/3);
  my $rw = $w - $rs;
  foreach my $x (0 .. $w-1) {
    my $f = $x / ($w-1);

    my $b = 0;
    if ($f < 1/4) {
      $b = $f * 4;
    } elsif ($f < 1/2) {
      $b = (1/2-$f) * 4;
    } elsif ($f > 3/4) {
      $b = ($f-3/4) * 4;
    }
    my $blue = int (max (0, min (1, $b)) * 255);

    my $g = 0;
    if ($f > 1/4 && $f < 1/2) {
      $g = ($f-1/4) * 4;
    } elsif ($f > 1/2 && $f < 3/4) {
      $g = (3/4-$f) * 4;
    } elsif ($f > 3/4) {
      $g = ($f-3/4) * 4;
    }
    my $green = int (max (0, min (1, $g)) * 255);

    my $r = 0;
    if ($f > 1/2) {
      $r = ($f-1/2) * 2;
    }
    my $red = int (max (0, min (1, $r)) * 255);

    my $colour = sprintf '#%02X%02X%02X', $red, $blue, $green;
    say $colour;
    $colour = '#00FFFF';
    $image->line ($x,0, $x,$h-1, $colour);
  }
  $image->save('/tmp/x.png');
  system ('xzgv /tmp/x.png');
  exit 0;
}

{
  require Convert::Color::X11;
  @Convert::Color::X11::RGB_TXT = ('/tmp/rgb.txt');
  @Convert::Color::X11::RGB_TXT = ('/tmp/rgb.txt');
  print scalar(Convert::Color::X11->colors),"\n";
  my $c = Convert::Color::X11->new('redfdjks');
  ### $c
  exit 0;
}


