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
#use Smart::Comments;

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


#------------------------------------------------------------------------------
# helpers

sub big_leftshift {
  my ($b, $n) = @_;
  require Math::BigInt;
  $b = Math::BigInt->new($b);
  $b <<= $n;
  return $b;
}

#------------------------------------------------------------------------------
# DRI2Driver enum

ok ($X->num('DRI2Driver','DRI'),   0);
ok ($X->num('DRI2Driver','VDPAU'), 1);

ok ($X->interp('DRI2Driver',0), 'DRI');
ok ($X->interp('DRI2Driver',1), 'VDPAU');


#------------------------------------------------------------------------------
# DRI2Attachment enum

ok ($X->num('DRI2Attachment','FrontLeft'),  0);
ok ($X->num('DRI2Attachment','BackLeft'),   1);
ok ($X->num('DRI2Attachment','FrontRight'), 2);
ok ($X->num('DRI2Attachment','BackRight'),  3);
ok ($X->num('DRI2Attachment','Depth'),      4);
ok ($X->num('DRI2Attachment','Stencil'),    5);
ok ($X->num('DRI2Attachment','Accum'),      6);
ok ($X->num('DRI2Attachment','FakeFrontLeft'),  7);
ok ($X->num('DRI2Attachment','FakeFrontRight'), 8);
ok ($X->num('DRI2Attachment','DepthStencil'),   9);
ok ($X->num('DRI2Attachment','Hiz'),           10);

ok ($X->interp('DRI2Attachment',0), 'FrontLeft');
ok ($X->interp('DRI2Attachment',1), 'BackLeft');
ok ($X->interp('DRI2Attachment',2), 'FrontRight');
ok ($X->interp('DRI2Attachment',3), 'BackRight' );
ok ($X->interp('DRI2Attachment',4), 'Depth');
ok ($X->interp('DRI2Attachment',5), 'Stencil');
ok ($X->interp('DRI2Attachment',6), 'Accum');
ok ($X->interp('DRI2Attachment',7), 'FakeFrontLeft');
ok ($X->interp('DRI2Attachment',8), 'FakeFrontRight');
ok ($X->interp('DRI2Attachment',9), 'DepthStencil');
ok ($X->interp('DRI2Attachment',10), 'Hiz');


#------------------------------------------------------------------------------
# DRI2QueryVersion()

{
  my $client_major = 1;
  my $client_minor = 2;
  my @ret = $X->DRI2QueryVersion ($client_major, $client_minor);
  MyTestHelpers::diag ("server DRI2 version ", join('.',@ret));
  ok (scalar(@ret), 2);
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# DRI2Connect

{
  my $window = $X->root;
  my $driver_type;
  foreach $driver_type ('DRI','VDPAU') {
    my @ret = $X->DRI2Connect ($window,'DRI');
    ok (scalar(@ret), 2);

    my ($driver, $device) = @ret;
    MyTestHelpers::diag ("connect $driver_type driver=\"",$driver,"\" device=\"",$device);
  }
}

#------------------------------------------------------------------------------
# DRI2Authenticate

{
  my $window = $X->root;
  my $token = 1234;
  my @ret = $X->DRI2Authenticate ($window,$token);
  ok (scalar(@ret), 1);
}


#------------------------------------------------------------------------------
# DRI2GetBuffers

{
  my $drawable = $X->root;
  my $attach_list;
  foreach $attach_list ([ ],
                           [ 'BackLeft' ],
                           [ 'BackLeft','Accum' ],
                          ) {
    my $num_attach = scalar(@$attach_list);
    my @ret = $X->robust_req ('DRI2GetBuffers', $drawable,@$attach_list);
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
          "DRI2GetBuffers return count ".scalar(@ret));
  }
}

# {
#   my $counter = $X->new_rsrc;
#   $X->DRI2CreateCounter ($counter, 123);
#   $X->QueryPointer($X->root); # sync
#   ok (1, 1, 'DRI2CreateCounter');
# 
#   my $value = $X->DRI2QueryCounter ($counter);
#   ok ($value, 123);
# 
#   foreach my $value (0, 1, -1,
#                      big_leftshift(1,32),
#                      - big_leftshift(1,32),
#                      big_leftshift(1,63) - 1,
#                      - big_leftshift(1,63),
#                     ) {
#     $X->DRI2SetCounter ($counter, $value);
#     my $got_value = $X->DRI2QueryCounter ($counter);
#     ok ($got_value == $value, 1,
#         "counter $value got $got_value");
#   }
# 
#   $X->DRI2DestroyCounter ($counter);
#   $X->QueryPointer($X->root); # sync
#   ok (1, 1, 'DRI2DestroyCounter');
# }

#------------------------------------------------------------------------------
# DRI2CreateAlarm / DRI2DestroyAlarm



# #------------------------------------------------------------------------------
# # DRI2CounterNotify event
# 
# {
#   my $aref = $X->{'ext'}->{'DRI2'};
#   my ($request_num, $event_num, $error_num, $obj) = @$aref;
# 
#   my $more;
#   foreach $more (0, 1) {
#     my $time;
#     foreach $time ('CurrentTime', 103) {
#       my %input = (# can't use "name" on an extension event, at least in 0.56
#                    # name        => "DRI2CounterNotify",
#                    synthetic     => 1,
#                    code          => $event_num,
#                    sequence_number => 100,
# 
#                    counter       => 101,
#                    wait_value    => -123,
#                    counter_value => -256,
#                    time          => $time,
#                    count         => 6,
#                    destroyed     => 1,
#                   );
#       my $data = $X->pack_event(%input);
#       ok (length($data), 32);
# 
#       my %output = $X->unpack_event($data);
#       ### %output
# 
#       ok ($output{'code'},      $input{'code'});
#       ok ($output{'name'},      'DRI2CounterNotify');
#       ok ($output{'synthetic'}, $input{'synthetic'});
# 
#       ok ($output{'counter'},      $input{'counter'});
#       ok ($output{'wait_value'},   $input{'wait_value'});
#       ok ($output{'counter_value'},$input{'counter_value'});
#       ok ($output{'time'},         $input{'time'});
#       ok ($output{'count'},        $input{'count'});
#       ok ($output{'destroyed'},    $input{'destroyed'});
#     }
#   }
# }
# 
# #------------------------------------------------------------------------------
# # DRI2AlarmNotify event
# 
# {
#   my $aref = $X->{'ext'}->{'DRI2'};
#   my ($request_num, $event_num, $error_num, $obj) = @$aref;
#   my $alarm_event_num = $event_num + 1;
# 
#   my $more;
#   foreach $more (0, 1) {
#     my $time;
#     foreach $time ('CurrentTime', 103) {
#       my %input = (# can't use "name" on an extension event, at least in 0.56
#                    # name          => "DRI2AlarmNotify",
#                    synthetic       => 1,
#                    code            => $alarm_event_num,
#                    sequence_number => 100,
# 
#                    alarm         => 101,
#                    counter_value => -123,
#                    alarm_value   => -256,
#                    time          => $time,
#                    state         => 'Destroyed',
#                   );
#       my $data = $X->pack_event(%input);
#       ok (length($data), 32);
# 
#       my %output = $X->unpack_event($data);
#       ### %output
# 
#       ok ($output{'code'},      $input{'code'});
#       ok ($output{'name'},      'DRI2AlarmNotify');
#       ok ($output{'synthetic'}, $input{'synthetic'});
# 
#       ok ($output{'alarm'},         $input{'alarm'});
#       ok ($output{'counter_value'}, $input{'counter_value'});
#       ok ($output{'alarm_value'},   $input{'alarm_value'});
#       ok ($output{'time'},          $input{'time'});
#       ok ($output{'state'},         $input{'state'});
#     }
#   }
# }


#------------------------------------------------------------------------------

exit 0;
