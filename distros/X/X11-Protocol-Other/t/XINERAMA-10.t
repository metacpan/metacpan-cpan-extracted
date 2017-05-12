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

my $test_count = (tests => 8)[1];
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
    = $X->QueryExtension('XINERAMA');
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no XINERAMA on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("XINERAMA extension is opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('XINERAMA')) {
  die "QueryExtension says XINERAMA avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# PanoramiXQueryVersion

{
  my $client_major = 1;
  my $client_minor = 0;
  my @ret = $X->PanoramiXQueryVersion ($client_major, $client_minor);
  MyTestHelpers::diag ("PanoramiXQueryVersion ", join('.',@ret));
  ok (scalar(@ret), 2);
  my ($server_major, $server_minor) = @ret;
  ok ($server_major <= $client_major, 1,
     "PanoramiXQueryVersion server_major $server_major <= 1");
}


#------------------------------------------------------------------------------
# PanoramiXGetState

{
  my @ret = $X->PanoramiXGetState ($X->root);
  MyTestHelpers::diag ("PanoramiXGetState ", join(', ',@ret));
  ok (scalar(@ret), 1);
}


#------------------------------------------------------------------------------
# PanoramiXGetScreenCount

my $monitor_count;
{
  my @ret = $X->PanoramiXGetScreenCount ($X->root);
  MyTestHelpers::diag ("PanoramiXGetScreenCount ", join(', ',@ret));
  ok (scalar(@ret), 1);
  $monitor_count = $ret[0];
  ok ($monitor_count >= 0, 1);
}


#------------------------------------------------------------------------------
# PanoramiXGetScreenSize

# Is PanoramiXGetScreenSize() permitted when no monitors?  Seems ok on X.org
# 1.9.x but for safety skip if $monitor_count == 0.
{
  my @ret;
  if ($monitor_count > 0) {
    @ret = $X->PanoramiXGetScreenSize ($X->root, 0);
  }
  MyTestHelpers::diag ("PanoramiXGetScreenSize ", join(', ',@ret));
  skip ($monitor_count == 0,
        scalar(@ret), 2);
  skip ($monitor_count == 0,
        defined $ret[0] && $ret[0] >= 0, 1);
  skip ($monitor_count == 0,
        defined $ret[1] && $ret[1] >= 0, 1);
}


#------------------------------------------------------------------------------

exit 0;
