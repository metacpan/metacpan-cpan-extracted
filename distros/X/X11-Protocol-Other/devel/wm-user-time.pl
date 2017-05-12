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

my $X = X11::Protocol->new (':0');
$X->{'event_handler'} = \&event_handler;
sub event_handler {
  my (%h) = @_;
  ### event_handler: \%h
  if ($h{'name'} eq 'PropertyNotify') {
    print $X->atom_name($h{'atom'}),"\n";
    my ($value, $type, $format, $bytes_after)
      = $X->GetProperty ($h{'window'}, $h{'atom'},
                         0,  # AnyPropertyType
                         0,  # offset
                         999,  # length
                         0); # delete;
    if ($type eq $X->atom('CARDINAL')) {
      $value = unpack 'L', $value;
    }
    print "  ",$X->atom_name($type),": $value\n";
  }
};

foreach my $window (@ARGV) {
  $X->ChangeWindowAttributes
    (oct($window), event_mask => $X->pack_event_mask('PropertyChange'));
}

foreach (1 .. 20) {
  $X->handle_input;
}
exit 0;
