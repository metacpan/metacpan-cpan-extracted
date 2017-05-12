# Copyright 2012, 2013 Kevin Ryde

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

package App::MathImage::RectByXY;
use 5.004;
use strict;
use Carp;
use List::Util 'min', 'max';

use vars '$VERSION';
$VERSION = 110;

# uncomment this to run the ### lines
#use Smart::Comments;


# |
# |--------+
# | \   \  |
# |  \   \ |
# |\  \   \|
# | \  \   |
# |  \  \  |\
# +-------------
#

sub new {
  my $class = shift;
  my $self = bless { quad => 1,
                     @_ }, $class;

  my $x_min = $self->{'x_min'};
  my $x_max = $self->{'x_max'};
  my $y_min = $self->{'y_min'};
  my $y_max = $self->{'y_max'};
  $self->{'d_max'} = max ($x_max + $y_max,
                          - $x_min + $y_max,
                          - $x_min - $y_min,
                          $x_max - $y_min);

  my $d = $self->{'d'}
    = ($x_min > 0 ? $x_min
       : $x_max < 0 ? -$x_max
       : 0)
      + ($y_min > 0 ? $y_min
         : $y_max < 0 ? -$y_max
         : 0);
  my $y = $self->{'y'} = max (-1,
                              $self->{'y_min'}-1,
                              $d - $x_max-1);
  $self->{'x'} = $d - $y;

  ### range: "x=$self->{'x_min'}..$self->{'x_max'}  y=$self->{'y_min'}..$self->{'y_max'}"
  ### d start: $self->{'d'}
  ### d_max: $self->{'d_max'}
  ### xy: "$self->{'x'},$self->{'y'}"

  return $self;
}

sub next {
  my ($self) = @_;
  my $quad = $self->{'quad'};
  my $x = $self->{'x'};
  my $y = $self->{'y'};

  for (;;) {
    if ($quad == 1) {
      # X,Y axes both
      $x--;
      $y++;
      ### quad 1 at: "$x,$y  d=$self->{'d'}"
      if ($x >= 0 && $x >= $self->{'x_min'} && $y <= $self->{'y_max'}) {
        last;
      }
      ### end of quad 1 ...

      $quad = $self->{'quad'} = 2;
      $x = min (0,
                $self->{'x_max'} + 1,
                $self->{'y_max'} - $self->{'d'} + 1);
      $y = $self->{'d'} + $x;
      ### start quad 2: "$x,$y"
    }

    if ($quad == 2) {
      # Ypos excluded, Xneg included
      $x--;
      $y--;
      ### quad 2 at: "$x,$y"
      if ($y >= 0 && $x >= $self->{'x_min'} && $y >= $self->{'y_min'}) {
        last;
      }
      ### end of quad 2 ...

      $quad = $self->{'quad'} = 3;
      $y = min (0,
                $self->{'y_max'} + 1,
                - $self->{'d'} - $self->{'x_min'} + 1);  # -(d-(-xmin))
      $x = - $self->{'d'} - $y;
      ### start quad 3: "$x,$y"
    }

    if ($quad == 3) {
      # Xneg excluded, Yneg axis excluded
      $x++;
      $y--;
      ### quad 3 at: "$x,$y  d=$self->{'d'}"
      if ($x < 0 && $x <= $self->{'x_max'} && $y >= $self->{'y_min'}) {
        last;
      }
      ### end of quad 3 ...

      $quad = $self->{'quad'} = 4;
      $x = max (-1,
                $self->{'x_min'} - 1,
                $self->{'d'} + $self->{'y_min'} - 1);  # d-(-ymin)
      $y = $x - $self->{'d'};
      ### start quad 4: "$x,$y"
    }

    if ($quad == 4) {
      # Yneg included, Xneg excluded
      $x++;
      $y++;
      ### quad 4 at: "$x,$y"
      if ($y < 0 && $x <= $self->{'x_max'} && $y <= $self->{'y_max'}) {
        last;
      }
      ### end of quad 4 ...

      $quad = $self->{'quad'} = 1;
      if (++$self->{'d'} > $self->{'d_max'}) {
        ### d past d_max, end ...
        return;
      }
      ### d now: $self->{'d'}

      $quad = $self->{'quad'} = 1;
      $y = max (-1,
                $self->{'y_min'}-1,
                $self->{'d'}-$self->{'x_max'}-1);
      $x = $self->{'d'} - $y;
      ### start quad 1: "$x,$y  d=$self->{'d'}"
    }
  }

  ### return: "$x,$y"
  return ($self->{'x'} = $x,
          $self->{'y'} = $y);
}
