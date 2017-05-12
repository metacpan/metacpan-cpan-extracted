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

my $test_count = (tests => 6)[1];
plan tests => $test_count;

# supplied with perl 5.005, might not be available earlier
if (! eval { require IPC::SysV; 1 }) {
  MyTestHelpers::diag ('IPC::SysV not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('IPC::SysV not available', 1, 1);
  }
  exit 0;
}

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

my ($major_opcode, $first_event, $first_error)
  = $X->QueryExtension('MIT-SHM');
{
  if (! defined $major_opcode) {
    MyTestHelpers::diag ('QueryExtension() no MIT-SHM on the server');
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no MIT-SHM on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("MIT-SHM extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('MIT-SHM')) {
  die "QueryExtension says MIT-SHM avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync

# perms 644 so server is certain to be able to read it
my $shmid;
if (! eval {
  $shmid = shmget (IPC::SysV::IPC_PRIVATE(),
                   5000,
                   0644 | IPC::SysV::IPC_CREAT()); # world read
  1;
}) {
  # usually a die or croak if no shm on the system
  MyTestHelpers::diag ('shmget() dies -- ',$@);
  foreach (1 .. $test_count) {
    skip ('shmget() dies', 1, 1);
  }
  exit 0;
}
if (! defined $shmid) {
  MyTestHelpers::diag ("shmget() cannot get shared memory: $!");
  foreach (1 .. $test_count) {
    skip ('shmget() cannot get shared memory', 1, 1);
  }
  exit 0;
}

#------------------------------------------------------------------------------
# MitShmAttach

my $shmseg = $X->new_rsrc;
if (! eval {
  local $^W = 0; # avoid warnings from X11::Protocol 0.56 format_error_msg()
  my $seq = $X->send ('MitShmAttach', $shmseg, $shmid, 1); # read-only
  $X->QueryPointer($X->{'root'}); # sync
  1;
}) {
  MyTestHelpers::diag ('MitShmAttach cannot attach readonly -- ',$@);
  foreach (1 .. $test_count) {
    skip ('MitShmAttach cannot attach readonly', 1, 1);
  }
  exit 0;
}

#------------------------------------------------------------------------------
# MitShmPutImage

{
  my $pixmap = $X->new_rsrc;
  $X->CreatePixmap ($pixmap,
                    $X->root,
                    1,     # depth
                    2,2);  # width,height

  my $gc = $X->new_rsrc;
  $X->CreateGC ($gc, $pixmap, foreground => $X->{'white_pixel'});

  my %event;
  local $X->{'event_handler'} = sub {
    my %h = @_;
    if ($h{'name'} eq 'MitShmCompletion') {
      %event = %h;
    }
  };
  my @ret =  $X->MitShmPutImage ($pixmap, $gc,
                                 1,    # depth,
                                 1,1,  # total width,height
                                 0,0,  # src x,y
                                 1,1,  # src width,height
                                 0,0,  # dst x,y
                                 'ZPixmap',
                                 1,
                                 $shmseg,
                                 0);
  $X->QueryPointer($X->{'root'}); # sync

  ok ($event{'name'}, 'MitShmCompletion');
  ok ($event{'drawable'}, $pixmap);
  ok ($event{'major_opcode'}, $major_opcode);
  ok ($event{'minor_opcode'}, 3);  # MitShmPutImage request num
  ok ($event{'shmseg'}, $shmseg);
  ok ($event{'offset'}, 0);
}

exit 0;
