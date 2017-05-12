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


# Usage: perl xresource-print.pl
#
# This is an example printing the resource counts and pixmap bytes used for
# all clients.
#
# The only subtle part is $X->robust_req() which is used in case a client
# disconnects in between the XResourceQueryClients() list and then querying
# each for their usage.  It's only a short time between, but error checking
# is a good idea when dealing with things belonging to other clients.
#
# An eval{} around a plain $X->XResourceQueryClientResources() is another
# way to do it.  Such an eval might also catch error replies queued up from
# earlier asynchronous requests.  There's none in this case, but it's the
# nature of the protocol to only get back errors later on.
#
# For reference, in X11::Protocol 0.56 an $X->{'error_handler'} isn't very
# good for continuing processing things with replies.  If the handler merely
# prints a message and returns then something fishy happens, giving an empty
# reply to the unpacking which then often throws an error (unpack of no data
# is an error).
#

use 5.004;
use strict;
use X11::Protocol;

my $X = X11::Protocol->new;
if (! $X->init_extension('X-Resource')) {
  print "X-Resource extension not available on the server\n";
  exit 0;
}

my @clients = $X->XResourceQueryClients;

foreach my $client (@clients) {
  my ($xid_base, $xid_mask) = @$client;

  printf "client 0x%X is using\n", $xid_base;

  my $ret = $X->robust_req('XResourceQueryClientResources', $xid_base);
  if (ref $ret) {
    my @resources = @$ret;
    while (@resources) {
      my $atom = shift @resources;
      my $count = shift @resources;
      my $atom_name = $X->atom_name($atom);
      printf "%6d  %s\n", $count, $atom_name;
    }
  } else {
    print "  error getting client resources\n";
  }

  $ret = $X->robust_req ('XResourceQueryClientPixmapBytes', $xid_base);
  if (ref $ret) {
    my ($bytes) = @$ret;
    printf "%6s  PixmapBytes\n", $bytes;
  } else {
    print "  error getting pixmap bytes\n";
  }

  print "\n";
}

exit 0;
