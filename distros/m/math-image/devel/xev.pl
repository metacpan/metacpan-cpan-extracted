#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use X11::Protocol;


{
  system ("math-image --prima --size=50 &");
  sleep 1;
  print "\n";

  my $X = X11::Protocol->new;

  {
    my ($value, $type, $format, $bytes_after)
      = $X->GetProperty ($X->root,
                         $X->atom('_NET_SUPPORTED'),
                         'AnyPropertyType',
                         0,   # offset
                         999, # max length
                         0);  # delete;
    my @states = unpack 'L*', $value;
    foreach my $state (@states) {
      my $state_name = $X->atom_name($state);
      print " $state_name";
    }
    print "\n";
  }

  my @events;
  $X->{'event_handler'} = sub {
    push @events, { @_ };
  };

  my $window = $ARGV[0] || do {
    print "click to choose window\n";
    require X11::Protocol::ChooseWindow;
    X11::Protocol::ChooseWindow->choose(X=>$X)
    };
  printf "window %#X\n", $window;


  my $event_mask = $X->pack_event_mask('StructureNotify',
                                       'SubstructureNotify',
                                       'PropertyChange',
                                      );
  $X->ChangeWindowAttributes($window, event_mask => $event_mask);
  for (;;) {
    $X->handle_input;
    while (@events) {
      my $h = shift @events;
      my $name = $h->{'name'};
      if ($name eq 'PropertyNotify') {
        my $atom = $h->{'atom'};
        my $atom_name = $X->atom_name($h->{'atom'});
        print "$name  $atom_name($atom)\n";

        if ($atom_name eq '_NET_WM_STATE') {
          my ($value, $type, $format, $bytes_after)
            = $X->GetProperty ($window,
                               $atom,
                               'AnyPropertyType',
                               0,   # offset
                               999, # max length
                               0);  # delete;
          if ($type == 0) {
            print "  no such property\n";
          } else {
            my $type_name = $X->atom_name($type);
            my $length = length($value);
            print "  type=$type_name length=$length   ";
            my @states = unpack 'L*', $value;
            foreach my $state (@states) {
              my $state_name = $X->atom_name($state);
              # $state_name =~ s/^_NET_WM_STATE_//;
              print " $state_name";
            }
            print "\n";
          }
        }

        # if ($atom_name eq '_WIN_AREA') {
        #   my ($value, $type, $format, $bytes_after)
        #     = $X->GetProperty ($window,
        #                        $atom,
        #                        'AnyPropertyType',
        #                        0,   # offset
        #                        999, # max length
        #                        0);  # delete;
        #   if ($type == 0) {
        #     print "  no such property\n";
        #   } else {
        #     my $type_name = $X->atom_name($type);
        #     my $length = length($value);
        #     print "  type=$type_name length=$length   ";
        #     my @area = unpack 'L*', $value;
        #     print "  ",join(', ',@area),"\n";
        #   }
        # }

      } elsif ($name eq 'ButtonPress'
               || $name eq 'ButtonRelease') {
      } else {
        print "$name\n";
      }
    }
  }
  exit 0;
}
