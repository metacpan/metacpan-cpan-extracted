#!/usr/bin/perl -w

# Copyright 2013, 2014 Kevin Ryde

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

use 5.004;
use strict;
use X11::Protocol;
use X11::Protocol::WM;

# uncomment this to run the ### lines
use Smart::Comments;

# (x-get-selection 'PRIMARY 'STRING)
# (insert (x-get-selection 'PRIMARY 'UTF8_STRING))
# (x-get-selection 'PRIMARY 'COMPOUND_TEXT)
# (x-get-selection 'PRIMARY 'TEXT)

{
  my $X = X11::Protocol->new;
  my %h;
  $X->{'event_handler'} = sub {
    %h = @_;
    ### event_handler: \%h
  };

  my $selection_atom = $X->atom('PRIMARY');

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
                   );

  my ($owner) = $X->GetSelectionOwner($selection_atom);
  ### $owner

  # "TARGETS" atom list of supported conversions
  #
  my $prop = $X->atom('MY_PROPERTY');
  foreach my $target_name (
                           # 'TK_APPLICATION',
                           # 'CLASS',
                           # 'LENGTH', 'LIST_LENGTH','USER',
                           # 'INTEGER',
                           'TARGETS',
                           'TEXT',
                           'STRING',
                           'UTF8_STRING',
                           'COMPOUND_TEXT',
                          ) {
    ### $target_name

    my $target_atom = $X->atom($target_name);
    $X->ConvertSelection($selection_atom,
                         $target_atom,
                         $prop,    # property
                         $window,  # requestor
                         0,        # time
                        );
    $X->QueryPointer($X->{'root'}); # sync

    sleep 1;
    $X->QueryPointer($X->{'root'}); # sync
    ### event property: $h{'property'} ne 'None' && $X->atom_name($h{'property'})

    if ($h{'property'} ne 'None') {
      my ($value, $type, $format, $bytes_after)
        = $X->GetProperty ($window,
                           $prop,
                           0,    # AnyPropertyType
                           0,    # offset
                           999,  # length
                           1);   # delete;
      ### MY_PROPERTY value ...
      ### $value
      ### value bytes: join(' ', map {sprintf '%02X',ord} split //, $value)
      ### $type
      ### type: $type && $X->atom_name($type)
      ### $format
      ### $bytes_after

      if ($type == $X->atom('ATOM')) {
        ### atoms list: map {$X->atom_name($_)} unpack 'L*', $value
      }
    }
  }

  exit 0;
}
