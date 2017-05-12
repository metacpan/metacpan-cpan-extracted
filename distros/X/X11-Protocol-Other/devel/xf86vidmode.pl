#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use X11::Protocol;

# uncomment this to run the ### lines
use Smart::Comments;


use lib 'devel/lib';
$ENV{'DISPLAY'} ||= ':0';


{
  my $X = X11::Protocol->new;

  $X->init_extension('XFree86-VidModeExtension') or die $@;
  $X->QueryPointer($X->{'root'}); # sync
  ### init_extension() ok ...

  {
    my @version = $X->XF86VidModeQueryVersion;
    ### @version
  }
  {
    my @modeline = $X->XF86VidModeGetModeLine(0);
    ### @modeline
  }

  {
    my @monitor = $X->XF86VidModeGetMonitor(0);
    ### @monitor
    # my ($vendor, $model, $hsyncs, $vsyncs, $bandwidth) = @monitor;
    exit 0;
  }
  {
    my @modeline = $X->XF86VidModeGetAllModeLines(0);
    ### @modeline
  }

  $X->XF86VidModeSetClientVersion(2,2);
  {
    my @modeline = $X->XF86VidModeGetAllModeLines(0);
    ### @modeline
  }
  exit 0;
}
