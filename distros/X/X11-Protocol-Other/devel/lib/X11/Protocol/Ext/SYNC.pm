# Copyright 2011, 2012, 2013, 2014, 2017 Kevin Ryde

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
package X11::Protocol::Ext::SYNC;
use strict;
use Carp;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 31;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
# use Smart::Comments;

# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
#
# SYNC 3.1
#    /usr/share/doc/x11proto-xext-dev/sync.txt.gz
#
#    /usr/include/X11/extensions/syncproto.h
#    /usr/include/X11/extensions/syncconst.h
#    /usr/include/X11/extensions/syncstr.h
#
#    /usr/include/X11/extensions/sync.h
#    /usr/share/X11/doc/hardcopy/Xext/synclib.PS.gz
#    /so/xorg/libXext-1.2.0/src/XSync.c
#    /so/xorg/libXext-1.2.0/specs/synclib.xml
#       Xlib
#    /usr/share/xcb/sync.xml
#       xcb
#
#    /so/xorg/xorg-server-1.10.0/Xext/sync.c
#       server source
#
# X11R7.6 SYNC 3.0, no Fence
#    /so/xorg/sync-3.0/sync.txt
#    /so/x11r6.4/xc/include/extensions/sync.h
#    /so/x11r6.4/xc/include/extensions/syncstr.h
#    /so/x11r6.4/xc/programs/Xserver/Xext/sync.c
#
#    /so/xfree/xfree86-3.3.2.3a/include/extensions/sync.h
#    /so/xfree/xfree86-3.3.2.3a/include/extensions/syncstr.h
#    /so/xfree/xfree86-3.3.2.3a/programs/Xserver/Xext/sync.c
#
#    /so/x11r2/X.V11R2/lib/X/XSync.c
#       Xlib

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 3;
use constant CLIENT_MINOR_VERSION => 1;

#------------------------------------------------------------------------------
# symbolic constants

use constant constants_list =>
  (
   SyncValueType  => ['Absolute', 'Relative' ],
   SyncTestType   => [ 'PositiveTransition','NegativeTransition',
                       'PositiveComparison','NegativeComparison' ],
   SyncAlarmState => ['Active', 'Inactive', 'Destroyed' ],
  );

sub _ext_constants_install {
  my ($X, $constants_arrayref) = @_;
  foreach (my $i = 0; $i <= $#$constants_arrayref; $i+=2) {
    my $name = $constants_arrayref->[$i];
    my $aref = $constants_arrayref->[$i+1];
    $X->{'ext_const'}->{$name} = $aref;
    $X->{'ext_const_num'}->{$name} = { X11::Protocol::make_num_hash($aref) };
  }
}

#------------------------------------------------------------------------------
# events

use constant events_list =>
  (SyncCounterNotify =>
   [ sub {
       my $X = shift;
       my $data = shift;

       my ($counter,
           $wait_value_hi, $wait_value_lo,
           $counter_value_hi,$counter_value_lo,
           $time,
           $count,
           $destroyed)
         = unpack 'xxxxLLLLLLSCx', $data;
       return
         (@_,
          counter       => $counter,
          wait_value    => _hilo_to_int64($wait_value_hi,$wait_value_lo),
          counter_value => _hilo_to_int64($counter_value_hi,$counter_value_lo),
          time          => _interp_time($time),
          count         => $count,
          destroyed     => $destroyed);
     },
     sub {
       my ($X, %h) = @_;
       return (pack('xxxxLLLLLLSCx',
                    $h{'counter'},
                    _int64_to_hilo($h{'wait_value'}),
                    _int64_to_hilo($h{'counter_value'}),
                    _num_time($h{'time'}),
                    $h{'count'},
                    $h{'destroyed'}),
               1); # "do_seq" put in sequence number
     } ],

   SyncAlarmNotify =>
   [ sub {
       my $X = shift;
       my $data = shift;

       my ($alarm,
           $counter_value_hi,$counter_value_lo,
           $alarm_value_hi, $alarm_value_lo,
           $time,
           $state)
         = unpack 'xxxxLLLLLLCx3', $data;
       return
         (@_,
          alarm         => $alarm,
          counter_value => _hilo_to_int64($counter_value_hi,$counter_value_lo),
          alarm_value   => _hilo_to_int64($alarm_value_hi,$alarm_value_lo),
          time          => _interp_time($time),
          state         => $X->interp('SyncAlarmState',$state));
     },
     sub {
       my ($X, %h) = @_;
       return (pack('xxxxLLLLLLCx3',
                    $h{'alarm'},
                    _int64_to_hilo($h{'counter_value'}),
                    _int64_to_hilo($h{'alarm_value'}),
                    _num_time($h{'time'}),
                    $X->num('SyncAlarmState',$h{'state'})),
               1); # "do_seq" put in sequence number
     } ],
  );

sub _ext_events_install {
  my ($X, $event_num, $events_arrayref) = @_;
  foreach (my $i = 0; $i <= $#$events_arrayref; $i += 2) {
    my $name = $events_arrayref->[$i];
    if (defined (my $already = $X->{'ext_const'}->{'Events'}->[$event_num])) {
      carp "Event $event_num $already overwritten with $name";
    }
    $X->{'ext_const'}->{'Events'}->[$event_num] = $name;
    $X->{'ext_events'}->[$event_num] = $events_arrayref->[$i+1]; # pack/unpack
    $event_num++;
  }
}

#------------------------------------------------------------------------------

my $reqs =
  [
   # Version 3.0

   ['SyncInitialize',  # 0
    sub {
      my ($X, $major, $minor) = @_;
      return pack 'CCxx', $major, $minor;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8CC', $data;
    } ],

   ['SyncListSystemCounters',  # 1
    \&_request_empty,
    sub {
      my ($X, $data) = @_;
      ### SyncListSystemCounters reply(): length($data), $data
      my ($ncounters) = unpack 'x8L', $data;
      ### $ncounters
      my @ret;
      my $pos = 32;
      foreach (1 .. $ncounters) {
        ### at: $pos, substr($data,$pos)

        my ($counter, $resolution_hi, $resolution_lo, $name_len)
          = unpack 'LlLS', substr($data,$pos,14); # 4+8+2=14
        ### elem: [ $counter, $resolution_hi, $resolution_lo, $name_len ]
        $pos += 14;

        my $name = substr ($data, $pos, $name_len);
        $pos += $name_len;
        $pos += X11::Protocol::padding($pos);

        push @ret, [ $counter,
                     _hilo_to_int64($resolution_hi,$resolution_lo),
                     $name ];
      }
      return @ret;
    }],

   ['SyncCreateCounter',  # 2
    sub {
      my ($X, $counter, $initial) = @_;
      return pack 'L3', $counter, _int64_to_hilo($initial);
    },
   ],

   ['SyncSetCounter',  # 3
    sub {
      my ($X, $counter, $value) = @_;
      ### SyncSetCounter() ...
      return pack 'L3', $counter, _int64_to_hilo($value);
    },
   ],

   ['SyncChangeCounter',  # 4
    sub {
      my ($X, $counter, $value) = @_;
      return pack 'L3', $counter, _int64_to_hilo($value);
    },
   ],

   ['SyncQueryCounter',  # 5
    \&_request_card32s, # ($X, $counter)
    sub {
      my ($X, $data) = @_;
      return _hilo_to_int64 (unpack 'x8LL', $data);
    },
   ],

   ['SyncDestroyCounter',  # 6
    \&_request_card32s, # ($X, $counter)
   ],

   ['SyncAwait',  # 7
    \&_request_empty,
   ],

   ['SyncCreateAlarm',  # 8
    \&_request_alarm_parameters,
   ],

   ['SyncChangeAlarm',  # 9
    \&_request_alarm_parameters,
   ],

   ['SyncQueryAlarm',  # 10
    \&_request_card32s, # ($X, $alarm)
    sub {
      my ($X, $data) = @_;
      ### SyncQueryAlarm() reply ...

      # use Data::HexDump::XXD;
      # print scalar(Data::HexDump::XXD::xxd($data));
      # print "\n";

      my ($counter, $value_type, $value_hi,$value_lo,
          $test_type, $delta_hi,$delta_lo,
          $events, $state)
        = unpack 'x8L7CC', $data;

      return (counter    => $counter,
              value      => _hilo_to_int64($value_hi,$value_lo),
              test_type  => $X->interp('SyncTestType',$test_type),
              value_type => $X->interp('SyncValueType',$value_type),
              delta      => _hilo_to_int64($delta_hi,$delta_lo),
              events     => $events,
              state      => $X->interp('SyncAlarmState',$state));
    } ],

   ['SyncDestroyAlarm',  # 11
    \&_request_card32s, # ($X, $alarm)
   ],

   ['SyncSetPriority',  # 12
    sub {
      my ($X, $xid, $priority) = @_;
      return pack 'Ll', _num_none($xid), $priority;
    }],
   ['SyncGetPriority',  # 13
    \&_request_xids, # ($X, $xid)
    sub {
      my ($X, $data) = @_;
      return unpack 'x8l', $data;
    }],

   #------------------------
   # version 3.1

   ['SyncCreateFence',  # 14
    sub {
      my ($X, $fence, $drawable, $initially_triggered) = @_;
      return pack 'LLCxxx', $drawable, $fence, $initially_triggered;
    }],

   ['SyncTriggerFence',  # 15
    \&_request_card32s, # ($X, $fence)
   ],

   ['SyncResetFence',  # 16
    \&_request_card32s, # ($X, $fence)
   ],

   ['SyncDestroyFence',  # 17
    \&_request_card32s, # ($X, $fence)
   ],

   ['SyncQueryFence',  # 18
    \&_request_card32s, # ($X, $fence)
    sub {
      my ($X, $data) = @_;
      return unpack 'x8C', $data;
    } ],

   ['SyncAwaitFence',  # 19
    \&_request_card32s, # ($X, $fence,...)
   ],
  ];

{
  my @keys = ('counter',
              'value_type',
              'value',
              'test_type',
              'delta',
              'events');
  my %key_to_conversion = (value => \&_int64_to_hilo,
                           delta => \&_int64_to_hilo);
  my %key_to_interp = (value_type => 'SyncValueType',
                       test_type  => 'SyncTestType');

  sub _request_alarm_parameters {
    my ($X, $alarm, %h) = @_;
    my $mask = 0;
    my @args;
    my $i;
    foreach $i (0 .. $#keys) {
      my $key = $keys[$i];
      next unless exists $h{$key};

      my $arg = delete $h{$key};
      $mask |= (1 << $i);

      if (my $conversion = $key_to_conversion{$key}) {
        push @args, &$conversion($arg);
      } else {
        if (my $interp = $key_to_interp{$key}) {
          $arg = $X->num($interp,$arg);
        }
        push @args, $arg;
      }
    }
    if (%h) {
      croak "Unrecognised alarm parameter(s): ",join(',',keys %h);
    }
    ### $mask
    ### @args
    return pack 'L*', $alarm, $mask, @args;
  }
}


#------------------------------------------------------------------------------

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### Sync new()

  my $self = bless { }, $class;
  _ext_requests_install ($X, $request_num, $reqs);
  _ext_constants_install ($X, [ $self->constants_list ]);
  _ext_events_install ($X, $event_num, [ $self->events_list ]);

  # SYNC spec says must initialize or behaviour undefined (though for
  # example the X.org server doesn't enforce this).  Also we want to know
  # whether 3.0 or 3.1 so that the Fence error type can be setup or not.
  #
  my ($major, $minor) = $X->req('SyncInitialize',
                                CLIENT_MAJOR_VERSION,
                                CLIENT_MINOR_VERSION);
  $self->{'major'} = $major;
  $self->{'minor'} = $minor;

  # Errors
  _ext_const_error_install ($X, $error_num,
                            'Counter',  # 0
                            'Alarm',    # 1

                            # Fence new in 3.1
                            (($major <=> 3 || $minor <=> 1) >= 0
                             ? ('Fence') : ()));   # 2
  return $self;
}


#------------------------------------------------------------------------------
# generic

sub _num_time {
  my ($time) = @_;
  if (defined $time && $time eq 'CurrentTime') {
    return 0;
  } else {
    return $time;
  }
}
sub _interp_time {
  my ($time) = @_;
  if ($time == 0) {
    return 'CurrentTime';
  } else {
    return $time;
  }
}

sub _num_none {
  my ($xid) = @_;
  if (defined $xid && $xid eq "None") {
    return 0;
  } else {
    return $xid;
  }
}


sub _ext_requests_install {
  my ($X, $request_num, $reqs) = @_;

  $X->{'ext_request'}->{$request_num} = $reqs;
  my $href = $X->{'ext_request_num'};
  my $i;
  foreach $i (0 .. $#$reqs) {
    $href->{$reqs->[$i]->[0]} = [$request_num, $i];
  }
}
sub _ext_const_error_install {
  my $X = shift;  # ($X, $errname1,$errname2,...)
  ### _ext_const_error_install: @_
  my $error_num = shift;
  my $aref = $X->{'ext_const'}{'Error'}  # copy
    = [ @{$X->{'ext_const'}{'Error'} || []} ];
  my $href = $X->{'ext_const_num'}{'Error'}  # copy
    = { %{$X->{'ext_const_num'}{'Error'} || {}} };
  my $i;
  foreach $i (0 .. $#_) {
    $aref->[$error_num + $i] = $_[$i];
    $href->{$_[$i]} = $error_num + $i;
  }
}

sub _request_empty {
  # ($X)
  if (@_ > 1) {
    croak "No parameters in this request";
  }
  return '';
}
sub _request_card32s {
  shift;
  ### _request_card32s(): @_
  return pack 'L*', @_;
}
sub _request_xids {
  my $X = shift;
  ### _request_xids(): @_
  return _request_card32s ($X, map {_num_none($_)} @_);
}

#------------------------------------------------------------------------------
# 64-bits

# -2^64 + $hi*2^32 + $lo
# = 2^32 * (-2^32 + $hi) + $lo
#
# -2^64 + $hi*2^32 + $lo
# = -2^64 + ($hi-2^31+2^31)*2^32 + $lo
# = -2^64 + 2^63 + ($hi-2^31)*2^32 + $lo
# = -2^63 + ($hi-2^31)*2^32 + $lo
#
# Crib: "<<" shift operator turns a negative into a positive, so must shift
# $hi as positive then adjust.

use constant _INT_BITS => do {
  # In Perl 5.14.2 with -T taint mode, $lo += -(1<<63) becomes an NV not a
  # UV making the int64 return lose precision.  $lo is tainted by being a
  # value read from the server.  Not sure what can be relied on for integer
  # arithmetic in taint mode, but for now treat it as 32-bit Perl.

  # $n = tainted zero.  It's assumed there will be something in %ENV which
  # is tainted.  Normally everything in %ENV is tainted, but it's not
  # uncommon to wash $PATH.  Could use Taint::Util::taint(), but don't
  # really want to demand that module.
  my $n = '0' . join ('', map {defined $_ && substr($_,0,0)} values %ENV);

  my $bits = 0;
  for (;;) {
    $bits++;
    $n *= 2;
    my $n2 = $n;
    $n += 1;
    if ($n <= $n2 || $n >= $n2 + 2) {
      # floating point round-off, stop
      last;
    }
    if ($bits >= 64) {
      # enough good bits for our purposes, stop
      last;
    }
  }
  ### $bits
  # Devel::Peek::Dump ($n);
  $bits;
};

if (_INT_BITS >= 64) {
  ### 64-bit UV ...

  eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;
sub _hilo_to_int64 {
  my ($hi,$lo) = @_;
  ### _hilo_to_int64() ...
  ### $hi
  ### $lo
  if ($hi & 0x8000_0000) {
    $hi -= 0x8000_0000;
    $lo += -(1<<63);
    ### twos-complement negative to ...
    ### $hi
    ### $lo
    ### lo hex: sprintf '%X', $lo
  }
  ### hi shift: $hi<<1
  ### result: ($hi << 32) + $lo
  return ($hi << 32) + $lo;
}
1;
HERE
} else {
  ### 32-bit UV (or anything less than 64) ...

  eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;
use Math::BigInt;
sub _hilo_to_int64 {
  my ($hi,$lo) = @_;
  # print "_hilo_to_int64() hi=$hi lo=$lo\n";

  my $ret = Math::BigInt->new("$hi") * (Math::BigInt->new(2) ** 32) + $lo;
  if ($hi & 0x8000_0000) {
    $ret -= Math::BigInt->new(2) ** 64;
  }
  ### $ret
  return $ret;
}
1;
HERE
}

# NV floats are converted to UV for bitwise ">>" or "&", which would lose
# some of the mantissa if UV==32bits, so use "%".
#
# Divisor 2^32 would be an NV float if UV==32bits, so do two divisions by
# 65536.
#
# Math::BigInt in perl 5.6.0 has a bug in the division where it mis-handles
# the sign of the dividend, giving for example -16 div 8 = -1 rem +7, where
# it should be -2 rem +1 (or perhaps -1 rem -7 if a negative remainder).
# Avoid that by making $sv positive and bit-invert the resulting $hi,$lo.
#
# For reference, Math::BigInt in perl 5.6.0 had int() returning a plain
# string, not a BigInt object, so avoid that.
#
sub _int64_to_hilo {
  my ($sv) = @_;
  ### _int64_to_hilo(): $sv
  # print "_int64_to_hilo() sv=$sv ",(ref $sv || '[plain scalar]'),"\n";

  my $xor = 0;
  if ($sv < 0) {
    $sv = -1 - $sv;
    $xor = 0xFFFF;
  }

  ($sv, my $lo) = _divrem($sv,65536);
  $lo ^= $xor;
  ($sv, my $lo2) = _divrem($sv,65536);
  $lo2 ^= $xor;
  $lo += 65536*$lo2;

  ($sv, my $hi) = _divrem($sv,65536);
  $hi ^= $xor;
  ($sv, my $hi2) = _divrem($sv,65536);
  $hi2 ^= $xor;
  $hi += 65536*$hi2;

  ### $hi
  ### $lo
  return ($hi, $lo)
}

sub _divrem {
  my ($n, $d) = @_;
  my $rem = $n % $d;
  return (($n-$rem)/$d, $rem);
}

1;
__END__

=for stopwords SYNC XID Ryde Pre-defined SERVERTIME timestamp IDLETIME BigInts arrayref ie unsatisfy untriggered XIDs builtin ENUM SyncValueType SyncTestType SyncAlarmState

=head1 NAME

X11::Protocol::Ext::SYNC - inter-client synchronization

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('SYNC')
   or print "SYNC extension not available";

=head1 DESCRIPTION

The SYNC extension adds

=over

=item *

Counter objects, counting in 64-bits client controlled or server builtin.

=item *

Alarm objects to receive events for counter values.

=item *

Priority level for clients.

=item *

Fence objects triggered by completion of screen rendering.  New in SYNC
version 3.1.

=back

Counters and alarms allow multiple clients to synchronize their actions.
One client can create a counter and increment it.  Other clients can block
or receive events for desired target values.

Counter values are INT64 signed 64-bit integers, so -2^63 to +2^63-1
inclusive.  On a 64-bit Perl these values are returned as plain integers.
On a 32-bit Perl they're returned as C<Math::BigInt> objects.  For requests
values can be given as either integers, floating point, or BigInts.

=head2 Client Counters

Client counters are changed by C<SyncChangeCounter()> or C<SyncSetCounter()>
requests.  The meaning of a counter value and when and by how much it
changes is entirely up to client programs.

Client counters do not wrap-around.  If an increment overflows the -2^63 to
+2^63-1 range then a C<BadValue> results, or alarms becomes Inactive when
adding their C<delta> overflows the INT64 range.

=head2 System Counters

Pre-defined system counters are controlled by the server.  As of SYNC
specification 3.1 the only system counter always available is "SERVERTIME".
A particular server might have more.

=over

=item "SERVERTIME"

The server timestamp in milliseconds.  This is per the C<time> field of
server events etc.

=back

Recent versions of the X.org server (1.10 or thereabouts) have

=over

=item "IDLETIME"

The idle time in milliseconds, being the time since any device input.  This
is the same as the idle time in C<MitScreenSaverQueryInfo()> (see
L<X11::Protocol::Ext::MIT_SCREEN_SAVER>).

=back

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('SYNC');

=over

=item C<($server_major, $server_minor) = $X-E<gt>SyncInitialize ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like.  The returned
C<$server_major> and C<$server_minor> is what the server will do.

This negotiation request is made automatically in C<init_extension()> and
the SYNC spec says it should not be done again later.  The current module
code supports up to SYNC version 3.1 and that version is requested.  The
version the server returns is stored in the extension object,

    my $extobj = $X->{'ext'}->{'SYNC'}->[3];
    $major = $extobj->{'major'};
    $minor = $extobj->{'minor'};

=item C<@infos = $X-E<gt>SyncListSystemCounters ($client_major, $client_minor)>

Return a list of the server-defined counters.  Each return value is an
arrayref

    [ $counter, $resolution, $name ]

C<$counter> is the XID (an integer) of the counter.

C<$resolution> is an estimate of the granularity of the counter.  For
example if resolution is 10 then it might increment by 10 or thereabouts
each time.

C<$name> is a string name of the counter.

See F<examples/sync-info.pl> in the X11-Protocol-Other sources for a
complete program listing the system counters.

=item C<$X-E<gt>SyncCreateCounter ($counter, $value)>

Create C<$counter> (a new XID) as a counter with initial value C<$value> (an
INT64).

=item C<$X-E<gt>SyncSetCounter ($counter, $value)>

Set C<$counter> (an XID) to C<$value> (64-bit integer).  The server system
counters cannot be changed by clients.

=item C<$X-E<gt>SyncChangeCounter ($counter, $add)>

Change C<$counter> (an XID) by adding C<$add> (64-bit integer) to it.  The
server system counters cannot be changed by clients.

If C<$add> would make the resulting counter overflow a 64-bit integer then a
C<BadValue> error results.

=item C<$value = $X-E<gt>SyncQueryCounter ($counter)>

Return the current value of C<$counter> (an XID).

=item C<$X-E<gt>SyncDestroyCounter ($counter)>

Destroy C<$counter> (an XID).

Any clients currently waiting on C<$counter> are sent a C<SyncCounterNotify>
event with the C<destroyed> field true.  Any alarms on C<$counter> become
state "Inactive".  A client's counters are destroyed automatically on
connection close.  System counters cannot be destroyed.

=back

=head2 Alarms and Waiting

=over

=item C<$X-E<gt>SyncAwait ([$key=E<gt>$value,...],...)>

Block processing of further requests from the current client until one of
the given counter conditions is satisfied.  The call C<$X-E<gt>SyncAwait()>
returns immediately, but any further requests sent on C<$X> will not be read
by the server until the wait is satisfied.

If one of the wait conditions is already satisfied then the block is for no
time.  The C<event_threshold> events described below are still generated in
this case.

Each condition is an arrayref of key/value pairs

    counter           the target counter (integer XID)
    value_type        "Absolute" or "Relative"
    value             target value (INT64 signed integer)
    test_type         "PositiveTransition", "NegativeTransition",
                      "PositiveComparison" or "NegativeComparison"
    event_threshold   possible difference (INT64 signed integer)

For example to wait on two counters

    $X->SyncAwait ([ counter    => $c1,
                     value_type => "Absolute",
                     value      => 1000,
                     test_type  => "PositiveComparison",
                     event_threshold => 100 ],
                   [ counter    => $c2,
                     value_type => "Absolute",
                     value      => 500,
                     test_type  => "NegativeTransition",
                     event_threshold => 100 ]);

C<test_type> is how the condition will be satisfied,

    "PositiveComparison"   whenever counter >= value
    "NegativeComparison"   whenever counter <= value
    "PositiveTransition"   change from counter<value to counter>=value
    "NegativeTransition"   change from counter>value to counter<=value

C<value_type> is how C<value> is interpreted

    "Absolute"     target value as given
    "Relative"     target value is counter current value + given value

For "Absolute" the C<counter> can be "None" and that's considered satisfied
immediately.  For "Relative" each C<counter> must be a valid counter.  If
adding the relative amount overflows an INT64 then a C<BadValue> error
results.

If any of the counters is destroyed during C<SyncAwait()> then the wait
finishes and a C<CounterNotify> event with the C<destroyed> flag is
generated.

When C<SyncAwait()> finishes, the C<event_threshold> can generate
C<CounterNotify> events for the client.  The difference

    diff = counter - target value

is compared to the given C<event_threshold>

    if diff >= event_threshold for "Positive"
    or diff <= event_threshold for "Negative"
    then send CounterNotify

This is designed to alert the client that a counter has run on by more than
a threshold amount.  This could be due to lag, or perhaps a jump in the
value.

=item C<$X-E<gt>SyncCreateAlarm ($alarm, $key=E<gt>$value, ...)>

=item C<$X-E<gt>SyncChangeAlarm ($alarm, $key=E<gt>$value, ...)>

Create C<$alarm> (a new XID) as an alarm, or change the parameters of an
existing C<$alarm>.  The key/value parameters are similar to C<SyncAwait()>
above,

    counter       the target counter (integer XID)
    value_type    "Absolute" or "Relative"
    value         target value (64-bit signed integer)
    test_type     "PositiveTransition", "NegativeTransition",
                  "PositiveComparison" or "NegativeComparison"
    delta         step target value (64-bit signed, default 1)
    events        boolean (default true)

All the parameters have defaults, so an alarm can be created with no counter
etc at all just by

    my $alarm = $X->new_rsrc;
    $X->SyncCreateAlarm ($alarm);

C<counter> "None" (0) or omitted makes the alarm "Inactive".

C<delta> is added to C<value> when the alarm is satisfied.  C<delta> is
added repeatedly if necessary to make it unsatisfied, ie. add smallest
necessary multiple of C<delta> to become unsatisfied.  The default C<delta>
of 1 means C<value> has 1 added until unsatisfied again, so reset the alarm
target to counter value+1.

If adding C<delta> this way would overflow an INT64, or if C<delta> is 0 in
a "Comparison" test (and thus no amount of adding will unsatisfy), then the
alarm value is unchanged and the alarm set "Inactive" instead.  Setting
C<delta> to 0 therefore makes a "once-only" alarm.

C<delta> must be positive or negative in the same direction as the
C<test_type> or a C<Match> error results.

    "Positive"     must have delta >= 0
    "Negative"     must have delta <= 0

If C<events> is true then when the alarm is satisfied an C<AlarmNotify>
event is generated.  If the C<delta> caused the alarm to become "Inactive"
then the C<state> field in the event will show it Inactive.

The C<events> flag is a per-client setting.  Each client can individually
select or deselect events from any alarm using C<SyncChangeAlarm()>,

    $X->SyncChangeAlarm ($alarm, events => $bool);

If an error results (bad type, bad counter, etc) then the SYNC specification
allows some of the request changes to have been applied but others not.

=item C<@list = $X-E<gt>SyncQueryAlarm ($alarm)>

Return the current parameters of C<$alarm> (integer XID) in the form of a
key/value list like C<SyncCreateAlarm()> above.

For reference, in the X.org server circa its version 1.10 if C<value_type>
is set to "Relative" then it reads back as "Absolute" with a C<value> which
is the target counter+relative_value.  Not sure what the SYNC spec says
about this.

=item C<$X-E<gt>SyncDestroyAlarm ($alarm)>

Destroy C<$alarm> (an XID).

=back

=head1 Client Priority

=over

=item C<$X-E<gt>SyncSetPriority ($xid, $priority)>

=item C<$priority = $X-E<gt>SyncGetPriority ($xid)>

Get or set a client's scheduling priority level in the server.  C<$xid> is
any XID belonging to the desired client, or "None" (0) for the current
client.  C<$priority> is an INT32 integer.  Higher numbers are higher
priority.  The default priority is 0.

    $X->SyncSetPriority ("None", 100);   # higher priority

    $X->SyncSetPriority ("None", -123);  # lower priority

Setting a client to high priority may help it do smooth animations etc.
A high priority client might have to be careful that it doesn't flood the
server with requests which starve other clients.  The server may or may not
actually do anything with the priority level.

=back

=head2 Fence

Fences are new in SYNC version 3.1.  A fence represents completion of all
queued drawing in the server.  It can be in "triggered" or "untriggered"
state.  Clients can ask for trigger when drawing has completed, and then
either query or block waiting for that to occur.

=over

=item C<$X-E<gt>SyncCreateFence ($fence, $drawable, $initially_triggered)>

Create C<$fence> (a new XID) as a fence on the screen of C<$drawable>.

=item C<$X-E<gt>SyncTriggerFence ($fence)>

Ask the server to set C<$fence> (XID) to triggered state when all drawing
requests currently in progress on the screen of C<$fence> have completed.
This is all drawing from both the current client and other clients.  If
C<$fence> is already triggered then do nothing.

If a simple server does all drawing direct to video memory with no queuing
then C<$fence> will be triggered immediately.  If the server or graphics
card has some sort or rendering pipeline or queue then C<$fence> is
triggered only when the drawing requests issued so far have reached the
actual screen.

=item C<$X-E<gt>SyncResetFence ($fence)>

Reset C<$fence> (an XID) from triggered to untriggered state.  A C<Match>
error results if C<$fence> is not currently in triggered state.

=item C<$X-E<gt>SyncDestroyFence ($fence)>

Destroy C<$fence> (an XID).

=item C<$triggered = $X-E<gt>SyncQueryFence ($fence)>

Get the current triggered state of C<$fence> (an XID).  The return is 0 if
untriggered or 1 if triggered.

=item C<$X-E<gt>SyncAwaitFence ($fence1, $fence2, ...)>

Block the processing of further requests from the current client until one
or more of the given C<$fence> XIDs is in triggered state.  If one of the
fences is already currently triggered then there's no block and request
processing continues immediately.

=back

=head1 EVENTS

Each event has the usual fields

    name             "SyncCounterNotify" etc
    synthetic        true if from a SendEvent
    code             integer opcode
    sequence_number  integer

plus event-specific fields described below.

=over

=item C<SyncCounterNotify>

A C<SyncCounterNotify> event is generated when a C<SyncAwait()> request is
unblocked by one or more of its requested conditions being satisfied.

The event-specific fields are

    time           integer, server timestamp
    counter        integer XID
    wait_value     INT64
    counter_value  INT64
    destroyed      bool, 0 or 1
    count          integer, how many more SyncCounterNotify

If multiple conditions in the C<SyncAwait()> have been satisfied then each
one results in a C<SyncCounterNotify> event.  The C<count> field is how many
more such C<SyncCounterNotify> are following the present one (0 if no more).

C<destroyed> is 1 if the C<counter> was destroyed during the C<SyncAwait()>.

=item C<SyncAlarmNotify>

A C<SyncAlarmNotify> is generated when an alarm object is triggered and its
C<events> flag is true for this client.

The event-specific fields are

    time           integer, server timestamp
    alarm          integer XID
    alarm_value    INT64
    counter_value  INT64
    state          enum "Active", "Inactive", or "Destroyed"

=back

=head1 ENUM TYPES

The following types are available for C<$X-E<gt>interp()> and
C<$X-E<gt>num()>, after C<init_extension()>.

=over

=item SyncValueType

    "Absolute"     0
    "Relative"     1

=item SyncTestType

    "PositiveTransition"     0
    "NegativeTransition"     1
    "PositiveComparison"     2
    "NegativeComparison"     3

=item SyncAlarmState

    "Active"        0
    "Inactive"      1
    "Destroyed"     2

=back

For example,

    my $num = $X->num("SyncTestType", "PositiveComparison");
    # sets $num to 2

=head1 ERRORS

The extension error types are

    "Counter"
    "Alarm"
    "Fence"         # if server has SYNC 3.1

which are respectively a bad C<$counter>, C<$alarm> or C<$fence> resource
XID in a request.

=head1 SEE ALSO

L<X11::Protocol>

F</usr/share/doc/x11proto-xext-dev/sync.txt.gz>,
F</usr/share/X11/doc/hardcopy/Xext/sync.PS.gz>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/x11-protocol-other/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014 Kevin Ryde

X11-Protocol-Other is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

X11-Protocol-Other is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

=cut

# The C<Math::BigInt> which is included in Perl 5.6.0 and thereabouts has a
# couple of dubious bits.  Believe it suffices for adding and subtracting
# but it might be necessary to demand a newer version for more involved
# calculations.  Working with an overloaded type for the 64-bits is much
# more convenient than two 32-bit parts.
