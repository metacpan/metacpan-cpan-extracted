#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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
use Tk;

use FindBin;
my $progname = $FindBin::Script;

{
  require App::MathImage::Tk::Perl::NumAxis;
  my $mw = MainWindow->new;
  my $axis = $mw->Component
    ('AppMathImageTkPerlNumAxis','axis',
     -height   => 300,
     -width    => 150,
     -borderwidth => 10,
     # -min_decimals => 2,
     -page_size => 100,
    );

  # my $axis = $mw->Axis(
  #
  #                 -margin   => 70,
  #                 -tick     => 50,
  #                 #-tickfont => $tickfont,
  #                 -tst      => 300,
  #                 -xmin     => 100,
  #                 -xmax     => 500,
  #                 -ymin     => 0,
  #                 -ymax     => 1000,
  #                );
  $axis->pack (-expand => 1,
               -fill => 'both');
  ### reqwidth: $axis->reqwidth
  MainLoop;
  exit 0;

}

{
  my $mw = MainWindow->new;
  require Tk::Axis;
  my $axis = $mw->Axis(-height   => 300,
                       -width    => 150,
                       -margin   => 70,
                       -tick     => 50,
                       #-tickfont => $tickfont,
                       -tst      => 300,
                       -xmin     => 100,
                       -xmax     => 500,
                       -ymin     => 0,
                       -ymax     => 1000,
                      );
  $axis->pack;
  MainLoop;
  exit 0;
}
