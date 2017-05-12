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

# uncomment this to run the ### lines
use Smart::Comments;

$ENV{'DISPLAY'} ||= ':0';


{
  my $X = X11::Protocol->new;
  $X->init_extension('DOUBLE-BUFFER') or die;

  # {
  #   my @version = $X->DbeGetVersion (99,99);
  #   ### @version
  # }
  # # $X->QueryPointer($X->{'root'}); # sync

  {
    ### DbeGetVisualInfo send ...
    my $window = $X->root;
    my $seq = $X->send('DbeGetVisualInfo',$window);
    sleep 1;
    ### $seq
    ### sync ...

    # foreach (1..7) {
    #   $X->send('GetAtomName',3);
    # }
    # # $X->{'connection'}->give("\0"x16384);
    # $X->flush;
    # 
    # $X->QueryPointer($X->{'root'});

    for (;;) {
      ### X handle_input ...
      $X->handle_input;
    }
    exit 0;
  }

  {
    ### DbeGetVisualInfo ...
    ### seq: $X->{'sequence_num'}
    my @infos = $X->DbeGetVisualInfo($X->root);
    ### @infos
  }
  $X->QueryPointer($X->{'root'}); # sync

  exit 0;
}

{
  my $X = X11::Protocol->new (':0');
  $X->{'event_handler'} = sub {
    my (%h) = @_;
    ### event_handler: \%h
  };

  $X->init_extension('DOUBLE-BUFFER') or die $@;
  $X->QueryPointer($X->{'root'}); # sync

  my $width = 100;
  my $height = 100;
  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $X->root,         # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    0,0,              # x,y
                    $width,$height,
                    0,                # border
                    background_pixel => $X->black_pixel,
                   );
  $X->MapWindow ($window);
  sleep 1;

  my $gc = $X->new_rsrc;
  $X->CreateGC ($gc, $window,
                foreground => 0xFF00FF,
                background => 0);

  my $buffer = $X->new_rsrc;
  $X->DbeAllocateBackBufferName ($window, $buffer, 'Copied');
  $X->QueryPointer($X->{'root'}); # sync

  $X->PolyFillRectangle ($buffer, $gc, [10,10, $width,$height]);
  $X->QueryPointer($X->{'root'}); # sync
  sleep 1;

  $X->DbeSwapBuffers ($window, 'Copied');
  $X->QueryPointer($X->{'root'}); # sync
  sleep 1;

  {
    my @attr = $X->DbeGetBackBufferAttributes ($buffer);
    ### @attr
    $X->QueryPointer($X->{'root'}); # sync
  }
  $X->DestroyWindow ($window);
  $X->QueryPointer($X->{'root'}); # sync
  {
    my @attr = $X->DbeGetBackBufferAttributes ($buffer);
    ### @attr
    $X->QueryPointer($X->{'root'}); # sync
  }

  $X->DbeDellocateBackBufferName ($buffer);

  $X->PolyFillRectangle ($buffer, $gc, [0,0, $width,$height]);
  $X->QueryPointer($X->{'root'}); # sync

  exit 0;
}





sub atom_name_maybe {
  my ($X, $atom) = @_;
  my $ret = $X->robust_req ('GetAtomName', $atom);
  if (ref $ret) {
    return @$ret;
  }
  return '[not-atom]';
}
