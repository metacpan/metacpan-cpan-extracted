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

use 5.006;
use strict;
use X11::Protocol;

# uncomment this to run the ### lines
use Smart::Comments;

use lib 'devel/lib';
$ENV{'DISPLAY'} ||= ':0';


{
  # version 2.0
  my $X = X11::Protocol->new;

  $X->init_extension('XFree86-DGA') or die $@;
  $X->QueryPointer($X->{'root'}); # sync
  ### init_extension() ok ...

  # {
  #   my @modes = $X->XDGAQueryModes(0);
  #   ### @modes
  # }
  {
    my @ret = $X->XDGAOpenFramebuffer(0);
    ### @ret
    printf "%X\n", $ret[1];
  }

 $X->XDGASelectInput(0, $);
    ### @ret
    printf "%X\n", $ret[1];
  }
  exit 0;
}
{
  my $X = X11::Protocol->new;

  $X->init_extension('XFree86-DGA') or die $@;
  $X->QueryPointer($X->{'root'}); # sync
  ### init_extension() ok ...

  my ($address, $width, $bank_size, $ram_size) = $X->XF86DGAGetVideoLL(0);

  my $mmap;
  require File::Map;
  File::Map::map_file($mmap, '/dev/mem', '+<', $address, 1024**2);

  {
    my $enable_flags = $X->XF86DGADirectVideo(0, 0b01110);
    ### enable flags: sprintf '%b', $enable_flags
  }

  my $size = 1440*50*4;
  substr($mmap,0,$size) = "\0"x$size;
  substr($mmap,$size,$size) = "\xFF"x$size;
  sleep 3;

  {
    my $disable_flags = $X->XF86DGADirectVideo(0, 0);
    ### disable flags: sprintf '%b', $disable_flags
  }

  exit 0;
}


{
  my $X = X11::Protocol->new;

  $X->init_extension('XFree86-DGA') or die $@;
  $X->QueryPointer($X->{'root'}); # sync
  ### init_extension() ok ...

  {
    my @version = $X->XF86DGAQueryVersion;
    ### @version
  }
  {
    # ($address, $width, $bank_size, $ram_size)
    my @LL = $X->XF86DGAGetVideoLL(0);
    ### @LL
    printf "%X %X %X %X\n", @LL;
  }
  {
    my @wh = $X->XF86DGAGetViewPortSize(0);
    ### @wh
  }
  # {
  #   $X->XF86DGASetViewPort(0, 200,100, 0);
  #   my @wh = $X->XF86DGAGetViewPortSize(0);
  #   ### @wh
  # }

  {
    my $vidpage = $X->XF86DGAGetVidPage(0);
    ### $vidpage
  }
  {
    $X->XF86DGASetVidPage(0, 0);
    $X->QueryPointer($X->{'root'}); # sync
    my $vidpage = $X->XF86DGAGetVidPage(0);
    ### $vidpage
  }
  {
    my $query_flags = $X->XF86DGAQueryDirectVideo(0);
    ### query flags: sprintf '%X', $query_flags
  }

  {
    my $disable_flags = $X->XF86DGADirectVideo(0, 1);
    ### disable flags: sprintf '%b', $disable_flags
  }

  {
    my $enable_flags = $X->XF86DGADirectVideo(0, 0b01110);
    ### enable flags: sprintf '%b', $enable_flags
  }
  { my $changed_result = $X->XF86DGAViewPortChanged(0, 1);
    ### $changed_result
  }
  { my $changed_result = $X->XF86DGAViewPortChanged(0, 1);
    ### $changed_result
  }
  {
    my $disable_flags = $X->XF86DGADirectVideo(0, 0);
    ### disable flags: sprintf '%b', $disable_flags
  }

  exit 0;
}
