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
use ExactImage;

use Smart::Comments;


# my $image = ExactImage::newImage();
my $image = ExactImage::newImageWithTypeAndSize(1,1,40,20);
{ my $class = ref $image;
  ### $class
}

ExactImage::imageResize($image,40,20);

print "Width: ", ExactImage::imageWidth($image), "\n";
print "Height: ", ExactImage::imageHeight($image), "\n";
print "Xres: ", ExactImage::imageXres($image), "\n";
print "Yres: ", ExactImage::imageYres($image), "\n";
print "Channels: ", ExactImage::imageChannels ($image), "\n";
print "Channel depth: ", ExactImage::imageChannelDepth ($image). "\n";

ExactImage::setForegroundColor(0,0,0,1.0);
ExactImage::setBackgroundColor(1.0,1.0,1.0,1.0);
ExactImage::imageDrawRectangle($image, 0,0, 39,19);

ExactImage::setForegroundColor(1.0,1.0,1.0,1.0);
ExactImage::setBackgroundColor(0,0,0,1.0);
ExactImage::imageDrawLine($image, 2,2, 10,10);

{ my @get = ExactImage::get($image, 0,0);
  ### @get
}

{ my $str = ExactImage::encodeImage ($image, "jpeg", 80, "");
  ### $str
}
{ my $str = ExactImage::encodeImage ($image, "xpm");
  ### $str
}

if (! ExactImage::encodeImageFile ($image, "/tmp/x.xpm", 80, "")) {
  print "error writing ...\n";
}
system ("ls -l /tmp/x.xpm");
