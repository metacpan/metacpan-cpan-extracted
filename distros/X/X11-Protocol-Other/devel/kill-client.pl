#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use X11::Protocol;

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $X = X11::Protocol->new;
  my $X2 = X11::Protocol->new;
  my $pixmap2 = $X2->new_rsrc;
  $X2->CreatePixmap ($pixmap2,
                     $X2->{'root'},
                     $X2->{'root_depth'},
                     1,1);  # width,height
  { my @q2 = $X2->QueryPointer($X2->{'root'});  # sync
    ### @q2
  }
  $X->KillClient($pixmap2);
  { my @q = $X->QueryPointer($X->{'root'});  # sync
    ### @q
  }
  sleep 1;


  for (1 .. 1000) {
    eval { $X2->UngrabServer; };
    $X2->flush;
  }
  $X2->flush;


  # { my @q2 = $X2->QueryPointer($X2->{'root'});  # sync
  #   ### @q2
  # }

  exit 0;
}
