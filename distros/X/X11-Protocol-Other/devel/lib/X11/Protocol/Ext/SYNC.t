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

my $test_count = (tests => 158)[1];
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


#------------------------------------------------------------------------------
# Helpers.

# Return $b << $n, with $b converted to a Math::BigInt for the shift.
# No "<<" operator in old Math::BigInt, so this is implemented with "**".
sub big_leftshift {
  my ($b, $n) = @_;
  require Math::BigInt;
  return Math::BigInt->new("$b") * Math::BigInt->new(2) ** $n;
}


#------------------------------------------------------------------------------
# _hilo_to_int64()
# Note explicit stringizing to cope with old Math::BigInt.

MyTestHelpers::diag ("_INT_BITS() is ", X11::Protocol::Ext::SYNC::_INT_BITS());

{ my $ret = X11::Protocol::Ext::SYNC::_hilo_to_int64(0,1);
  $ret = "$ret";
  $ret =~ s/^\+//;
  ok ($ret == 1, 1);
}
{ my $ret = X11::Protocol::Ext::SYNC::_hilo_to_int64(0,0x8000_0000);
  $ret = "$ret";
  $ret =~ s/^\+//;
  ok ($ret, '2147483648');
}
{ my $ret = X11::Protocol::Ext::SYNC::_hilo_to_int64(0,0xFFFF_FFFF);
  $ret = "$ret";
  $ret =~ s/^\+//;
  ok ($ret, '4294967295');
}
{ my $ret = X11::Protocol::Ext::SYNC::_hilo_to_int64(0x8000_0000,3);
  $ret = "$ret";
  $ret =~ s/^\+//;
  ok ($ret, '-9223372036854775805');
}
{ my $ret = X11::Protocol::Ext::SYNC::_hilo_to_int64(0x1234_5678, 0x8765_4321);
  $ret = "$ret";
  $ret =~ s/^\+//;
  ok ($ret, '1311768467139281697');
}
{ my $ret = X11::Protocol::Ext::SYNC::_hilo_to_int64(0xFFFF_FFFF, 0xFFFF_FFFF);
  $ret = "$ret";
  $ret =~ s/^\+//;
  ok ($ret == -1, 1);
}

#------------------------------------------------------------------------------
# _int64_to_hilo()

{ my @ret = X11::Protocol::Ext::SYNC::_int64_to_hilo(0);
  ok (scalar(@ret), 2);
  ok ($ret[0] == 0, 1);
  ok ($ret[1] == 0, 1);
}
{ my @ret = X11::Protocol::Ext::SYNC::_int64_to_hilo(-1);
  ok (scalar(@ret), 2);
  ok ($ret[0] == 0xFFFF_FFFF, 1);
  ok ($ret[1] == 0xFFFF_FFFF, 1);
}
{ my $sv = big_leftshift(1,32);
  my @ret = X11::Protocol::Ext::SYNC::_int64_to_hilo($sv);
  ok (scalar(@ret), 2);
  ok ($ret[0] == 1, 1);
  ok ($ret[1] == 0, 1);
}
{ my $sv = big_leftshift(1,63) - 1;
  my @ret = X11::Protocol::Ext::SYNC::_int64_to_hilo($sv);
  ok (scalar(@ret), 2);
  ok ($ret[0] == 0x7FFF_FFFF, 1);
  ok ($ret[1] == 0xFFFF_FFFF, 1);
}
{ # -8000_0000 0000_0000
  my $sv = - big_leftshift(1,63);
  my @ret = X11::Protocol::Ext::SYNC::_int64_to_hilo($sv);
  ok (scalar(@ret), 2);
  ok ($ret[0] == 0x8000_0000, 1,  "-800..00 hi got $ret[0]");
  ok ($ret[1] == 0,           1);
}
{ # -4000_0000 0000_0001
  my $sv = - big_leftshift(1,62) - 1;
  my ($hi,$lo) = X11::Protocol::Ext::SYNC::_int64_to_hilo($sv);
  ok ($hi == 0xBFFF_FFFF, 1);
  ok ($lo == 0xFFFF_FFFF, 1);
}

{
  # -7FFF_FFFF FFFF_FFFF
  my $sv = - big_leftshift(1,63) + 1;
  my @ret = X11::Protocol::Ext::SYNC::_int64_to_hilo($sv);
  ok (scalar(@ret), 2);
  ok ($ret[0] == 0x8000_0000, 1,  "-7FF..FF hi got $ret[0]");
  ok ($ret[1] == 1,           1,  "-7FF..FF lo want 1 got $ret[0]");
  MyTestHelpers::diag ("sv=$sv   hi=$ret[0] lo=$ret[1]");
}

#------------------------------------------------------------------------------
# errors

{
  ok ($X->num('Error','Counter'),    $first_error);
  ok ($X->num('Error','Alarm'),      $first_error+1);
  ok ($X->num('Error',$first_error),   $first_error);
  ok ($X->num('Error',$first_error+1), $first_error+1);
  ok ($X->interp('Error',$first_error),   'Counter');
  ok ($X->interp('Error',$first_error+1), 'Alarm');
  {
    local $X->{'do_interp'} = 0;
    ok ($X->interp('Error',$first_error), $first_error);
    ok ($X->interp('Error',$first_error+1), $first_error+1);
  }
}


#------------------------------------------------------------------------------
# SyncTestType enum

ok ($X->num('SyncTestType','PositiveTransition'),   0);
ok ($X->num('SyncTestType','NegativeTransition'),   1);
ok ($X->num('SyncTestType','PositiveComparison'),   2);
ok ($X->num('SyncTestType','NegativeComparison'),   3);

ok ($X->interp('SyncTestType',0), 'PositiveTransition');
ok ($X->interp('SyncTestType',1), 'NegativeTransition');
ok ($X->interp('SyncTestType',2), 'PositiveComparison');
ok ($X->interp('SyncTestType',3), 'NegativeComparison');


#------------------------------------------------------------------------------
# SyncValueType enum

ok ($X->num('SyncValueType','Absolute'),   0);
ok ($X->num('SyncValueType','Relative'),   1);

ok ($X->interp('SyncValueType',0), 'Absolute');
ok ($X->interp('SyncValueType',1), 'Relative');


#------------------------------------------------------------------------------
# SyncAlarmState enum

ok ($X->num('SyncAlarmState','Active'),    0);
ok ($X->num('SyncAlarmState','Inactive'),  1);
ok ($X->num('SyncAlarmState','Destroyed'), 2);

ok ($X->interp('SyncAlarmState',0), 'Active');
ok ($X->interp('SyncAlarmState',1), 'Inactive');
ok ($X->interp('SyncAlarmState',2), 'Destroyed');


#------------------------------------------------------------------------------
# SyncCreateCounter / SyncDestroyCounter

{
  my $counter = $X->new_rsrc;
  $X->SyncCreateCounter ($counter, 123);
  $X->QueryPointer($X->root); # sync
  ok (1, 1, 'SyncCreateCounter');

  { my $value = $X->SyncQueryCounter ($counter);
    $value = "$value";
    $value =~ s/^\+//;
    ok ($value, 123);
  }

  { my $value;
    foreach $value (0, 1, -1,
                    big_leftshift(1,32),
                    - big_leftshift(1,32),
                    big_leftshift(1,63) - 1,
                    - big_leftshift(1,63),
                   ) {
      $X->SyncSetCounter ($counter, $value);
      my $got_value = $X->SyncQueryCounter ($counter);
      ok ($got_value == $value, 1,
          "counter $value got $got_value");
    }
  }

  $X->SyncDestroyCounter ($counter);
  $X->QueryPointer($X->root); # sync
  ok (1, 1, 'SyncDestroyCounter');
}

#------------------------------------------------------------------------------
# SyncCreateAlarm / SyncDestroyAlarm

{
  my $alarm = $X->new_rsrc;
  $X->SyncCreateAlarm ($alarm);

  $X->SyncDestroyAlarm ($alarm);
  $X->QueryPointer($X->root); # sync
  ok (1, 1, 'SyncCreateAlarm / SyncDestroyAlarm');
}

#------------------------------------------------------------------------------
# alarm parameters

{
  my $counter = $X->new_rsrc;
  $X->SyncCreateCounter ($counter, 123);
  my $alarm = $X->new_rsrc;
  $X->SyncCreateAlarm ($alarm, value => -123);

  { my %h = $X->SyncQueryAlarm ($alarm);
    ok ($h{'value'} == -123,                     1);
    ok ($h{'test_type'} eq 'PositiveComparison', 1);
    ok ($h{'value_type'} eq 'Absolute',          1);
    ok ($h{'delta'} == 1,          1);
    ok ($h{'events'} == 1,         1);
    ok ($h{'state'} eq 'Inactive', 1);

    # print $h{'delta'},"\n";
    # use Devel::Peek;
    # Dump($h{'delta'});
  }

  {
    $X->SyncChangeAlarm ($alarm,
                         test_type => 'NegativeComparison',
                         delta => -1);
    my %h = $X->SyncQueryAlarm ($alarm);
    ok ($h{'test_type'}, 'NegativeComparison');
    ok ($h{'delta'} == -1, 1);
  }
  {
    $X->SyncChangeAlarm ($alarm,
                         counter    => $counter,
                         value_type => 'Relative');
    my %h = $X->SyncQueryAlarm ($alarm);
    ok ($h{'counter'}, $counter);
  }
  {
    $X->SyncChangeAlarm ($alarm, value_type => 'Absolute');
    my %h = $X->SyncQueryAlarm ($alarm);
    ok ($h{'value_type'}, 'Absolute');
    ok ($h{'events'}, 1);
  }
  {
    $X->SyncChangeAlarm ($alarm, events => 0);
    my %h = $X->SyncQueryAlarm ($alarm);
    ok ($h{'events'}, 0);
  }

  $X->SyncDestroyAlarm ($alarm);
  $X->SyncDestroyCounter ($counter);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# SyncCounterNotify event

{
  my $aref = $X->{'ext'}->{'SYNC'};
  my ($request_num, $event_num, $error_num, $obj) = @$aref;

  my $more;
  foreach $more (0, 1) {
    my $time;
    foreach $time ('CurrentTime', 103) {
      my %input = (# can't use "name" on an extension event, in
                   # X11::Protocol 0.56
                   # name        => "SyncCounterNotify",
                   synthetic     => 1,
                   code          => $event_num,
                   sequence_number => 100,

                   counter       => 101,
                   wait_value    => -123,
                   counter_value => -256,
                   time          => $time,
                   count         => 6,
                   destroyed     => 1,
                  );
      my $data = $X->pack_event(%input);
      ok (length($data), 32);

      my %output = $X->unpack_event($data);
      ### %output

      ok ($output{'code'},      $input{'code'});
      ok ($output{'name'},      'SyncCounterNotify');
      ok ($output{'synthetic'}, $input{'synthetic'});

      ok ($output{'counter'},      $input{'counter'});
      ok ($output{'wait_value'},   $input{'wait_value'});
      ok ($output{'counter_value'},$input{'counter_value'});
      ok ($output{'time'},         $input{'time'});
      ok ($output{'count'},        $input{'count'});
      ok ($output{'destroyed'},    $input{'destroyed'});
    }
  }
}

#------------------------------------------------------------------------------
# SyncAlarmNotify event

{
  my $aref = $X->{'ext'}->{'SYNC'};
  my ($request_num, $event_num, $error_num, $obj) = @$aref;
  my $alarm_event_num = $event_num + 1;

  my $more;
  foreach $more (0, 1) {
    my $time;
    foreach $time ('CurrentTime', 103) {
      my %input = (# can't use "name" on an extension event, in
                   # X11::Protocol 0.56
                   # name          => "SyncAlarmNotify",
                   synthetic       => 1,
                   code            => $alarm_event_num,
                   sequence_number => 100,

                   alarm         => 101,
                   counter_value => -123,
                   alarm_value   => -256,
                   time          => $time,
                   state         => 'Destroyed',
                  );
      my $data = $X->pack_event(%input);
      ok (length($data), 32);

      my %output = $X->unpack_event($data);
      ### %output

      ok ($output{'code'},      $input{'code'});
      ok ($output{'name'},      'SyncAlarmNotify');
      ok ($output{'synthetic'}, $input{'synthetic'});

      ok ($output{'alarm'},         $input{'alarm'});
      ok ($output{'counter_value'}, $input{'counter_value'});
      ok ($output{'alarm_value'},   $input{'alarm_value'});
      ok ($output{'time'},          $input{'time'});
      ok ($output{'state'},         $input{'state'});
    }
  }
}


#------------------------------------------------------------------------------
# SyncSetPriority / SyncGetPriority

{
  $X->SyncSetPriority(0,123);
  ok ($X->SyncGetPriority(0), 123);

  $X->SyncSetPriority("None",-123);
  ok ($X->SyncGetPriority(0), -123);

  $X->SyncSetPriority(0,0);
  ok ($X->SyncGetPriority(0), 0);

  # second client connection
  my $X2 = X11::Protocol->new ($display);
  my $pixmap2 = $X2->new_rsrc;
  $X2->CreatePixmap($pixmap2, $X2->root, 1, 1,1);
  $X2->QueryPointer($X->root); # sync

  $X->SyncSetPriority($pixmap2, 456);
  ok ($X->SyncGetPriority($pixmap2), 456);
  ok ($X2->SyncGetPriority(0), 456);
  ok ($X->SyncGetPriority(0), 0);

  my $pixmap = $X->new_rsrc;
  $X->CreatePixmap($pixmap, $X2->root, 1, 1,1);
  ok ($X->SyncGetPriority($pixmap), 0);
  $X->FreePixmap($pixmap);
}


#------------------------------------------------------------------------------

exit 0;
