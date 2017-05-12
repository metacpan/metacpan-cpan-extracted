#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2013 Kevin Ryde

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

use 5.008;
use strict;
use warnings;
use Test::More tests => 7;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::MathImage::Gtk2::Ex::GdkColorBits;

{
  my $want_version = 110;
  is ($App::MathImage::Gtk2::Ex::GdkColorBits::VERSION, $want_version,
      'VERSION variable');
  is (App::MathImage::Gtk2::Ex::GdkColorBits->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { App::MathImage::Gtk2::Ex::GdkColorBits->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { App::MathImage::Gtk2::Ex::GdkColorBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
MyTestHelpers::glib_gtk_versions();

#-----------------------------------------------------------------------------

foreach my $elem ([ 0x0000, 0x0080, 0x00FF, '#000000' ],
                  [ 0xFF00, 0xFF80, 0xFFFF, '#FFFFFF' ],
                  [ 0x1234, 0x5678, 0x9ABC, '#12569A' ],
                 ) {
  my ($red, $green, $blue, $want) = @$elem;
  my $color = Gtk2::Gdk::Color->new($red, $green, $blue);
  is (App::MathImage::Gtk2::Ex::GdkColorBits::to_HRRGGBB($color),
      $want,
      sprintf('to_HRRGGBB on %#X %#X %#X',$red,$green,$blue));
}

exit 0;
