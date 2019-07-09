# DRI2SwapCompleteEventType name ?



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
package X11::Protocol::Ext::DRI2;
use strict;
use Carp;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 31;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
use Smart::Comments;


# /usr/share/doc/x11proto-dri2-dev/dri2proto.txt.gz
#
# /usr/include/X11/extensions/dri2proto.h
# /usr/include/X11/extensions/dri2tokens.h
#
# /so/xorg/xorg-server-1.10.0/hw/xfree86/dri2/dri2ext.c
#    Server source.
#
# /so/xfree4/unpacked/usr/share/doc/xserver-xfree86/README.DRI.gz
#
# /usr/share/xcb/dri2.xml
#    xcb (dri2 1.3)
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz


# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 1;
use constant CLIENT_MINOR_VERSION => 2;

#------------------------------------------------------------------------------
# symbolic constants

use constant constants_list =>
  (DRI2Driver     => ['DRI', 'VDPAU'],
   DRI2Attachment => [qw(FrontLeft
                         BackLeft
                         FrontRight
                         BackRight
                         Depth
                         Stencil
                         Accum
                         FakeFrontLeft
                         FakeFrontRight
                         DepthStencil
                         Hiz
                       )],
   DRI2SwapCompleteEventType => [ '',
                                  'ExchangeComplete',  # 1
                                  'BlitComplete',      # 2
                                  'FlipComplete' ],    # 3
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
  (DRI2BufferSwapComplete =>
   [ sub {
       my $X = shift;
       my $data = shift;
       my ($event_type, $drawable, $ust_hi,$ust_lo, $msc_hi,$msc_lo, $sbc_hi,$sbc_lo)
         = unpack 'xxxxSxxL7', $data;
       return (@_,  # base fields
               event_type => $X->num('DRI2BufferSwapCompleteEventType', $event_type),
               drawable   => $drawable,
               ust        => _hilo_to_card64($ust_hi,$ust_lo),
               msc        => _hilo_to_card64($msc_hi,$msc_lo),
               sbc        => _hilo_to_card64($sbc_hi,$sbc_lo),
              );
     }, sub {
       my ($X, %h) = @_;
       my $level = ($X->num('DamageReportLevel', $h{'level'})
                    + ($h{'more'} ? 0x80 : 0));
       return (pack('xxxxSxxL7',
                    $level,
                    $X->interp('DRI2BufferSwapCompleteEventType', $h{'event_type'}),
                    $h{'drawable'},
                    _hilo_to_card64($h{'ust'}),
                    _hilo_to_card64($h{'msc'}),
                    _hilo_to_card64($h{'sbc'})),
               1); # "do_seq" put in sequence number
     } ],

   DRI2InvalidateBuffers =>
   [ 'xxxxLx24',
     'drawable',
   ],
  );

sub _ext_events_install {
  my ($X, $event_num, $events_arrayref) = @_;
  foreach (my $i = 0; $i <= $#$events_arrayref; $i+=2) {
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
# requests

my $requests_arrayref =
  [
   ['DRI2QueryVersion',    # 0
    \&_request_card32s, # ($X, $client_major, $client_minor)
    sub {
      my ($X, $data) = @_;
      return unpack 'x8LL', $data;

      # Any interest in holding onto the version?
      #  my ($server_major, $server_minor) = unpack 'x8LL', $data;
      # ### $server_major
      # ### $server_minor
      # my $self;
      # if ($self = $self->{'ext'}{'DRI2'}->[3]) {
      #   $self->{'major'} = $server_major;
      #   $self->{'minor'} = $server_minor;
      # }
      # return ($server_major, $server_minor);
    }],

   ['DRI2Connect',  # 1
    sub {
      my ($X, $window, $driver_type) = @_;
      return pack 'LL', $window, $X->num('DRI2Driver',$driver_type);
    },
    sub {
      my ($X, $data) = @_;
      ### DRI2Connect() reply length: length($data)
      my ($driver_len, $device_len) = unpack 'x8LL', $data;
      ### $driver_len
      ### $device_len
      return (substr($data, 32,
                     $driver_len),
              substr($data, 32 + X11::Protocol::padding($driver_len),
                     $device_len));
    },
   ],

   ['DRI2Authenticate',  # 2
    \&_request_card32s,  # ($X, $window, $token)
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data; # ($authenticated)
    },
   ],

   ['DRI2CreateDrawable',  # 3
    \&_request_card32s,  # ($X, $drawable)
   ],

   ['DRI2DestroyDrawable',  # 4
    \&_request_card32s,  # ($X, $drawable)
   ],

   ['DRI2GetBuffers',  # 5
    sub {  # ($X, $drawable, $attach...)
      my $X = shift;
      my $drawable = shift;

      ### DRI2GetBuffers(), num_attach: scalar(@_)
      ### attaches: (map {$X->num('DRI2Attachment',$_)} @_)
      ### data: pack 'L*',$drawable,scalar(@_), map {$X->num('DRI2Attachment',$_)} @_

      return pack 'L*',
        $drawable,
          scalar(@_), # num attachments
            map {$X->num('DRI2Attachment',$_)} @_;
    },
    \&_reply_get_buffers ],

   ['DRI2CopyRegion',  # 6
    \&_request_card32s,  # ($X, $drawable, $region, $dest, $src)
    sub {  # ($X, $data)  empty
      return;
    },
   ],

   #------------------------------------
   # protocol 1.1

   ['DRI2GetBuffersWithFormat',  # 7
    sub {  # ($X, $drawable, $attach_format,...)
      my $X = shift;
      my $drawable = shift;

      ### DRI2GetBuffers(), num_attach_formats: scalar(@_)

      return pack 'L*',
        $drawable,
          scalar(@_), # num attachments
            map {
              my ($attach, $format) = @$_;
              ($X->num('DRI2Attachment',$attach), $format)
            } @_;
    },
    \&_reply_get_buffers ],

   #------------------------------------
   # protocol 1.2

   ['DRI2SwapBuffers',  # 8
    sub {
      my ($X, $drawable, $target_msc, $divisor, $remainder) = @_;
      return pack('L*',
                  $drawable,
                  _card64_to_hilo($target_msc),
                  _card64_to_hilo($divisor),
                  _card64_to_hilo($remainder));
    },
    sub {
      my ($X, $data) = @_;
      return _hilo_to_card64 (unpack 'x8LL', $data);
    },
   ],

   ['DRI2GetMSC',  # 9
    \&_request_card32s,  # ($X, $drawable)
    \&_reply_ums64 ],

   ['DRI2WaitMSC',   # 10
    sub {
      my ($X, $drawable, $target_msc, $divisor, $remainder) = @_;
      return pack 'L*', $drawable,
        _card64_to_hilo($target_msc),
          _card64_to_hilo($divisor),
            _card64_to_hilo($remainder);
    },
    \&_reply_ums64 ],

   ['DRI2WaitSBC',  # 11
    sub {
      my ($X, $drawable, $target_sbc) = @_;
      return pack 'L*', $drawable, _card64_to_hilo($target_sbc);
    },
    \&_reply_ums64 ],

   [ 'DRI2SwapInterval',  # 12
     \&_request_card32s,  # ($X, $drawable, $interval)
   ],
  ];

sub _reply_get_buffers {
  my ($X, $data) = @_;
  ### _reply_get_buffers(), length: length($data)

  my ($width, $height, $num_buffers) = unpack 'x8LLL', $data;
  ### $width
  ### $height
  ### $num_buffers

  return ($width, $height, _unpack_buffers($X,$data,$num_buffers));
}
sub _unpack_buffers {
  my ($X, $data, $num_buffers) = @_;
  return map {
    # (attach, name, pitch, cpp, flags)
    [ unpack 'L*', substr($data,12+$_*20,20) ]
  } 1 .. $num_buffers;
}

sub _reply_ums64 {
  my ($X, $data) = @_;
  ### _reply_ums64(): $data
  my ($ust_hi,$ust_lo, $msc_hi,$msc_lo, $sbc_hi,$sbc_lo)
    = unpack 'x8L6', $data;
  return (_hilo_to_card64($ust_hi,$ust_lo),
          _hilo_to_card64($msc_hi,$msc_lo),
          _hilo_to_card64($sbc_hi,$sbc_lo));
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

#------------------------------------------------------------------------------

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  my $self = bless { }, $class;

  _ext_constants_install ($X, [ $self->constants_list ]);
  _ext_requests_install ($X, $request_num, $requests_arrayref);
  _ext_events_install ($X, $event_num, [ $self->events_list ]);
  return $self;
}

#------------------------------------------------------------------------------
# generic

sub _request_card32s {
  shift;
  ### _request_card32s(): @_
  return pack 'L*', @_;
}
sub _request_screen16 {
  shift;  # ($X, $screen)
  @_ == 1 or croak "Single screen number parameter expected";
  return pack 'Sxx', @_;
}

sub _num_none {
  my ($xid) = @_;
  if (defined $xid && $xid eq "None") {
    return 0;
  } else {
    return $xid;
  }
}

#------------------------------------------------------------------------------
# 64-bits

{
  my $uv = ~0;
  my $bits = 0;
  while ($uv && $bits < 64) {
    $uv >>= 1;
    $bits++;
  }

  if ($bits >= 64) {
     eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;
sub _hilo_to_card64 {
  my ($hi,$lo) = @_;
  ### _hilo_to_sv(): "$hi $lo"
  if ($hi & 0x8000_0000) {
    $hi -= 0x8000_0000;
    $lo += -(1<<63);
  }
  ### $hi
  ### $lo
  ### hi shift: $hi<<1
  ### result: ($hi << 32) + $lo
  return ($hi << 32) + $lo;
}
1;
HERE
  } else {
     eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;
use Math::BigInt;
sub _hilo_to_card64 {
  my ($hi,$lo) = @_;
  my $sv = ($hi << 32) + $lo;
  my $sv = Math::BigInt->new($hi)->blsft(32)->badd($lo);
  if ($hi & 0x8000_0000) {
    $sv = -$sv;
  }
  return $sv;
}
1;
HERE
  }
}

sub _card64_card64_to_hilo {
  my ($sv) = @_;
  return ($sv >> 32,          # hi
          $sv & 0xFFFF_FFFF); # lo
}

1;
__END__

=for stopwords XID Ryde

=head1 NAME

X11::Protocol::Ext::DRI2 - direct video memory access

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('DRI2')
   or print "DRI2 extension not available";

=head1 DESCRIPTION

The DRI2 extension ...

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('DRI2');

=head2 DRI2 1.0

=over

=item C<($server_major, $server_minor) = $X-E<gt>DRI2QueryVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like.  The returned
C<$server_major> and C<$server_minor> is what the server will do.

The current code in this module supports up to 1.2 and the intention would
be to automatically negotiate in C<init_extension()> if necessary.

=item C<($driver_name, $device_name) = $X-E<gt>DRI2Connect ($window, $driver_type)>

Get the driver name and device name to use on C<$window> (integer XID).
C<$driver_type> is a C<DRI2Driver> enum,

    "DRI"      0
    "VDPAU"    1

If C<$driver_type> is unknown or the client is not on the same machine as
the server then the returned C<$driver_name> and C<$device_name> are empty
strings "".

Exactly what the client might have to do with C<$driver_name> is
unspecified.

=item C<$bool = $X-E<gt>DRI2Authenticate ($window, $token)>

Ask the server to authenticate C<$token> (a 32-bit integer) so the client
can access DRI memory on the screen associated with C<$window> (an integer
XID).  The return is 1 if successful or 0 if C<$token> is no good.

The C<$token> should be obtained from the kernel rendering manager, somehow.

=item C<($width,$height,[bufinfo],[bufinfo]...) = $X-E<gt>DRI2GetBuffers ($drawable, $attach...)>

Get buffers for C<$drawable> (integer XID) at the given C<$attach> points.
Each C<$attach> argument is a C<DRI2Attachment> enum value,

    FrontLeft           0
    BackLeft            1
    FrontRight          2
    BackRight           3
    Depth               4
    Stencil             5
    Accum               6
    FakeFrontLeft       7
    FakeFrontRight      8
    DepthStencil        9     new in protocol 1.1
    Hiz                10

The return is the screen size and a buffer info for each given C<$attach>.
Each info is an arrayref

    [ $attach,          # $attach from request
      $name,            # buffer name (integer)
      $pitch,           # (integer)
      $cpp,             # chars per pixel (integer)
      $flags            # (integer)
    ]

If any of the C<$attach> buffers requested cannot be obtained then a Value
error is sent.

=item C<$X-E<gt>DRI2CopyRegion ($drawable, $region, $src_attach, $dst_attach)>

Copy C<$region> (integer XID of XFIXES Region type) from C<$src_attach> to
C<$dst_attach> buffers of C<$drawable> (integer XID).  The attach arguments
are per C<DRI2GetBuffers()> above.

=back

=head2 DRI2 1.1

=over

=item C<($width,$height,[bufinfo],[bufinfo]...) = $X-E<gt>DRI2GetBuffers ($drawable, [$attach,$format],...)>

Get buffers for C<$drawable> (integer XID) at the given C<$attach> points.
Each buffer requested is an arrayref of two values

    [ $attach, $format ]

C<$attach> is a C<DRI2Attachment> enum value as per C<DRI2GetBuffers()>
above, and C<$format> (an integer) is some sort of device-dependent format
desired for the buffer.

The return and possible Value error is the same as C<DRI2GetBuffers()>
above.

=back

=head2 DRI2 1.2

=over

=item C<($sbc) = $X-E<gt>DRI2SwapBuffers ($drawable, $target_msc, $divisor, $remainder)>

Schedule a swap of the front and back buffers.

The swap will be done when the media stamp counter reaches C<$target_msc>.
If MSC E<gt> C<$target_msc> already then it's done when MSC mod C<$divisor>
equals C<$remainder>, or if C<$divisor> is 0 then immediately.

When the swap is performed the swap counter increments and a
C<DRI2BufferSwapComplete> event is sent to the client.

=item C<($ust, $msc, $sbc) = $X-E<gt>DRI2GetMSC ($drawable)>

Get the current unadjusted system time, media stamp counter, and swap
buffer counter.

The C<$sbc> swap buffer counter is how many scheduled C<DRI2SwapBuffers()>
swaps have completed.

=item C<($ust, $msc, $sbc) = $X-E<gt>DRI2WaitMSC ($drawable, $target_msc, $divisor, $remainder)>

Block processing of requests from the client until the media stamp counter
reaches C<$target_msc>.

If MSC E<gt> $target_msc already then block until MSC mod $divisor ==
$remainder, or if $divisor is 0 then don't block.

The return is the time and counters per C<DRI2GetMSC()> above.

=item C<($ust, $msc, $sbc) = $X-E<gt>DRI2WaitSBC ($drawable, $target_sbc, $divisor, $remainder)>

Block processing of requests from the client until the swap buffer counter
reaches C<$target_sbc>.  If C<$target_sbc> is 0 then block until all
currently scheduled C<DRI2SwapBuffers()> have completed.

The return is time and counters per C<DRI2GetMSC()> above.

=item C<$X-E<gt>DRI2SwapInterval ($drawable, $interval)>

Set the swap interval on C<$drawable> (integer XID).

Swaps scheduled with C<DRI2SwapBuffers()> are limited to at most one swap
per C<$interval> many media stamp counter frames.

=head1 EVENTS

The following events have the usual fields

    name             "DRI2..."
    synthetic        true if from a SendEvent
    code             integer opcode
    sequence_number  integer

=over

=item C<DRI2BufferSwapComplete>

This is sent to the client when a scheduled C<DRI2SwapBuffers()> has
completed.  The fields are

    event_type      enum "ExchangeComplete"  1
                         "BlitComplete"      2
                         "FlipComplete"      3
    drawable        XID
    ust             unadjusted system time (integer)
    msc             media stamp counter (integer)
    sbc             swap buffer counter (integer)

C<ust>, C<msc> and C<sbc> are as per C<DRI2GetMSC()> above.

=item C<DRI2InvalidateBuffers>

This is sent to the client to advise that some sort of screen size or other
change has invalidated the buffers it obtained with C<DRI2GetBuffers()>.
The fields are

    drawable        XID

=head1 SEE ALSO

L<X11::Protocol>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/x11-protocol-other/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2017 Kevin Ryde

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
