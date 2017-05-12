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

use lib 'devel', '.';

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $X = X11::Protocol->new (':0');
  $X->init_extension('Composite') or die $@;

  my $rootwin = $X->root;

  my $pixmap = $X->new_rsrc;
  $X->CreatePixmap ($pixmap,
                    $rootwin,
                    $X->root_depth,
                    100,100);

  my $gc = $X->new_rsrc;
  $X->CreateGC ($gc, $rootwin); # , subwindow_mode => 'IncludeInferiors');

  my $owin = $X->new_rsrc;
  $X->CreateWindow ($owin,
                    $X->root,         # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    0,0,              # x,y
                    100,100,          # width,height
                    0,                # border
                    override_redirect => 1,
                   );
  $X->ConfigureWindow ($owin,
                       stack_mode => 'Above');
  $X->MapWindow ($owin);
  $X->CompositeRedirectWindow ($owin, 'Automatic');

  $X->CopyArea ($owin, $pixmap, $gc,
                0,0,  # src x,y
                100,100,
                0,0); # dst x,y

  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $X->root,         # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    0,0,              # x,y
                    100,100,          # width,height
                    0,                # border
                    background_pixmap => $pixmap,
                   );
  $X->MapWindow ($window);
  $X->flush;
  sleep 99;

#  system "xwd -id $pixmap >/tmp/x.xwd && xzgv /tmp/x.xwd";
  exit 0;
}


# {
#   my $X = X11::Protocol->new (':0');
#   $X->init_extension('Composite') or die $@;
# 
#   my $rootwin = $X->root;
#   my ($root, $parent, @children) = $X->QueryTree ($rootwin);
# 
#   my $grab = X11::Protocol::GrabServer->new($X);
#   foreach my $child (@children) {
# 
#   }
# 
#   my $pixmap = $X->new_rsrc;
#   $X->CreatePixmap ($pixmap,
#                     $rootwin,
#                     $X->root_depth,
#                     100,100);
# 
#   my $gc = $X->new_rsrc;
#   $X->CreateGC ($gc, $rootwin); # , subwindow_mode => 'IncludeInferiors');
# }
