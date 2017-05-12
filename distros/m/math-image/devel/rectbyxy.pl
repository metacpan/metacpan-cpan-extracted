#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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

# uncomment this to run the ### lines
#use Smart::Comments;

{
  require App::MathImage::RectByXY;
  my $r = App::MathImage::RectByXY->new (x_min => -5,
                                         x_max => -5,
                                         y_min => -5,
                                         y_max => -1);
  while (my ($x,$y) = $r->next) {
    print "x=$x, y=$y\n";
  }
}

{
  require App::MathImage::RectByXY;
  foreach my $x_min (-8, -5, -3, -2, -1,
                     0, 1, 2, 5, 8) {
    foreach my $x_max (-8, -5, -3, -2, -1,
                       0, 1, 2, 5, 8) {
      next unless $x_max >= $x_min;
      foreach my $y_min (-8, -5, -2, -1,
                         0, 1, 2, 5, 8) {
        foreach my $y_max (-8, -5, -3 -2, -1,
                           0, 1, 2, 3, 5, 8) {
          next unless $y_max >= $y_min;

          my $r = App::MathImage::RectByXY->new (x_min => $x_min,
                                                 x_max => $x_max,
                                                 y_min => $y_min,
                                                 y_max => $y_max);
          my %seen;
          while (my ($x,$y) = $r->next) {
            $seen{"$x,$y"}++;
          }
          foreach my $x ($x_min .. $x_max) {
            foreach my $y ($y_min .. $y_max) {
              if ((delete $seen{"$x,$y"}||0) != 1) {
                die "$x,$y not seen x=$x_min..$x_max y=$y_min..$y_max\n";
              }
            }
          }
          foreach my $key (sort keys %seen) {
            die "$key extra x=$x_min..$x_max y=$y_min..$y_max\n";
          }
        }
      }
    }
  }
  exit 0;
}
