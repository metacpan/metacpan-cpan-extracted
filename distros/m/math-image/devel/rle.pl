#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
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

{
  require App::MathImage::Image::Base::LifeBitmap;
  my $image = App::MathImage::Image::Base::LifeBitmap->new
    (-file  => '/usr/share/golly/Patterns/Life/Bounded-Grids/cross-surface.rle',
     # '/usr/share/golly/Patterns/Life/Guns/golly-ticker.rle'
    );
  $image->save_fh (\*STDOUT);

  $image->rectangle (0,0, 19,9, 'b', 1);
  $image->rectangle (2,2, 18,8, 'o', 0);
  
  $image->rectangle (0,3, 19,4, 'b', 1);
  
  $image->save_fh (\*STDOUT);
  
  $image->save ('/tmp/x.rle');
  $image->load ('/tmp/x.rle');
  ### rows_array: $image->{'-rows_array'}
  $image->save_fh (\*STDOUT);
  exit 0;
}

{
  require App::MathImage::Image::Base::LifeRLE;
  my $image = App::MathImage::Image::Base::LifeRLE->new
    (-width  => 20,
     -height => 10,
    );
  $image->rectangle (0,0, 19,9, 'b', 1);
  $image->rectangle (2,2, 18,8, 'o', 0);
  $image->rectangle (5,5, 5,5, '26', 0);

  $image->rectangle (0,3, 19,4, 'b', 1);

  $image->save_fh (\*STDOUT);

  $image->save ('/tmp/x.rle');
  $image->load ('/tmp/x.rle');
  ### rows_array: $image->{'-rows_array'}
  $image->save_fh (\*STDOUT);
  exit 0;
}

{
  open NOSUCH, '</dev/null';
  my $ret = print NOSUCH;
  ### $ret
  exit 0;
}
