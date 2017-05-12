#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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


my $test_count = (tests => 21)[1];
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
$X->QueryPointer($X->root);  # sync

{
  my ($major_opcode, $first_event, $first_error)
    = $X->QueryExtension('DOUBLE-BUFFER');
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no DOUBLE-BUFFER on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("DOUBLE-BUFFER extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('DOUBLE-BUFFER')) {
  MyTestHelpers::diag ("QueryExtension says DOUBLE-BUFFER avaiable, but init_extension() failed");
  die;
}
$X->QueryPointer($X->root); # sync

my $dbe_obj = $X->{'ext'}->{'DOUBLE_BUFFER'}->[3];
ok (!!$dbe_obj, 1, 'Dbe object');
MyTestHelpers::diag ("DOUBLE-BUFFER extension version $dbe_obj->{'major'}.$dbe_obj->{'minor'}");



#------------------------------------------------------------------------------
# Have seen an xfree86 3.3.6 server somehow botch the length in its reply
# and end up sending nothing in reply DbeGetVisualInfo, unless you provoke
# it to further output by just a send() and then further send()s fetching
# something (QueryPointer, GetAtomName, whatever).
#
# Think this is a server bug, and one not easily worked around.  For now set
# an alarm() so as not to hang but otherwise let this .t script fail.
#

if (exists $SIG{'ALRM'}) {
  # no SIGALRM in perl 5.6.0, it seems, maybe
  $SIG{'ALRM'} = sub {
    MyTestHelpers::diag ("Oops, timeout");
    exit 1;
  };
}
alarm(30);



#------------------------------------------------------------------------------
# DbeSwapAction enum

{
  ok ($X->num('DbeSwapAction','Undefined'),  0);
  ok ($X->num('DbeSwapAction','Background'), 1);
  ok ($X->num('DbeSwapAction','Untouched'),  2);
  ok ($X->num('DbeSwapAction','Copied'),     3);

  ok ($X->num('DbeSwapAction',0), 0);
  ok ($X->num('DbeSwapAction',1), 1);
  ok ($X->num('DbeSwapAction',2), 2);
  ok ($X->num('DbeSwapAction',3), 3);

  ok ($X->interp('DbeSwapAction',0), 'Undefined');
  ok ($X->interp('DbeSwapAction',1), 'Background');
  ok ($X->interp('DbeSwapAction',2), 'Untouched');
  ok ($X->interp('DbeSwapAction',3), 'Copied');
}

#------------------------------------------------------------------------------
# DbeGetVisualInfo

my $have_root_dbe = 0;
{
  ### DbeGetVisualInfo one screen ...
  my @info_aref_list = $X->DbeGetVisualInfo ($X->root);
  ### @info_aref_list
  $X->QueryPointer($X->{'root'}); # sync

  ok (scalar(@info_aref_list), 1);
  my $info_aref = $info_aref_list[0];
  ok (ref $info_aref, 'ARRAY');
  ok (ref $info_aref eq 'ARRAY' && (scalar(@$info_aref) % 2) == 0,
      1,
      'info array even length');

  my $good = 1;
  if (ref $info_aref eq 'ARRAY') {
    my $visual = shift @$info_aref;
    my $dp = shift @$info_aref;

    if ($visual !~ /^\d+$/) {
      MyTestHelpers::diag ("DbeGetVisualInfo visual not numeric: $visual");
      $good = 0;
    }
    if (! $X->{'visuals'}->{$visual}) {
      MyTestHelpers::diag ("DbeGetVisualInfo no such visual: $visual");
      $good = 0;
      next;
    }
    $have_root_dbe ||= ($visual == $X->root_visual);
    my $want_depth = $X->{'visuals'}->{$visual}->{'depth'};

    if (ref $dp ne 'ARRAY') {
      MyTestHelpers::diag ("DbeGetVisualInfo depth/perf not an arrayref: $dp");
      $good = 0;
      next;
    }
    if (scalar(@$dp) ne 2) {
      MyTestHelpers::diag ("DbeGetVisualInfo depth/perf length bad: ",
                           scalar(@$dp));
      $good = 0;
    }
    my $got_depth = $dp->[0];
    my $got_perf = $dp->[1];

    if ($got_depth != $want_depth) {
      MyTestHelpers::diag ("DbeGetVisualInfo visual $visual depth $got_depth but server info has $want_depth");
      $good = 0;
    }
    if ($got_perf !~ /^\d+$/) {
      MyTestHelpers::diag ("DbeGetVisualInfo perf not numeric: $got_perf");
      $good = 0;
    }
  }
  ok ($good, 1);
}

{
  ### DbeGetVisualInfo all screens ...
  my @info_aref_list = $X->DbeGetVisualInfo ();
  $X->QueryPointer($X->{'root'}); # sync

  my $num_screens = scalar(@{$X->{'screens'}});
  ok (scalar(@info_aref_list), $num_screens);
}

# in scalar context unspecified yet
# {
#   my $info_aref = $X->DbeGetVisualInfo ($X->root);
#   $X->QueryPointer($X->{'root'}); # sync
# 
#   ok (ref $info_aref, 'ARRAY');
#   if (ref $info_aref ne 'ARRAY') {
#     MyTestHelpers::diag ("DbeGetVisualInfo scalar context info: $info_aref");
#   }
#   my $visual = (ref($info_aref) eq 'ARRAY') && $info_aref->[0];
#   ok ($visual =~ /^\d+$/ ? 1 : 0, 1);
# }


#------------------------------------------------------------------------------

{
  ### DbeAllocateBackBufferName ...
  my $buffer = $X->new_rsrc;
  $X->DbeAllocateBackBufferName ($X->root, $buffer, 'Copied');
  $X->QueryPointer($X->root); # sync
  ### $buffer

  {
    my $got_window = $X->DbeGetBackBufferAttributes ($buffer);
    ok ($got_window, $X->root, 'GetBackBufferAttributes window');
  }

  $X->DbeBeginIdiom;
  $X->DbeEndIdiom;

  $X->DbeSwapBuffers ($X->root, 'Untouched');
  $X->DbeSwapBuffers ($X->root, 'Untouched');

  $X->DbeDeallocateBackBufferName ($buffer);
  $X->QueryPointer($X->root); # sync
}

{
  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $X->root,         # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    0,0,              # x,y
                    100,100,          # width,height
                    0);               # border

  my $buffer = $X->new_rsrc;
  $X->DbeAllocateBackBufferName ($window, $buffer, 'Copied');

  {
    my $got_window = $X->DbeGetBackBufferAttributes ($buffer);
    ok ($got_window, $window, 'GetBackBufferAttributes for own window');
  }

  $X->DestroyWindow ($window);

  {
    my $got_window = $X->DbeGetBackBufferAttributes ($buffer);
    ok ($got_window, 'None', 'GetBackBufferAttributes for destroyed window');
  }
}

#------------------------------------------------------------------------------

exit 0;
