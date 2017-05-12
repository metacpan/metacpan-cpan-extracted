#!/usr/bin/perl -w

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

use 5.010;
use strict;
use warnings;

use Smart::Comments;


require 'devel/lib/Image/Base/ExactImage.pm';

my $image = Image::Base::ExactImage->new(-width => 40,
                                         -height => 20,
                                         -file_format => 'png');
### $image
{ my $width = $image->get('-width');
  ### $width
}
{ my $height = $image->get('-height');
  ### $height
}
# ExactImage::setForegroundColor(0,0,0,1.0);
# ExactImage::setBackgroundColor(1.0,1.0,1.0,1.0);
# $image->rectangle (tImage::imageDrawRectangle($image, 0,0, 39,19);

$image->line(2,2, 10,10, '#FFFFFF');
$image->rectangle(5,5, 15,15, '#FFFFFF');
$image->ellipse(20,5, 25,10, '#FFFFFF');

$image->save('/tmp/x.png');
system ("ls -l /tmp/x.png; convert /tmp/x.png /tmp/x.xpm; cat /tmp/x.xpm");
