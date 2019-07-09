# test ...



# Copyright 2011, 2012, 2013, 2014, 2017, 2019 Kevin Ryde

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
package X11::Protocol::Ext::XFree86_VidModeExtension;
use strict;
use Carp;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 31;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
use Smart::Comments;


# Protocol 0.7:
#   /so/x11r6.4/xc/include/extensions/xf86vmstr.h
#       protocol
#
#   /so/x11r6.4/xc/programs/Xserver/Xext/xf86vmode.c
#       server
#
# Protocol 0.8:
#   /so/xfree/xfree86-3.3.2.3a/include/extensions/xf86vmstr.h
#      protocol
#
#   /so/xfree/xfree86-3.3.2.3a/programs/Xserver/Xext/xf86vmode.c
#   /so/xfree/xfree86-3.3.2.3a/programs/Xserver/hw/xfree86/common/xf86Cursor.c
#      server
#
#   /so/xfree/xfree86-3.3.2.3a/lib/Xxf86vm/XF86VMode.c
#   /so/xfree/xfree86-3.3.2.3a/include/extensions/xf86vmode.h
#   /so/xfree/xfree86-3.3.2.3a/programs/Xserver/hw/xfree86/doc/man/XF86VM.man
#      xlib
#
# Protocol 2.0:
#   /usr/include/X11/extensions/xf86vm.h
#   /usr/include/X11/extensions/xf86vmproto.h
#
#   /so/x86vm/libXxf86vm-1.1.1/src/XF86VMode.c
#       Xlib
#
#   /so/xorg/xorg-server-1.10.0/hw/xfree86/dixmods/extmod/xf86vmode.c
#       server source
#
# Other:
#   /z/usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
#


# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 2;
use constant CLIENT_MINOR_VERSION => 1;

#------------------------------------------------------------------------------
# events

my $XF86VidModeNotify_event
  = [ 'xCxxLsssSx16',
      'detail',
      'time',
      'dx',
      'dy',
      'screen',
      'state',
    ];

#------------------------------------------------------------------------------
# requests

my $reqs =
  [
   ['XF86VidModeQueryVersion',  # 0
    \&_request_empty,
    sub {
      my ($X, $data) = @_;
      return unpack 'x8SS', $data;
    }],

   ['XF86VidModeGetModeLine',  # 1
    \&_request_screen16,
    do {
      my @fields = (qw(dotclock

                       hdisplay
                       hsyncstart
                       hsyncend
                       htotal

                       vdisplay
                       vsyncstart
                       vsyncend
                       vtotal

                       flags
                       private_size));
      sub {
        my ($X, $data) = @_;

        # use Data::HexDump::XXD;
        # print scalar(Data::HexDump::XXD::xxd($data));
        # print "\n";

        my @values = unpack 'x8LS8LL', $data;
        my $private_size = pop @values;
        ### @values
        ### $private_size

        return ((map { ($fields[$_] => $values[$_]) } 0 .. $#values),
                private => substr($data,32,$private_size*4));;
      }
    },
   ],

   ['XF86VidModeModModeLine',  # 2
    do {
      my @fields = (qw(dotclock

                       hdisplay
                       hsyncstart
                       hsyncend
                       htotal

                       vdisplay
                       vsyncstart
                       vsyncend
                       vtotal

                       flags
                       private_size));
      sub {
        my ($X, $screen_num, %h) = @_;
        my $private = delete $h{'private'};
        if (! defined $private) { $private = ''; }
        $h{'private_size'} = int((length($private)+3)/4);

        my @values = delete @h{@fields}; # hash slice
        if (%h) {
          croak "XF86VidModeModModeLine unknown field(s): ",join(',',keys %h);
        }
        return pack ('x8LS8LL'.padded($private),
                     $screen_num,
                     @values,
                     $private);
      }
    } ],

   ['XF86VidModeSwitchMode',  # 3
    sub {
      my ($X, $screen_num, $zoom) = @_;
      return pack 'SS', $screen_num, $zoom;
    },
   ],

   ['XF86VidModeGetMonitor',  # 4
    \&_request_screen16,
    sub {
      my ($X, $data) = @_;

      use Data::HexDump::XXD;
      print scalar(Data::HexDump::XXD::xxd($data));
      print "\n";

      # There was a "bandwidth" field in protocol 0.7 and 0.8 headers, but
      # the server never sent it and Xlib never used it.
      #
      my ($vendor_len, $model_len, $num_hsync, $num_vsync)
        = unpack 'x8C4L', $data;

      my $pos = 32;
      my @hsyncs;
      foreach (1 .. $num_hsync) {
        my $sync = unpack 'L', substr($data,$pos,4);
        $pos += 4;
        push @hsyncs, [ $sync & 0xFFFF, $sync >> 16 ]; # lo,hi
      }

      my @vsyncs;
      foreach (1 .. $num_vsync) {
        my $sync = unpack 'L', substr($data,$pos,4);
        $pos += 4;
        push @vsyncs, [ $sync & 0xFFFF, $sync >> 16 ]; # lo,hi
      }

      my $vendor = substr ($data, $pos, $vendor_len);
      $pos += $vendor_len + X11::Protocol::padding($vendor_len);
      my $model = substr ($data, $pos, $model_len);

      return $vendor, $model, \@hsyncs, \@vsyncs;
    },
   ],

   ['XF86VidModeLockModeSwitch',  # 5
    sub {
      my ($X, $screen_num, $lock) = @_;
      return pack 'SS', $screen_num, $lock;
    },
   ],

   ['XF86VidModeGetAllModeLines',  # 6
    \&_request_screen16,
    sub {
      my ($X, $data) = @_;
      ### XF86VidModeGetAllModeLines() reply length: length($data)

      use Data::HexDump::XXD;
      print scalar(Data::HexDump::XXD::xxd($data));
      print "\n";

      my $self = $X->{'ext'}{'XFree86_VidModeExtension'}->[3];
      ### $self
      my $protocol_2 = ($self->{'set_client_major'} >= 2);
      my $protocol_08 = (($self->{'major'} <=> 0 || $self->{'minor'} <=> 8)
                         >= 0);

      my ($num_modes) = unpack 'x8L', $data;
      ### $num_modes

      my $pos = 32;
      my @ret;
      foreach (1 .. $num_modes) {
        ### $pos
        my %h;

        # bigger data format if XF86VidModeSetClientVersion() is 2 or more
        if ($protocol_2) {
          @h{ # hash slice
            qw(dotclock

               hdisplay
               hsyncstart
               hsyncend
               htotal

               hskew

               vdisplay
               vsyncstart
               vsyncend
               vtotal

               flags
               private_size
             )} = unpack 'LS4LS4x4Lx12L', substr($data,$pos,48);
          $pos += 48;

        } else {
          @h{ # hash slice
            qw(dotclock

               hdisplay
               hsyncstart
               hsyncend
               htotal

               vdisplay
               vsyncstart
               vsyncend
               vtotal

               flags
               private_size
             )} = unpack 'LS8L2', substr($data,$pos,28);
          $pos += 28;
        }

        # in protocol 0.7 the server gave a "private_size" field but didn't
        # send the actual data, per server code in X11R6.4
        # /so/x11r6.4/xc/programs/Xserver/Xext/xf86vmode.c
        #
        if ($protocol_08) {
          my $private_size = 4 * delete $h{'private_size'};
          ### $private_size
          $h{'private'} = substr($data,$pos,$private_size);
          $pos += $private_size;
        }

        push @ret, \%h;
      }
      return @ret;
    }
   ],

   ['XF86VidModeAddModeLine',  # 7
    sub {
      my ($X, $screen) = @_;
      die;
    }],

   ['XF86VidModeDeleteModeLine',  # 8
    \&_request_screen16,
   ],

   ['XF86VidModeValidateModeLine',  # 9
    sub {
      shift;  # ($X, $screen, $n)
      return pack 'SS', @_;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data; # (result)
    } ],

   ['XF86VidModeSwitchToMode',   # 10
    \&_request_screen32, # and more ...
   ],

   ['XF86VidModeGetViewPort',   # 11
    \&_request_screen16,
    sub {
      my ($X, $data) = @_;
      return unpack 'x8LL', $data; # ($x,$y)
    } ],

   ['XF86VidModeSetViewPort',   # 12
    sub {
      shift;  # ($X, $screen, $x,$y)
      return pack 'SxxLL', @_;
    },
   ],

   #---------------------------------------------------------------------------
   # protocol 2.0

   ['XF86VidModeGetDotClocks',  # 13
    \&_request_screen16,
   ],

   [ 'XF86VidModeSetClientVersion',  # 14
     sub {
       my ($X, $client_major, $client_minor) = @_;
       my $self = $X->{'ext'}{'XFree86_VidModeExtension'}->[3];
       $self->{'set_client_major'} = $client_major;
       return pack 'SS', @_;
     },
   ],

   [ 'XF86VidModeSetGamma', # 15
     \&_request_card32s ],  # ($X, $screen, $colormap)

   [ 'XF86VidModeGetGamma', # 16
     \&_request_card32s ],  # ($X, $screen, $mask)

   [ 'XF86VidModeGetGammaRamp', # 17
     sub {
       shift;  # ($X, $screen, $x, $y, $width, $height, $color)
       return pack 'LSSSSL', @_;
     } ],

   [ 'XF86VidModeSetGammaRamp',  # 18
     sub {
       shift;  # ($X, $screen, $src_x,$src_y, $width,$height, $dst_x,$dst_y)
       return pack 'LS*', @_;
     } ],

   [ 'XF86VidModeGetGammaRampSize',  # 19
     sub {
       shift;
       # ($X, $screen, $src_x,$src_y, $width,$height, $dst_x,$dst_y, $key)
       return pack 'LS6L', @_;
     } ],

   [ 'XF86VidModeGetPermissions',  # 20
     \&_request_screen16,
   ],
  ];

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### XF86VidMode new()

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  # Errors
  _ext_const_error_install ($X, $error_num,
                            'XF86VidModeBadClock',           # 0
                            'XF86VidModeBadHTimings',        # 1
                            'XF86VidModeBadVTimings',        # 2
                            'XF86VidModeModeUnsuitable',     # 3
                            'XF86VidModeExtensionDisabled',  # 4
                            'XF86VidModeClientNotLocal',     # 5
                            'XF86VidModeZoomLocked',         # 6
                           );

  my ($server_major, $server_minor) = $X->XF86VidModeQueryVersion;

  return bless { set_client_major => 0,
                 server_major     => $server_major,
                 server_minor     => $server_minor,
               }, $class;
}

#------------------------------------------------------------------------------
# generic

sub _request_empty {
  # ($X)
  if (@_ > 1) {
    croak "No parameters in this request";
  }
  return '';
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

1;
__END__

=for stopwords XID Ryde

=head1 NAME

X11::Protocol::Ext::XFree86_VidModeExtension - video modes

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('XFree86-VidModeExtension')
   or print "XFree86-VidModeExtension extension not available";

=head1 DESCRIPTION

The XFree86-VidModeExtension extension ...

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('XFree86-VidModeExtension');

=head2 XFree86-VidModeExtension 1.0

=over

=item C<($server_major, $server_minor) = $X-E<gt>XF86VidModeQueryVersion ()>

Return the DGA protocol version implemented by the server.

=item C<%h = $X-E<gt>XF86VidModeGetModeLine ($screen_num)>

Get the current mode of C<$screen_num> (integer 0 upwards).  The return is a
list of key/value pairs,

    dotclock   => integer
    hdisplay   => integer, horizontal visible pixels
    hsyncstart => integer, horizontal sync start
    hsyncend   => integer, horizontal sync end
    htotal     => integer, horizontal total pixels
    vdisplay   => integer, vertical visible pixels
    vsyncstart => integer, vertical sync start
    vsyncend   => integer, vertical sync end
    vtotal     => integer, vertical total pixels
    flags      => integer
    private    => byte string

They can be put into a hash for access to a particular value,

    my %h = $X->XF86VidModeGetModeLine(0);
    print $h{'hskew'},"\n";

C<private> is extra data from the driver on the screen.  Usually it's an
empty string, but for example in the past the S3 Virge driver had some extra
flags and blank delay there.  In the current code this is always just a byte
string, no attempt at a decode.

=item C<$X-E<gt>XF86VidModeModModeLine ($screen_num, key=E<gt>value,...)>

Modify the current mode of C<$screen_num> (integer 0 upwards).  Key/value
parameters are as per C<XF86VidModeGetModeLine()> above.

All fields are mandatory, except for C<private> which is treated as an empty
string if omitted.

Any mode values can be given (not just those listed by
C<XF86VidModeGetAllModeLines()>) but it's generally the caller's
responsibility to ensure they don't exceed the capabilities of the monitor.

=item C<($vendor, $model, $hsyncs_aref, $vsyncs_aref) = $X-E<gt>XF86VidModeGetMonitor ($screen_num)>

Get information on the monitor and its capabilities.

C<$vendor> and C<$model> are strings.  C<$hsyncs_aref> and C<$hsyncs_aref>
are arrayrefs containing in turn arrayref pairs of low,high permitted sync
amounts,

    [ [ 3000, 4500 ],
      [ 7200, 8200 ]
    ]

For reference, past versions of the protocol headers and Xlib docs had a
"bandwidth" field here, but the server never sent it and Xlib never looked
at it.

=item C<$X-E<gt>XF86VidModeSwitchMode ($screen_num, $zoom)>

Switch to the next or previous mode on C<$screen_num> (integer 0 upwards).
If C<$zoom> is 1 (or more) to switch to the next mode, or 0 to switch to the
previous mode.

=item C<$X-E<gt>XF86VidModeLockModeSwitch ($screen_num, $lock)>

Lock or unlock mode switching on C<$screen_num> (integer 0 upwards).  If
C<$lock> is non-zero then mode switching via either the keyboard or the
C<XF86VidModeSwitchMode()> request is prevented.  If C<$lock> is zero
switching is allowed again.

=item C<$X-E<gt>XF86VidModeGetAllModeLines ($screen_num)>

=back

=head1 BUGS

Some versions of the X.org server circa 1.10 had the C<hskew> field of
C<XF86VidModeGetAllModeLines()> byte swapped as 16-bit instead of 32-bit.
If it's zero this makes no difference, but non-zero might come out wrong for
a client with different endianness than the server.

=over

L<http://cgit.freedesktop.org/xorg/xserver/commit/hw/xfree86/dixmods/extmod/xf86vmode.c?id=9edcae78c46286baff42e74bfe26f6ae4d00fe01>

=back

=head1 SEE ALSO

L<X11::Protocol>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/x11-protocol-other/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2017, 2019 Kevin Ryde

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
