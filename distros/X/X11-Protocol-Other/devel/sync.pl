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

use 5.004;
use strict;

# uncomment this to run the ### lines
# use Smart::Comments;

# use lib 'devel/lib';
# $ENV{'DISPLAY'} ||= ":0";

{
  # fence
  # xvfb-run --auto-servernum --server-args="-screen 0 640x480x24 -screen 1 1024x768x24" sh -c 'icewm & sleep 2; DISPLAY=$DISPLAY.1 perl -I ../lib sync.pl'

  # xvfb-run --auto-servernum --server-args="-screen 0 640x480x24 -screen 1 1024x768x24" sh -c 'icewm & sleep 2; DISPLAY=$DISPLAY.1 perl -I ../lib sync.pl'

  require X11::Protocol;
  my $X = X11::Protocol->new;
  if (! $X->init_extension('SYNC')) {
    print "No SYNC on the server\n";
    exit 0;
  }
  $X->choose_screen(1);

  my $fence = $X->new_rsrc;
  ### $fence
  $X->SyncCreateFence ($fence, $X->root, 0);
  $X->flush;
  $X->handle_input;
  # $X->QueryPointer($X->root); # sync

  exit 0;
}

{
  # taint
  require Devel::Peek;

  my $tainted;
  sysread(STDIN,$tainted,0);
  $tainted .= '0';
  Devel::Peek::Dump ($tainted);
  $tainted += 0;

  my $lo = 0xFFFF_FFFF;
  ### $lo
  Devel::Peek::Dump ($lo);
  $lo += $tainted;
  ### $lo
  Devel::Peek::Dump ($lo);

  $lo = -(1<<63) + $lo;
  ### $lo
  Devel::Peek::Dump ($lo);
  exit;
}

{
  # taint
  require Devel::Peek;
  require Taint::Util;

  my $lo = 0xFFFF_FFFF;
  Taint::Util::taint($lo);
  ### $lo
  Devel::Peek::Dump ($lo);

  my $s = -(1<<63) + $lo;
  ### $s
  Devel::Peek::Dump ($s);
  exit;
}

{
  # taint
  require Devel::Peek;
  require Taint::Util;

  my $lo = 0xFFFF_FFFF;
  ### $lo
  Taint::Util::taint($lo);
  ### $lo
  $lo *= 2;
  $lo += 1;
  ### $lo
  Devel::Peek::Dump ($lo);
  exit;
  my $x = -(1<<63);
  ### $x
  Devel::Peek::Dump ($x);
  $lo += $x;
  ### $lo
  Devel::Peek::Dump ($lo);
  exit;

}
{
  # counter

  require X11::Protocol;
  my $X = X11::Protocol->new;
  if (! $X->init_extension('SYNC')) {
    print "No SYNC on the server\n";
    exit 0;
  }

  my $counter = $X->new_rsrc;
  $X->SyncCreateCounter ($counter, 123);
  $X->QueryPointer($X->root); # sync
  ### $counter

  { my $value = $X->SyncQueryCounter ($counter);
    ### $value
  }

  $X->SyncSetCounter ($counter, -1);
  { my $value = $X->SyncQueryCounter ($counter);
    ### $value
  }

  exit 0;
}

{
  # IDLETIME from SYNC and from MIT-SCREEN-SAVER

  my $X = X11::Protocol->new;
  if (! $X->init_extension('SYNC')) {
    print "No SYNC on the server\n";
    exit 0;
  }
  if (! $X->init_extension('MIT-SCREEN-SAVER')) {
    print STDERR "MIT-SCREEN-SAVER extension not available\n";
    exit 1;
  }

  my @infos = $X->SyncListSystemCounters;
  my $num_infos = scalar(@infos);
  print "total $num_infos system counters\n";

  foreach my $elem (@infos) {
    my ($counter, $resolution, $name) = @$elem;
    my $value = $X->SyncQueryCounter($counter);
    print "counter=$counter resolution=$resolution \"$name\"  value=$value\n";
  }

  {
     my ($state, $window, $til_or_since, $idle, $event_mask, $kind)
       = $X->MitScreenSaverQueryInfo ($X->root);
    ### $state
    ### $til_or_since
    ### $idle
  }
  exit 0;
}

{
  # _int64_to_hilo() divisions

  require Math::BigInt;
  require X11::Protocol::Ext::SYNC;

  my $sv = - Math::BigInt->new(1) * Math::BigInt->new(2) ** 63 + 1;
  print "sv $sv ",ref $sv,"\n";

  my $d = 2**16;
  {
    my ($q,$r) = $sv->bdiv($d);
    print "q $q\n";
    print "r $r\n";

    my $rem = $sv % $d;
    print "rem $rem ",ref $rem,"\n";
    my $sub = $sv - $rem;
    print "sub $sub ",ref $sub,"\n";
    my $quot = $sub/$d;
    print "quot $quot ",ref $quot,"\n";
    my $int = int($quot);
    print "int $int ",ref $int,"\n";
    my $p = $quot*$d + $rem;
    my $diff = $sv - $p;
    print "p $p ",ref $p,"  diff=$diff\n";

  }

  my ($h,$l) = X11::Protocol::Ext::SYNC::_int64_to_hilo($sv);
  print "h=$h l=$l\n";

  ($sv, my $lo) = X11::Protocol::Ext::SYNC::_divrem($sv,65536);
  print "lo $lo ",ref $lo,"\n";
  print "sv $sv ",ref $sv,"\n";

  ($sv, my $lo2) = X11::Protocol::Ext::SYNC::_divrem($sv,65536);
  print "lo2 $lo2 ",ref $lo2,"\n";
  print "sv $sv ",ref $sv,"\n";

  ($sv, my $hi) = X11::Protocol::Ext::SYNC::_divrem($sv,65536);
  print "hi $hi\n";
  print "sv $sv ",ref $sv,"\n";
  my $hi2 = $sv % 65536;
  print "hi2 $hi2\n";
  $hi += 65536*$hi2;

  exit 0;
}

exit 0;




# # The Math::BigInt which comes with Perl 5.6.0 has some dodginess.  bdiv(),
# # "/" and "%" return only strings, and the remainder doesn't always seem to
# # be positive.  Skip tests there.
# #
# my $q = Math::BigInt->new(2)**64 / 65536;
# my $bigint_quot_is_bigint = ref $q;
# if (! $bigint_quot_is_bigint) {
#   MyTestHelpers::diag ("BigInt division doesn't return BigInt object, only number string");
# }
#   my $skip = ($bigint_quot_is_bigint
#               ? undef
#               : "due to BigInt division doesn't return BigInt, only number string");
