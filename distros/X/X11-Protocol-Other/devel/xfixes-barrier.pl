#!/usr/bin/perl -w

# Copyright 2011, 2014, 2016 Kevin Ryde

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
  my $display = $ENV{'DISPLAY'} || ':0';
  my $X = X11::Protocol->new ($display);
  $X->{'event_handler'} = sub {
    my (%h) = @_;
    ### event_handler: \%h
  };

  { my @query_xinput = $X->QueryExtension('XInputExtension');
    ### @query_xinput
  }

  $X->init_extension('XFIXES') or die;
  $X->init_extension('XInputExtension') or die;

  # { my @xinput_version = $X->XInputExtensionGetExtensionVersion ("XInputExtension");
  #   ### @xinput_version
  # }

  # { my @xinput_selected = $X->XInputExtensionGetSelectedEvents ($X->root);
  #   ### @xinput_selected
  # }
  # { my @xinput_version = $X->XInputExtensionQueryVersion (99,99);
  #   ### @xinput_version
  # }
  # { my @xinput_query = $X->XInputExtensionQueryDevice (0);
  #   ### @xinput_query
  # }

  {
    print "XFixesCreatePointerBarrier()\n";
    my $barrier = $X->new_rsrc;
    $X->XFixesCreatePointerBarrier ($barrier, $X->root, 100,100, 400,100,
                                    0,
                                    # 'AllDevices',
                                    # 'AllMasterDevices',
                                    # 2,
                                   );
    $X->QueryPointer($X->root); # sync

    # print "XFixesDestroyPointerBarrier()\n";
    # $X->XFixesDestroyPointerBarrier ($barrier);

    $X->QueryPointer($X->root); # sync
  }

  # $X->QueryPointer($X->{'root'}); # sync
  sleep 100;

  exit 0;
}
