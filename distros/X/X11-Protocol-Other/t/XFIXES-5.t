#!/usr/bin/perl -w

# Copyright 2011, 2013, 2014 Kevin Ryde

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
use Test;

BEGIN { require 5 }
use strict;
use Test;

use lib 't';
use MyTestHelpers;
#BEGIN { MyTestHelpers::nowarnings() }
END { MyTestHelpers::diag ("END"); }

# uncomment this to run the ### lines
# use Smart::Comments;

my $test_count = (tests => 3)[1];
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
  my $client_major = 5;
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
# XFixesCreatePointerBarrier() / XFixesDestroyPointerBarrier()

{
  my $barrier = $X->new_rsrc;
  $X->XFixesCreatePointerBarrier ($barrier, $X->root, 100,100, 200,100,
                                  0); # directions
  $X->QueryPointer($X->root); # sync

  $X->XFixesDestroyPointerBarrier ($barrier);
  $X->QueryPointer($X->root); # sync

  ok (1,1, 'plain barrier, no devices listed');
}

#------------------------------------------------------------------------------
# XFixesCreatePointerBarrier() / XFixesDestroyPointerBarrier()
# with XInputExtension style "AllDevices"
#
# Xvfb 1.11.1.901 server gave "Implementation" (17) error when passing
# AllDevices.  Ignore that, but still throw a normal error for anything
# else, like bad length etc.
#
# Xorg server circa 1.14.3 doesn't accept AllDevices in
# XFixesCreatePointerBarrier(), though it's described in the spec.
#
# Xorg server somewhere prior to 1.14.5 didn't take any devices args and
# gave a Length (16) error on passing any.  The checkin accepting those args
# is
# http://cgit.freedesktop.org/xorg/xserver/commit/xfixes/cursor.c?id=04c885de715a7c989e48fc8cf2e61db2b401de2d

{
  my $barrier;
  my $orig_error_handler = $X->{'error_handler'};
  local $X->{'error_handler'} = sub {
    my ($X, $data) = @_;
    ### error handler
    ### $data

    my ($type, $seq, $info, $minor_op, $major_op) = unpack 'xCSLSC', $data;
    if ($type == $X->num('Error','Implementation')) {
      MyTestHelpers::diag ("ignore XFixesCreatePointerBarrier error \"Implementation\"");
      undef $barrier;

    } elsif ($type == $X->num('Error','Length')) {
      # Length error is bad ...
      goto $orig_error_handler;

    } else {
      # AllDevices gives "Device" error from Xorg server 1.14.3.
      # That error is from XInputExtension and since that extension is not
      # initialized we don't know its error number, and $X->interp() gives
      # undef for the name.
      #
      MyTestHelpers::diag ("ignore XFixesCreatePointerBarrier error ", $type,
                           " '", $X->interp('Error',$type), "'");
      undef $barrier;
    }
  };

  {
    $barrier = $X->new_rsrc;
    $X->XFixesCreatePointerBarrier ($barrier, $X->root, 100,100, 200,100,
                                    0); # directions
    $X->QueryPointer($X->root); # sync

    if (defined $barrier) {  # if it was successfully created
      $X->XFixesDestroyPointerBarrier ($barrier);
      undef $barrier;
      $X->QueryPointer($X->root); # sync
    }
    ok (1,1, 'no devices barrier');
  }

  {
    my $have_pointer_barrier_devices = 1;
    if ($X->vendor eq 'The X.Org Foundation' && $X->release_number < 11405000) {
      $have_pointer_barrier_devices = 0;
      MyTestHelpers::diag ("X.org server ",$X->release_number," probably doesn't have XFixesCreatePointerBarrier() devices args, skip test");
    }

    my $skip;
    if (! $have_pointer_barrier_devices) {
      $skip = 'due to no devices args to XFixesCreatePointerBarrier()';
    }

    if ($have_pointer_barrier_devices) {
      $barrier = $X->new_rsrc;
      $X->XFixesCreatePointerBarrier ($barrier, $X->root, 100,100, 200,100,
                                      0,  # directions
                                      'AllDevices');
      $X->QueryPointer($X->root);  # sync

      if (defined $barrier) {  # if it was successfully created
        $X->XFixesDestroyPointerBarrier ($barrier);
        undef $barrier;
        $X->QueryPointer($X->root); # sync
      }
    }
    skip ($skip, 1,1, 'AllDevices barrier');
  }
}

#------------------------------------------------------------------------------

exit 0;
