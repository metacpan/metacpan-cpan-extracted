# Copyright 2011, 2012, 2013 Kevin Ryde

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


# pending Image::Xpm itself clipping to image size ...
#

package App::MathImage::Image::Base::XpmClipped;
use 5.004;
use strict;
use Carp;

use vars '$VERSION', '@ISA';
$VERSION = 110;

use Image::Xpm;
@ISA = ('Image::Xpm');

# uncomment this to run the ### lines
#use Smart::Comments;


sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### Xpm-Clipped xy(): "$x,$y"

  if ($x < 0 || $y < 0
      || $x >= $self->get('-width') || $y >= $self->get('-height')) {
    return undef;
  }
  return shift->SUPER::xy(@_);
}

1;
__END__
