#!/usr/bin/perl -w

# Copyright 2010, 2013 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Audio::WMA;

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $wma  = Audio::WMA->new('/tmp/x.wma');
  my $info = $wma->info();
  ### $info

  my $tags = $wma->tags();
  ### $tags
  exit 0;
}
