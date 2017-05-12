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

my $test_count = (tests => 90)[1];
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
  = $X->QueryExtension('DAMAGE');
{
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no DAMAGE on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("DAMAGE extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('DAMAGE')) {
  die "QueryExtension says DAMAGE avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# "Damage" error

{
  ok ($X->num('Error','Damage'),     $first_error);
  ok ($X->num('Error',$first_error), $first_error);
  ok ($X->interp('Error',$first_error), 'Damage');
  {
    local $X->{'do_interp'} = 0;
    ok ($X->interp('Error',$first_error), $first_error);
  }
}


#------------------------------------------------------------------------------
# DamageReportLevel enum

{
  ok ($X->num('DamageReportLevel','RawRectangles'),   0);
  ok ($X->num('DamageReportLevel','DeltaRectangles'), 1);
  ok ($X->num('DamageReportLevel','BoundingBox'),     2);
  ok ($X->num('DamageReportLevel','NonEmpty'),        3);

  ok ($X->num('DamageReportLevel',0), 0);
  ok ($X->num('DamageReportLevel',1), 1);
  ok ($X->num('DamageReportLevel',2), 2);
  ok ($X->num('DamageReportLevel',3), 3);

  ok ($X->interp('DamageReportLevel',0), 'RawRectangles');
  ok ($X->interp('DamageReportLevel',1), 'DeltaRectangles');
  ok ($X->interp('DamageReportLevel',2), 'BoundingBox');
  ok ($X->interp('DamageReportLevel',3), 'NonEmpty');
}


#------------------------------------------------------------------------------
# DamageQueryVersion

{
  my $client_major = 1;
  my $client_minor = 1;
  my @ret = $X->DamageQueryVersion ($client_major, $client_minor);
  MyTestHelpers::diag ("server DAMAGE version ", join('.',@ret));
  ok (scalar(@ret), 2);
  ok ($ret[0] <= $client_major, 1);
}
  $X->QueryPointer($X->root); # sync

#------------------------------------------------------------------------------
# DamageCreate / DamageDestroy

{
  my $level;
  foreach $level ('RawRectangles',
                  'DeltaRectangles',
                  'BoundingBox',
                  'NonEmpty') {
    my $damage = $X->new_rsrc;
    $X->DamageCreate ($damage, $X->root, $level);
    $X->DamageDestroy ($damage);
    $X->QueryPointer($X->root); # sync
    ok (1, 1, 'DamageCreate / DamageDestroy');
  }
}

#------------------------------------------------------------------------------
# DamageNotify event

{
  my $aref = $X->{'ext'}->{'DAMAGE'};
  my ($request_num, $event_num, $error_num, $obj) = @$aref;

  my $more;
  foreach $more (0, 1) {
    my $time;
    foreach $time ('CurrentTime', 103) {
      my %input = (# can't use "name" on an extension event, at least in 0.56
                   # name      => "DamageNotify",
                   synthetic => 1,
                   code      => $event_num,
                   sequence_number => 100,
                   damage   => 101,
                   drawable => 102,
                   level    => 'BoundingBox',
                   more     => $more,
                   time     => $time,
                   area     => [-104,-105,106,107],
                   geometry => [108,109,110,111]);
      my $data = $X->pack_event(%input);
      ok (length($data), 32);

      my %output = $X->unpack_event($data);
      ### %output

      ok ($output{'code'},      $input{'code'});
      ok ($output{'name'},      'DamageNotify');
      ok ($output{'synthetic'}, $input{'synthetic'});
      ok ($output{'damage'},    $input{'damage'});
      ok ($output{'drawable'},  $input{'drawable'});
      ok ($output{'level'},     $input{'level'});
      ok ($output{'more'},      $input{'more'});
      ok ($output{'time'},      $input{'time'});

      ok ($output{'area'}->[0], $input{'area'}->[0]);
      ok ($output{'area'}->[1], $input{'area'}->[1]);
      ok ($output{'area'}->[2], $input{'area'}->[2]);
      ok ($output{'area'}->[3], $input{'area'}->[3]);

      ok ($output{'geometry'}->[0], $input{'geometry'}->[0]);
      ok ($output{'geometry'}->[1], $input{'geometry'}->[1]);
      ok ($output{'geometry'}->[2], $input{'geometry'}->[2]);
      ok ($output{'geometry'}->[3], $input{'geometry'}->[3]);
    }
  }
}


#------------------------------------------------------------------------------

exit 0;
