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

my $test_count = (tests => 2)[1];
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
    MyTestHelpers::diag ('QueryExtension() no XINERAMA on the server');
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

{
  my ($major, $minor) = $X->PanoramiXQueryVersion (1,1);
  if (($major <=> 1 || $minor <=> 1) < 0) {
    MyTestHelpers::diag ("PanoramiXQueryVersion() no 1.1 on the server, only $major.$minor");
    foreach (1 .. $test_count) {
      skip ('PanoramiXQueryVersion() no 1.1 on the server', 1, 1);
    }
    exit 0;
  }
}


#------------------------------------------------------------------------------
# XineramaIsActive

{
  my @ret = $X->XineramaIsActive ();
  MyTestHelpers::diag ("XineramaIsActive ", join(', ',@ret));
  ok (scalar(@ret), 1);
}


#------------------------------------------------------------------------------
# XineramaQueryScreens

my $monitor_count;
{
  my @ret = $X->XineramaQueryScreens ();
  MyTestHelpers::diag ("XineramaQueryScreens count ",scalar(@ret));
  my $good = 1;
  my $rect;
  foreach $rect (@ret) {
    if (ref($rect) ne 'ARRAY') {
      $good = 0;
      MyTestHelpers::diag ("XineramaQueryScreens return not an arrayref");
    } elsif (scalar(@$rect) != 4) {
      $good = 0;
      MyTestHelpers::diag ("XineramaQueryScreens not 4-element array ",
                           scalar(@$rect));
    } else {
      MyTestHelpers::diag ("XineramaQueryScreens rectangle ", join(',',@$rect));
    }
  }
  ok ($good, 1);
}

#------------------------------------------------------------------------------

exit 0;
