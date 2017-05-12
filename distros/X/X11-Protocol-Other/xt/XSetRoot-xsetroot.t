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


# Exercise the inter-operation with xsetroot.  The properties it sets should
# be deleted by X11::Protocol::XSetRoot->set_background().
#
# This test requires that the root visual is dynamic, ie. PseudoColor etc.
# The x.org Xvfb test server can be run up with that by
#
#   xvfb-run -a -s '-cc 33' perl XSetRoot-xsetroot.t
#
# If that doesn't seem to work then check its operation with
# xvfb-run -a -s '-cc 33' xdpyinfo

BEGIN { require 5 }
use strict;
use Test;

use FindBin;
use lib "$FindBin::Bin/../t";
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use X11::Protocol::Other;
use X11::Protocol::XSetRoot;


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
MyTestHelpers::diag ("DISPLAY ", $display);

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

my $visual = $X->{'root_visual'};
my $visual_is_dynamic = X11::Protocol::Other::visual_is_dynamic($X,$visual);
if (! $visual_is_dynamic) {
  MyTestHelpers::diag ("root_visual $visual is not dynamic, xsetroot won't RetainPermanent");
  foreach (1 .. $test_count) {
    skip ('root visual not dynamic', 1, 1);
  }
  exit 0;
}
MyTestHelpers::diag ('root visual is dynamic');

# Something fishy with xvfb test server seems to cause the reconnect below
# to fail.  Keeping a second connection makes it better, dunno why.
my $keepalive_X = X11::Protocol->new ($display);

my $xsetroot_output = `xsetroot 2>&1`;
my $have_xsetroot = ($? == 0);
if (! $have_xsetroot) {
  MyTestHelpers::diag ("xsetroot error:\n", $xsetroot_output);
  foreach (1 .. $test_count) {
    skip ('xsetroot program not available', 1, 1);
  }
  exit 0;
}
MyTestHelpers::diag ('xsetroot available');


#------------------------------------------------------------------------------
# set_background()

system ('xsetroot -solid pink');

# Properties are set.
my $xrootpmap;
{
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($X->root, $X->atom('_XSETROOT_ID'),
                       0,    # AnyPropertyType
                       0,    # offset
                       1,    # length
                       0);   # delete;
  ok ($type, X11::AtomConstants::PIXMAP());
  ok ($format, 32);
  if ($type == X11::AtomConstants::PIXMAP()) {
    $xrootpmap = unpack 'L', $value;
  }
}

X11::Protocol::XSetRoot->set_background
  (display => $display,
   color => 'black');

# Properties should be deleted by set_background().
{
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($X->root, $X->atom('_XSETROOT_ID'),
                       0,    # AnyPropertyType
                       0,    # offset
                       1,    # length
                       0);   # delete;
  ok ($type, 0);
  ok ($format, 0);
}

{
  my $skip;
  my $xrootpmap_now_exists;
  if (! $xrootpmap) {
    $skip = 'due to _XSETROOT_ID not set';
  } else {
    my @ret = $X->robust_req ('GetImage',
                              $xrootpmap,
                              0,0, 1,1,
                              0xFFFF_FFFF, # plane mask
                              'ZPixmap');  # format
    if (ref $ret[0]) {
      # success
      $xrootpmap_now_exists = 1;
    } else {
      my ($type, $major, $minor) = @ret;
      MyTestHelpers::diag ("GetImage error (expected): type=$type opcode=$major.$minor");
      # error
      $xrootpmap_now_exists = 0;
    }
  }
  skip ($skip,
        $xrootpmap_now_exists, 0,
        '_XSETROOT_ID pixmap should now not exist (due to KillClient)');
}

#------------------------------------------------------------------------------

  exit 0;
