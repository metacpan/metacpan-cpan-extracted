#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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



use lib 'devel/lib';
$ENV{'DISPLAY'} ||= ':0';



use strict;
use X11::Protocol;

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $X = X11::Protocol->new;

  $X->init_extension('TOG-CUP') or die $@;
  $X->QueryPointer($X->{'root'}); # sync

  {
    my @version = $X->CupQueryVersion (99,99);
    ### @version
  }
  foreach (1 .. 80) { $X->QueryPointer($X->{'root'}); }

  {
    my @colors = $X->CupGetReservedColormapEntries (0);
    ### seq: $X->{'sequence_num'}
    ### @colors
    $X->QueryPointer($X->{'root'}); # sync
  }

  my $visual = 0x20; # $X->root_visual;
  my $rootwin = $X->root;
  ### $visual
  ### $rootwin

  my $colormap = $X->new_rsrc;
  $X->CreateColormap ($colormap, $visual, $rootwin, "None");
  $X->QueryPointer($X->{'root'}); # sync

  {
    my @colors = $X->CupStoreColors ($colormap, 0, 1, 2, 3, 4);
    ### @colors
  }
  exit 0;
}

{
  require Data::HexDump::XXD;
  print scalar(Data::HexDump::XXD::xxd("z" x 17));
  exit 0;
}
