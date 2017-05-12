#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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




use lib 'devel/lib';
$ENV{'DISPLAY'} ||= ":0";







BEGIN { require 5 }
use strict;
use X11::Protocol;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
END { MyTestHelpers::diag ("END"); }

# uncomment this to run the ### lines
use Smart::Comments;


my $test_count = (tests => 105)[1];
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

# DRI2 available on the server
my ($major_opcode, $first_event, $first_error)
  = $X->QueryExtension('DRI2');
{
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no DRI2 on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("DRI2 extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('DRI2')) {
  die "QueryExtension says DRI2 avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync

# 1.1 or higher
{
  my ($server_major, $server_minor) = $X->DRI2QueryVersion (1,1);

  MyTestHelpers::diag ("DRI2 extension version $server_major.$server_minor");
  unless ($server_major > 1
      || ($server_major == 1 && $server_minor >= 1)) {
    foreach (1 .. $test_count) {
      skip ("only DRI2 $server_major.$server_minor on the server", 1, 1);
    }
    exit 0;
  }
}


#------------------------------------------------------------------------------
# DRI2GetBuffersWithFormat

{
  my $drawable = $X->new_rsrc;
  $X->CreatePixmap ($drawable,
                    $X->root,
                    1,     # depth
                    32,32);  # width,height

  my $args_list;
  foreach $args_list ([ ],
                      [ ['BackLeft',0] ],
                      [ ['BackLeft',0],['Accum',1] ],
                     ) {
    my $num_attach = scalar(@$args_list);
    my @ret = $X->robust_req ('DRI2GetBuffersWithFormat',
                              $drawable,@$args_list);
    ### @ret
    my $skip;
    if (ref $ret[0]) {
      @ret = @{$ret[0]};
      MyTestHelpers::diag ("DRI2GetBuffers succeeded: ",join(', ',@ret));
    } else {
      my ($type, $major, $minor) = @ret;
      MyTestHelpers::diag ("DRI2GetBuffers failed");
      $skip = "DRI2GetBuffers failed: $type";
    }
    skip ($skip,
          scalar(@ret) >= 2,
          1,
          "DRI2GetBuffersWithFormat return count ".scalar(@ret));
  }
}

#------------------------------------------------------------------------------

exit 0;
