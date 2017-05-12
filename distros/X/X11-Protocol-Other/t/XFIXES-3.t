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

BEGIN { require 5 }
use strict;
use X11::Protocol;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
END { MyTestHelpers::diag ("END"); }

# uncomment this to run the ### lines
#use Smart::Comments;

my $test_count = (tests => 5)[1];
plan tests => $test_count;

require X11::Protocol;
MyTestHelpers::diag ("X11::Protocol version ", X11::Protocol->VERSION);

my $display = $ENV{'DISPLAY'};
if (! defined $display) {
  foreach (1 .. $test_count) {
    skip ('No DISPLAY set', 1, 1);
  }
  exit 0;
}

# pass display arg so as not to get a "guess" warning
my $X;
if (! eval { $X = X11::Protocol->new ($display); }) {
  MyTestHelpers::diag ('Cannot connect to X server -- ',$@);
  foreach (1 .. $test_count) {
    skip ('Cannot connect to X server', 1, 1);
  }
  exit 0;
}
$X->QueryPointer($X->{'root'});  # sync

{
  my ($major_opcode, $first_event, $first_error)
    = $X->QueryExtension('XFIXES');
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no XFIXES on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("XFIXES extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('XFIXES')) {
  die "QueryExtension says XFIXES avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync

{
  my $client_major = 3;
  my $client_minor = 0;
  my ($server_major, $server_minor) = $X->XFixesQueryVersion ($client_major, $client_minor);
  MyTestHelpers::diag ("XFixesQueryVersion ask for $client_major.$client_minor got server version $server_major.$server_minor");
  if ($server_major < $client_major) {
    foreach (1 .. $test_count) {
      skip ("QueryVersion() no XFIXES $client_major.$client_minor on the server", 1, 1);
    }
    exit 0;
  }
}


#------------------------------------------------------------------------------
# XFixesExpandRegion()

{
  my $region = $X->new_rsrc;
  $X->XFixesCreateRegion ($region, [5,6,7,8]);
  $X->QueryPointer($X->root); # sync

  my $r2 = $X->new_rsrc;
  $X->XFixesCreateRegion ($r2, [5,6,7,8]);
  $X->QueryPointer($X->root); # sync

  $X->XFixesExpandRegion ($region, $r2,
                          10,  # left
                          20,  # right
                          30,  # top
                          40); # bottom
  $X->QueryPointer($X->root); # sync

  my ($bounding, @rects) = $X->XFixesFetchRegion ($r2);
  ### @rects
  ok ($bounding->[0], 5-10, 'x');
  ok ($bounding->[1], 6-30, 'y');
  ok ($bounding->[2], 7+10+20, 'width');
  ok ($bounding->[3], 8+30+40, 'height');

  ok (scalar(@rects), 1);

  $X->XFixesDestroyRegion ($region);
  $X->QueryPointer($X->root); # sync
}

exit 0;
