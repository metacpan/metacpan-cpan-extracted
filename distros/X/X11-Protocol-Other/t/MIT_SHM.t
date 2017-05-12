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

my $test_count = (tests => 29)[1];
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

my ($major_opcode, $first_event, $first_error)
  = $X->QueryExtension('MIT-SHM');
{
  if (! defined $major_opcode) {
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


#------------------------------------------------------------------------------
# "ShmSeg" error

{
  ok ($X->num('Error','ShmSeg'),     $first_error);
  ok ($X->num('Error',$first_error), $first_error);
  ok ($X->interp('Error',$first_error), 'ShmSeg');
  {
    local $X->{'do_interp'} = 0;
    ok ($X->interp('Error',$first_error), $first_error);
  }
}

#------------------------------------------------------------------------------
# MitShmCompletion event

{
  my $aref = $X->{'ext'}->{'MIT_SHM'};
  my ($request_num, $event_num, $error_num, $obj) = @$aref;

  my $offset;
  foreach $offset (0, 0xFFFFFFFF) {
    my %input = (# can't "name" to pack an extension event, at least in 0.56
                 # name      => "MitShmCompletion",
                 synthetic => 1,
                 code      => $event_num,
                 sequence_number => 100,

                 drawable     => 101,
                 minor_opcode => 102,
                 major_opcode => 103,
                 shmseg       => 104,
                 offset       => $offset);
    my $data = $X->pack_event(%input);
    ok (length($data), 32);

    my %output = $X->unpack_event($data);
    ### %output

    ok ($output{'code'},          $input{'code'});
    ok ($output{'name'},          'MitShmCompletion');
    ok ($output{'synthetic'},     $input{'synthetic'});
    ok ($output{'drawable'},      $input{'drawable'});
    ok ($output{'major_opcode'},  $input{'major_opcode'});
    ok ($output{'minor_opcode'},  $input{'minor_opcode'});
    ok ($output{'shmseg'},        $input{'shmseg'});
    ok ($output{'offset'},        $input{'offset'});
  }
}


#------------------------------------------------------------------------------
# MitShmQueryVersion

ok (eval { $X->MitShmQueryVersion (1,0); 1 },
    undef,
    'MitShmQueryVersion with args throws an error');

{
  my @ret = $X->MitShmQueryVersion ();
  MyTestHelpers::diag ("MitShmQueryVersion got ", join(', ',@ret));
  ok (scalar(@ret), 6);

  my ($major, $minor, $uid, $gid, $shared_pixmaps, $format) = @ret;
  ok ($major >= 0, 1);
  ok ($minor >= 0, 1);
  ok ($uid >= 0, 1);
  ok ($gid >= 0, 1);
  ok ($shared_pixmaps >= 0, 1);
  # $format XYPixmap or ZPixmap, probably, maybe
}
$X->QueryPointer($X->root); # sync

exit 0;
