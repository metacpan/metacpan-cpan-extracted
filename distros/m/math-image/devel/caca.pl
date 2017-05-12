#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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



# file:///usr/share/doc/libcaca-dev/html/group__caca__primitives.html


use 5.004;
use strict;
use warnings;
use Term::Caca;

# lib/Image/Base/Caca.pm
use Image::Base::Caca;


my $size = $ARGV[0] || 80;
my $c = Term::Caca->new ($size, $size);
# $c->draw_thin_ellipse (int($size/2),int($size/2),
#                        int($size/2),int($size/2));
$c->draw_ellipse (int($size/2),int($size/2),
                  int($size/2),int($size/2),
                  '*');
$c->refresh;
$c->get_event(0);
exit 0;
