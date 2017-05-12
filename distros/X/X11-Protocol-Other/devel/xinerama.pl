#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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

use strict;
use X11::Protocol;

use lib 'devel', '.';

# uncomment this to run the ### lines
use Smart::Comments;

$ENV{DISPLAY} = ":102";
{
  my $X = X11::Protocol->new ($ENV{DISPLAY} || ':0');
  ### root: $X->{'root'}

  { my @query = $X->QueryExtension('XINERAMA');
    ### @query
  }
  $X->QueryPointer($X->{'root'}); # sync

  $X->init_extension('XINERAMA') or die $@;
  $X->QueryPointer($X->{'root'}); # sync

  { my @version = $X->PanoramiXQueryVersion (99,99);
    ### PanoramiXQueryVersion: @version
  }
  $X->QueryPointer($X->{'root'}); # sync

  my @state = $X->PanoramiXGetState ($X->{'root'});
  ### PanoramiXGetState: @state
  $X->QueryPointer($X->{'root'}); # sync

  my @count = $X->PanoramiXGetScreenCount ($X->{'root'});
  ### PanoramiXGetScreenCount: @count
  $X->QueryPointer($X->{'root'}); # sync
  my ($count) = @count;

  {
    my @size = $X->PanoramiXGetScreenSize ($X->{'root'}, 999999);
    ### PanoramiXGetScreenSize: @size
  }
  foreach my $monitor (0 .. $count+5) {
    ### $monitor
    my @size = $X->PanoramiXGetScreenSize ($X->{'root'}, $monitor);
    ### PanoramiXGetScreenSize: @size
    $X->QueryPointer($X->{'root'}); # sync
  }


  my @active = $X->XineramaIsActive ();
  ### XineramaIsActive: @active
  $X->QueryPointer($X->{'root'}); # sync

  my @query = $X->XineramaQueryScreens ($X->{'root'});
  ### XineramaQueryScreens: @query
  $X->QueryPointer($X->{'root'}); # sync

  exit 0;
}
