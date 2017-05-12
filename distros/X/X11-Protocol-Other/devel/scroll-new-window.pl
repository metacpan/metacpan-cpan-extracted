#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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
use Time::HiRes;
use X11::Protocol;
use X11::Protocol::WM;

use lib 'devel', '.';

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $X = X11::Protocol->new (':0');
  $X->{'event_handler'} = sub {
    my (%h) = @_;
    ### event_handler: \%h
  };

  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $X->root,         # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    0,0,              # x,y
                    100,100,          # width,height
                    0,                # border
                    background_pixel => $X->black_pixel,
                    event_mask       => $X->pack_event_mask('ButtonPress',
                                                            'ButtonMotion',
                                                            'PointerMotion',
                                                            'EnterWindow',
                                                            'LeaveWindow',
                                                            'FocusChange',
                                                            'OwnerGrabButton',
                                                           ),
                   );
  $X->MapWindow ($window);
  $X->flush;

  my $target = time() + 2;
  for (;;) {
    Time::HiRes::usleep(100);
    while (fh_readable ($X->{'connection'}->fh)) {
      ### handle_input
      $X->handle_input;
    }
    if (defined $target && time() > $target) {
      $target = undef;
      my %p = $X->QueryPointer($X->root);
      ### %p
      my $x = $p{'root_x'};
      my $y = $p{'root_y'};
      my $win2 = $X->new_rsrc;
      $X->CreateWindow ($win2,
                        $X->root,         # parent
                        'InputOutput',
                        0,                # depth, from parent
                        'CopyFromParent', # visual
                        $x-30,$y-30,              # x,y
                        60,60,          # width,height
                        0,                # border
                        background_pixel => $X->black_pixel,
                       );
      X11::Protocol::WM::set_wm_normal_hints ($X, $win2,
                                              user_position => 1,
                                              user_size => 1,
                                             );
      $X->MapWindow ($win2);
      $X->flush;
    }
  }
  exit 0;
}

sub fh_readable {
  my ($fh) = @_;
  require IO::Select;
  my $s = IO::Select->new;
  $s->add($fh);
  my @ready = $s->can_read(1);
  return scalar(@ready);
}
