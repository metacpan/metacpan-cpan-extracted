#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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
# use Smart::Comments;


my $test_count = (tests => 23)[1];
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

# SYNC available on the server
my ($major_opcode, $first_event, $first_error)
  = $X->QueryExtension('SYNC');
{
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no SYNC on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("SYNC extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('SYNC')) {
  die "QueryExtension says SYNC avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync

# 3.1 or higher
{
  my $sync = $X->{'ext'}->{'SYNC'}->[3];
  my $server_major = $sync->{'major'};
  my $server_minor = $sync->{'minor'};
  MyTestHelpers::diag ("SYNC extension version $server_major.$server_minor");
  unless ($server_major > 3
      || ($server_major == 3 && $server_minor >= 1)) {
    foreach (1 .. $test_count) {
      skip ("only SYNC $server_major.$server_minor on the server", 1, 1);
    }
    exit 0;
  }
}

if ($ENV{'X11_PROTOCOL_OTHER__SKIP_SYNC_31'}) {
  MyTestHelpers::diag ("X11_PROTOCOL_OTHER__SKIP_SYNC_31");
  foreach (1 .. $test_count) {
    skip ("due to X11_PROTOCOL_OTHER__SKIP_SYNC_31", 1, 1);
  }
  exit 0;
}


#------------------------------------------------------------------------------
# Errors

{
  ok ($X->num('Error','Counter'),    $first_error);
  ok ($X->num('Error','Alarm'),      $first_error+1);
  ok ($X->num('Error','Fence'),      $first_error+2);
  ok ($X->num('Error',$first_error), $first_error);
  ok ($X->num('Error',$first_error+1), $first_error+1);
  ok ($X->num('Error',$first_error+2), $first_error+2);
  ok ($X->interp('Error',$first_error),   'Counter');
  ok ($X->interp('Error',$first_error+1), 'Alarm');
  ok ($X->interp('Error',$first_error+2), 'Fence');
  {
    local $X->{'do_interp'} = 0;
    ok ($X->interp('Error',$first_error), $first_error);
    ok ($X->interp('Error',$first_error+1), $first_error+1);
    ok ($X->interp('Error',$first_error+2), $first_error+2);
  }
}


#------------------------------------------------------------------------------
# SyncCreateFence / SyncDestroyFence

{
  my $drawable = $X->root;

  my $fence = $X->new_rsrc;
  $X->SyncCreateFence ($fence, $drawable, 0);
  ### $fence
  ### QueryPointer ...
  $X->QueryPointer($X->root); # sync
  ### done ...
  ok (1, 1, 'SyncCreateFence, initially untriggered');

  { my $value = $X->SyncQueryFence ($fence);
    ### $value
    ok ($value, 0);
  }

  $X->SyncTriggerFence ($fence);
  # wait a little while for rendering to complete, perhaps
  $X->QueryPointer($X->root); # sync
  sleep 1;
  $X->QueryPointer($X->root); # sync

  { my $value = $X->SyncQueryFence ($fence);
    ok ($value, 1,
        'fence triggered after short delay');
  }

  $X->SyncResetFence ($fence);

  { my $value = $X->SyncQueryFence ($fence);
    ok ($value, 0, 'fence untriggered again');
  }

  $X->SyncDestroyFence ($fence);
  $X->QueryPointer($X->root); # sync
  ok (1, 1, 'SyncDestroyFence');
}

{
  my $drawable = $X->root;

  my $fence = $X->new_rsrc;
  $X->SyncCreateFence ($fence, $drawable, 1);
  $X->QueryPointer($X->root); # sync
  ok (1, 1, 'SyncCreateFence, initially triggered');

  { my $value = $X->SyncQueryFence ($fence);
    ok ($value, 1,
        'fence initially triggered state');
  }

  $X->SyncDestroyFence ($fence);
  $X->QueryPointer($X->root); # sync
  ok (1, 1, 'SyncDestroyFence');
}


#------------------------------------------------------------------------------
# SyncAwaitFence

{
  my $drawable = $X->root;

  my $f1 = $X->new_rsrc;
  $X->SyncCreateFence ($f1, $drawable, 0);

  my $f2 = $X->new_rsrc;
  $X->SyncCreateFence ($f2, $drawable, 1);

  $X->SyncAwaitFence ($f2);
  $X->QueryPointer($X->root); # sync
  ok (1, 1, 'SyncAwaitFence');

  $X->SyncAwaitFence ($f1,$f2);
  $X->QueryPointer($X->root); # sync
  ok (1, 1, 'SyncAwaitFence');

  $X->SyncDestroyFence ($f1);
  $X->SyncDestroyFence ($f2);
  $X->QueryPointer($X->root); # sync
  ok (1, 1, 'SyncDestroyFence');
}


#------------------------------------------------------------------------------

exit 0;
