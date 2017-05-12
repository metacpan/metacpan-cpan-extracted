#!/usr/bin/perl -w

# Copyright 2011, 2013 Kevin Ryde

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

my $test_count = (tests => 9)[1];
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
    = $X->QueryExtension('X-Resource');
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('server QueryExtension() has no X-Resource', 1, 1);
    }
    exit 0;
  }
}

if (! $X->init_extension ('X-Resource')) {
  die "QueryExtension says X-Resource avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync

MyTestHelpers::diag (sprintf 'resource_id_base %#X', $X->resource_id_base);


#------------------------------------------------------------------------------
# XResourceQueryVersion

{
  my $client_major = 1;
  my $client_minor = 0;
  my @ret = $X->XResourceQueryVersion ($client_major, $client_minor);
  MyTestHelpers::diag ("server X-Resource version ", join('.',@ret));
  ok (scalar(@ret), 2);
  ok ($ret[0] <= 1, 1);
}

#------------------------------------------------------------------------------
# XResourceQueryClients

{
  my @clients = $X->XResourceQueryClients;
  ### @clients
  my $good = 1;
  my $elem;
  foreach $elem (@clients) {
    if (! ref $elem) {
      MyTestHelpers::diag ('XResourceQueryClients element not an arrayref');
      $good = 0;
    } elsif (@$elem != 2) {
      MyTestHelpers::diag ('XResourceQueryClients element not length 2');
      $good = 0;
    } elsif (! ($elem->[0] =~ /^\d+/ && $elem->[1] =~ /^\d+/)) {
      MyTestHelpers::diag ("XResourceQueryClients element not an integer: '$elem->[0]' '$elem->[1]'");
      $good = 0;
    }
  }
  ok ($good, 1, 'XResourceQueryClients checks');
}
$X->QueryPointer($X->{'root'}); # sync

#------------------------------------------------------------------------------
# XResourceQueryClientResources

{
  my $xid = $X->{'resource_id_base'};
  my @ret = $X->XResourceQueryClientResources ($xid);
  ok (scalar(@ret)&1, 0, 'XResourceQueryClientResources even length list');
  my $good = 1;
  my $elem;
  foreach $elem (@ret) {
    if ($elem !~ /^\d+/) {
      MyTestHelpers::diag ("XResourceQueryClientResources element not an integer: '$elem'");
      $good = 0;
    }
  }

  my %resources = (@ret);
  my $atom;
  foreach $atom (keys %resources) {
    $X->GetAtomName($atom);
  }
  ok (1,1, 'XResourceQueryClientResources atoms pass GetAtomName');
}
$X->QueryPointer($X->{'root'}); # sync


#------------------------------------------------------------------------------
# XResourceQueryClientPixmapBytes unpack

{
  my $data = pack 'x8LL', 123, 3;
  my $got = $X->unpack_reply('XResourceQueryClientPixmapBytes', $data);
  my $want = 3 * (2.0**32) + 123;
  ok ($got == $want, 1, "XResourceQueryClientPixmapBytes with bytes_overflow==3");
  MyTestHelpers::diag("35-bit type is ",ref($got)||'number');
}
{
  my $data = pack 'x8LL', 0xFFFFFFFF, 0xFFFFFFFF;
  my $got = $X->unpack_reply('XResourceQueryClientPixmapBytes', $data);
  my $want = '18446744073709551615';
  ok ($got == $want, 1,
      "XResourceQueryClientPixmapBytes with bytes_overflow=0xFFFFFFFF");
  MyTestHelpers::diag("64-bit FFs ref type is ",ref($got)||'number');
}

#------------------------------------------------------------------------------
# XResourceQueryClientPixmapBytes request

{
  my $xid = $X->{'resource_id_base'};
  my @ret = $X->XResourceQueryClientPixmapBytes ($xid);
  ok (scalar(@ret), 1,
      'XResourceQueryClientPixmapBytes one return value');
  ok (!!($ret[0] =~ /^\d$/), 1,
      'XResourceQueryClientPixmapBytes return an integer');
}
$X->QueryPointer($X->{'root'}); # sync

exit 0;
