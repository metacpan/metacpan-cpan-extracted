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

use strict;
use X11::Protocol;

use lib 'devel/lib';

# uncomment this to run the ### lines
use Smart::Comments;


{
  my $X = X11::Protocol->new ($ENV{'DISPLAY'} || ':0');
  $X->init_extension('RANDR') or die;
  { my @version = $X->RRQueryVersion (1,0);
    ### @version
  }

  { my @size_ranges = $X->RRGetScreenSizeRange($X->root);
    ### @size_ranges
  }

  my %info;
  { my @info = $X->RRGetScreenInfo($X->root);
    ### @info
    %info = @info;
  }
  $X->QueryPointer($X->{'root'}); # sync

  {
    ###  time: $info{'time'},
    ###  config_time: $info{'config_time'},
    ###  size: $info{'size'},
    ###  rotation: $info{'rotation'},
    ###  rate: $info{'rate'},
    my @result = $X->RRSetScreenConfig($X->root,
                                       $info{'time'},
                                       $info{'config_time'},
                                       $info{'size'},
                                       4,
                                       $info{'rate'},
                                      );
    ### @result
  }
  sleep 2;
  {
    my @result = $X->RRSetScreenConfig($X->root,
                                       $info{'time'},
                                       $info{'config_time'},
                                       $info{'size'},
                                       $info{'rotation'},
                                       $info{'rate'},
                                      );
    ### @result
  }

  exit 0;
}
