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


# 2.0 bits:
# SetMode two flags fields
# byte_order "Significance" ?

# Protocol 1.0:
#   http://cvsweb.xfree86.org/cvsweb/xc/programs/Xserver/hw/xfree86/doc/man/Attic/XF86DGA.man?rev=3.10&hideattic=0&sortby=log&content-type=text/vnd.viewcvs-markup
#
#   /so/xfree/xfree86-3.3.2.3a/programs/Xserver/hw/xfree86/doc/README.DGA
#   /so/xfree/xfree86-3.3.2.3a/lib/Xxf86dga/XF86DGA.c
#       Xlib
#
#   /so/xfree/xfree86-3.3.2.3a/include/extensions/xf86dga.h
#   /so/xfree/xfree86-3.3.2.3a/include/extensions/xf86dgastr.h
#
#   /usr/include/X11/extensions/xf86dga1const.h
#   /usr/include/X11/extensions/xf86dga1proto.h
#
#   /so/xf86dga/XF86DGA.man
#
#   /so/xfree/xfree86-3.3.2.3a/programs/Xserver/Xext/xf86dga.c
#       server code
#
# Protocol 2.0:
#   /usr/share/doc/xserver-xfree86/README.DGA.gz
#   /so/xfree4/unpacked/usr/share/doc/xserver-xfree86/README.DGA.gz
#
#   /usr/include/X11/extensions/xf86dgaconst.h
#   /usr/include/X11/extensions/xf86dgaproto.h
#
#   /so/xorg/xorg-server-1.10.0/hw/xfree86/dixmods/extmod/xf86dga2.c
#   /so/xorg/xorg-server-1.10.0/hw/xfree86/common/xf86DGA.c
#        server code
#
#   XDGA(3) man page
#   /so/xf86dga/libXxf86dga-1.1.2/src/XF86DGA2.c
#        Xlib
#
# Other:
#   /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz



BEGIN { require 5 }
package X11::Protocol::Ext::XFree86_DGA;
use strict;
use Carp;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 31;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
# use Smart::Comments;


# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 1;
use constant CLIENT_MINOR_VERSION => 0;

#------------------------------------------------------------------------------
# symbolic constants

use constant constants_list =>
  (XDGAPixmapMode =>  ['Large','Small'],
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

# =head1 EVENTS
#
# Protocol version 2.0 sends key, button and pointer motion events selected
# by C<XDGASelectInput()> described above.
#
# Each event has the usual fields
#
#     name             "SyncCounterNotify" etc
#     synthetic        true if from a SendEvent
#     code             integer opcode
#     sequence_number  integer
#
# plus event-specific fields described below.
#
# =over
#
# =item C<XDGAKeyPressEvent>, C<XDGAKeyReleaseEvent>
#
# The "detail", "time" and "state" fields are the same as the core KeyPress
# and KeyRelease events,
#
#     detail           keycode (integer)
#     time             server timestamp (integer)
#     screen           screen number (integer)
#     state            keyboard modifiers (integer shift, control, etc)
#
# =item C<XDGAButtonPressEvent>, C<XDGAButtonReleaseEvent>
#
# The "detail", "time" and "state" fields are the same as the core
# ButtonPress and ButtonRelease events,
#
#     detail           button number 1 to 5
#     time             server timestamp (integer)
#     screen           screen number (integer)
#     state            keyboard modifiers (integer shift, control, etc)
#
# =item C<XDGAMotionEvent>
#
# The "time" and "state" fields are the same as the core key press and
# release events,
#
#     dx               \ pointer move in pixels, integer + or -
#     dy               /
#     time             server timestamp (integer)
#     screen           screen number (integer)
#     state            keyboard modifiers (integer shift, control, etc)
#
# =back

# xf86dgaproto.h struct dgaEvent has INT16 for screen, so "s" here, though
# normally a screen number will be >=0.
#
use constant events_list =>
  do {
    # struct dgaEvent has dx,dy fields for key and button events, but server
    # DGAStealButtonEvent() and DGAStealKeyEvent() always puts 0 in them, so
    # omit.
    #
    my $kb = [ 'xCxxLxxxxsSx16',
               'detail',
               'time',
               'screen',
               'state',
             ];
    (XDGAKeyPress      => $kb,   # +2
     XDGAKeyRelease    => $kb,   # +3
     XDGAButtonPress   => $kb,   # +4
     XDGAButtonRelease => $kb,   # +5

     # struct dgaEvent has a "detail" field for motion event, but server
     # DGAStealMotionEvent() always puts 0 in it, so omit.
     #
     XDGAMotionNotify  =>        # +6
     [ 'xxxxLsssSx16',
       'time',
       'dx',
       'dy',
       'screen',
       'state',
     ])
  };

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
# requests

my $reqs =
  [
   ['XF86DGAQueryVersion',  # 0
    \&_request_empty,
    sub {
      my ($X, $data) = @_;
      ### XF86DGAQueryVersion() reply ...
      return unpack 'x8SS', $data;
    }],

   ['XF86DGAGetVideoLL',  # 1
    \&_request_screen16,
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L4', $data; # (address,width,bank_size,ram_size)
    },
   ],

   ['XF86DGADirectVideo',  # 2
    sub {
      my ($X, $screen, $enable) = @_;
      return pack 'SS', $screen, $enable;
    } ],

   ['XF86DGAGetViewPortSize',  # 3
    \&_request_screen16,
    sub {
      my ($X, $data) = @_;
      return unpack 'x8LL', $data; # (width,height)
    },
   ],

   ['XF86DGASetViewPort',  # 4
    sub {
      shift;  # ($X, $screen, $x, $y)
      return pack 'SxxLL', @_;
    },
   ],

   ['XF86DGAGetVidPage',  # 5
    \&_request_screen16,
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data; # (vidpage)
    },
   ],

   ['XF86DGASetVidPage',  # 6
    sub {
      shift;  # ($X, $screen, $vidpage)
      return pack 'SS', @_;
    },
   ],

   ['XF86DGAInstallColormap',  # 7
    sub {
      my ($X, $screen, $colormap) = @_;
      return pack 'SxxL', $screen, $colormap;
    }],

   ['XF86DGAQueryDirectVideo',  # 8
    \&_request_screen16,
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data; # (flags)
    },
   ],

   ['XF86DGAViewPortChanged',  # 9
    sub {
      shift;  # ($X, $screen, $num_pages)
      return pack 'SS', @_;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data; # (bool)
    } ],


   #---------------------------------------------------------------------------
   # version 2.0

   undef,  # 10
   undef,  # 11

   # =item C<($mode_num =E<gt> $hashref, ...) = $X-E<gt>XDGAQueryModes($screen_num)>
   #
   # Return a list of available DGA modes and information.  Each mode is
   # returned as a pair
   #
   #    $mode_num => $hashref
   #
   # where C<$hashref> contains the following fields
   #
   #     mode_num
   #     byte_order         Significance enum
   #                          "LeastSignificant" or "MostSignificant"
   #     depth              bits per pixel with usable data, eg. 24
   #     bpp                bits per pixel including padding, eg. 32
   #     name               string name of mode from xorg.conf
   #     vsync_num          \ vertical refresh rate as fraction num/den
   #     vsync_den          /   retraces per second (Hertz)
   #     flags              bits
   #                        1    Concurrent Access
   #                        2    Solid Fill Rect
   #                        4    Blit Rect
   #                        8    Blit Trans Rect
   #                        16   Pixmap
   #     image_width        \
   #     image_height       /
   #     pixmap_width       \ size of the video part accessible by
   #     pixmap_height      /   pixmap of XDGASetMode()
   #     bytes_per_scanline
   #     red_mask           \ pixel bit-masks as per a visual
   #     green_mask         |
   #     blue_mask          /
   #     visual_class       VisualClass enum "TrueColor", "PseudoColor", etc
   #     viewport_width     \ size of the visible part of the video
   #     viewport_height    /
   #     viewport_xstep     \ granularity of X,Y position
   #     viewport_ystep     /   for XDGASetViewport()
   #     viewport_xmax      \ maximum X,Y position
   #     viewport_ymax      /   for XDGASetViewport()
   #     viewport_flags
   #
   # The return list can be put into a hash to lookup by mode number,
   #
   #    my %h = $X->XDGAQueryModes($screen_num);
   #    my $info = $h{$mode_num};
   #    print "$mode_num name is ",$info->{'name'},"\n";
   #

   ['XDGAQueryModes',   # 12
    \&_request_card32s,
    sub {
      my ($X, $data) = @_;
      my ($num_modes) = unpack 'x8L', $data;
      my $pos = 32;

      # use Data::HexDump::XXD;
      # print scalar(Data::HexDump::XXD::xxd($data));
      # print "\n";

      return map {my $h = _unpack_info($X,$data,$pos);
                  $pos += 72;
                  ($h->{'num'} => $h)
                } 1 .. $num_modes;
    } ],

   # =item C<(key=E<gt>value,...) = $X-E<gt>XDGASetMode($screen_num, $mode_num, $pixmap)>
   #
   # Put screen C<$screen_num> into DGA mode C<$mode_num>.  Or if
   # C<$mode_num> is 0 then leave DGA mode.
   #
   # C<$pixmap> is a new integer XID which is for X protocol access to the
   # video memory while in DGA mode.  This is only possible if the "Pixmap"
   # bit is set in the mode flags (C<XDGAQueryModes()> above).
   #
   # The return is a list of key/value pairs with mode information.  The
   # fields are C<XDGAQueryModes()> above for C<$mode_num>, and in addition
   #
   #     offset     => offset into video memory (integer)
   #     set_flags  => ... (integer)
   #
   ['XDGASetMode',  # 13
    sub {
      shift;  # ($X, $screen_num, $mode_num, $pixmap)
      return pack 'L3', @_;
    },
    sub {
      my ($X, $data) = @_;
      my ($offset, $flags) = unpack 'x8LL', $data;
      my $h = _unpack_info($X, $data, 32);
      return (offset    => $offset,
              set_flags => $flags,
              %$h);
    },
   ],

   # =item C<$X-E<gt>XDGASetViewport($screen_num, $x, $y, $flags)>
   #
   # Set the C<$x,$y> position of the top-left corner of the visible part of
   # the video memory.
   #
   # The hardware might support only certain positions, as per
   # C<viewport_xstep>,C<viewport_ystep> fields of C<XDGAQueryModes()>
   # above.  C<$x,$y> will round them to the next step if necessary.
   #
   # C<$flags> (an integer) can be bits
   #
   #     1    Flip Immediate
   #     2    Flip Retrace
   #
   # Flip retrace means to queue the viewport change to occur on the next
   # vertical retrace, so as not to flicker in the middle of the screen.
   #
   [ 'XDGASetViewport',  # 14
     sub {
       shift;  # ($X, $screen, $x, $y, $flags)
       return pack 'LSSL', @_;
     },
   ],

   # =item C<$X-E<gt>XDGAInstallColormap($screen_num, $colormap)>
   #
   # Install C<$colormap> in DGA mode.  The core
   # C<$X-E<gt>InstallColormap()> cannot be used in DGA mode.
   #
   [ 'XDGAInstallColormap', # 15
     sub {
       shift; # ($X, $screen, $colormap)
       return pack 'SxxL', @_;
     } ],

   # =item C<$X-E<gt>XDGASelectInput($screen_num, $event_mask)>
   #
   # Select key, button and mouse motion events while in DGA mode.
   # C<$event_mask> is as per the core C<$X-E<gt>pack_event()> with mask
   # bits
   #
   #     KeyPress
   #     KeyRelease
   #     ButtonPress
   #     ButtonRelease
   #     PointerMotion
   #     Button1Motion
   #     Button2Motion
   #     Button3Motion
   #     Button4Motion
   #     Button5Motion
   #     ButtonMotion
   #
   [ 'XDGASelectInput', # 16
     \&_request_card32s ],  # ($X, $screen, $mask)

   # =item C<$X-E<gt>XDGAFillRectangle($screen_num, $x,$y, $width,$height, $pixel)>
   #
   # Fill the rectangle C<$x,$y, $width,$height> with pixel value C<$pixel>.
   #
   # This request is supported if the "Solid Fill Rect" bit is set in the
   # mode flags (C<XDGAQueryModes()> above).
   #
   [ 'XDGAFillRectangle', # 17
     sub {
       shift;  # ($X, $screen, $x, $y, $width, $height, $color)
       return pack 'LSSSSL', @_;
     } ],

   # =item C<$X-E<gt>XDGACopyArea($screen_num, $src_x,$src_y, $width,$height, $dst_x,$dst_y)>
   #
   # Copy the rectangle C<$src_x,$src_y, $width,$height> to
   # C<$dst_x,$dst_y>.
   #
   # This request is supported if the "Blit Rect" bit is set in the mode
   # flags (C<XDGAQueryModes()> above).
   #
   [ 'XDGACopyArea',  # 18
     sub {
       shift;  # ($X, $screen, $src_x,$src_y, $width,$height, $dst_x,$dst_y)
       return pack 'LS*', @_;  # x,y's are CARD16s, so unsigned
     } ],

   # This request is supported if the "Blit Trans Rect" bit is set in the
   # mode flags (C<XDGAQueryModes()> above).
   #
   [ 'XDGACopyTransparentArea',  # 19
     sub {
       shift;
       # ($X, $screen, $src_x,$src_y, $width,$height, $dst_x,$dst_y, $key)
       return pack 'LS6L', @_;  # x,y's are CARD16s, so unsigned
     } ],

   # =item C<$status = $X-E<gt>XDGAGetViewportStatus($screen_num)>
   #
   [ 'XDGAGetViewportStatus',  # 20
     \&_request_card32s, # ($X,$screen_num)
     sub {
       my ($X, $data) = @_;
       return unpack 'x8L', $data;
     } ],

   # =item C<$X-E<gt>XDGASync($screen_num)>
   #
   # Block until all server drawing to the video memory is complete, either
   # ordinary X drawing or the Copy and Fill requests above.
   #
   # The server or hardware might queue drawing requests.  C<XDGASync()> is
   # a round-trip which ensures the video memory contains all drawing
   # requested.
   #
   # If "Concurrent Access" is set in the mode flags (C<XDGAQueryModes()>
   # above) then a client and the server can act on the video concurrently,
   # though care would be needed not to make a mess of each other's drawing.
   #
   # If "Concurrent Access" is not set then the client and server must not
   # act on the video concurrently.  The client must C<XDGASync()> to ensure
   # the server has finished.
   #
   [ 'XDGASync',  # 21
     \&_request_card32s, # ($X,$screen_num)
     sub {  # ($X, $data)  empty
       return;
     } ],

   # =item C<($device_name, $addr, $size, $offset, $extra) = $X-E<gt>XDGAOpenFramebuffer($screen_num)>
   #
   # Get the location of the video RAM memory framebuffer.  The client can
   # use this to open the framebuffer by an C<mmap()> or other means for use
   # when in DGA mode.
   #
   # C<$device_name> (a string) is the name of a device file to access the
   # framebuffer.  If it's an empty string then the framebuffer is in
   # physical memory (so whatever system-dependent device F</dev/mem> or
   # F</dev/pmem> etc).
   #
   # C<$addr> (an integer) is the address within the device or physical
   # memory.  This might be 64-bits on a 64-bit system.  If Perl has only
   # 32-bit UV when the address is 64-bits then C<$addr> is returned as a
   # C<Math::BigInt>.
   #
   # C<$offset> is an offset from C<$addr>.  C<$size> is the size of the
   # framebuffer memory, in bytes, at that C<$addr+$offset> location.
   #
   # C<$extra> is extra information.  It can be a bit
   #
   #     1      client will need root permissions
   #
   [ 'XDGAOpenFramebuffer',  # 22
     \&_request_card32s,
     sub {
       my ($X, $data) = @_;
       ### head: unpack('CCSL', $data)
       ### data: unpack('x8L5', $data)
       ### devname: substr($data,32)

       # (devlen,mem1,mem2,size,offset,extra)
       my ($length, $mem_lo, $mem_hi, @rest) = unpack 'x4L6', $data;

       # "\0" terminated within $length many CARD32s
       (my $devname = substr($data,32,4*$length)) =~ s/\0.*//;

       return ($devname,
               _hilo_to_card64($mem_hi,$mem_lo),
               @rest);
     } ],

   # =item C<$X-E<gt>XDGACloseFramebuffer($screen_num)>
   #
   # Tell the server that the client is no longer accessing the framebuffer
   # memory of C<XDGAOpenFramebuffer()> above.
   #
   [ 'XDGACloseFramebuffer', # 23
     \&_request_card32s ],

   # =item C<$X-E<gt>XDGASetClientVersion($client_major, $client_minor)>
   #
   [ 'XDGASetClientVersion', # 24
     sub {
       shift; # ($X, $client_major, $client_minor)
       return pack 'SS', @_;
     } ],

   # =item C<($x,$y) = $X-E<gt>XDGAChangePixmapMode($screen_num, $x,$y, $mode)>
   #
   # Change the position of the C<$pixmap> of C<XDGASetMode()> within the
   # video memory.
   #
   # C<$mode> is a XDGAPixmapMode enum,
   #
   #     "Large" (0)    pixmap_width,pixmap_height
   #     "Small" (1)    viewport_width,viewport_height and $x,$y
   #
   # Large mode means the pixmap is as big as possible, the C<pixmap_width>
   # and C<pixmap_height> per the mode info.
   #
   # Small mode means the pixmap is only the size of the viewport,
   # C<viewport_width> and C<viewport_height> per the mode info.  In this
   # case C<$x> and C<$y> are the top-left corner of the pixmap within the
   # full memory.  The position can be different from the visible viewport,
   # but it must be within the C<pixmap_width>,C<pixmap_height> limit.
   #
   [ 'XDGAChangePixmapMode',  # 25
     sub {
       my ($X, $screen_num, $x, $y, $mode) = @_;
       return pack 'LSSL',
         $screen_num, $x, $y, $X->interp('XDGAPixmapMode',$mode);
     },
     sub {
       my ($X, $data) = @_;
       return unpack 'x8SS', $data; # (x,y)
     },
   ],

   # =item C<$X-E<gt>XDGACreateColormap($screen_num, $colormap, $mode_num, $alloc)>
   #
   # Create C<$colormap> (a new XID) as a colormap for use with DGA
   # C<$screen_num> and C<$mode_num>.
   #
   # This is similar to the core C<CreateColormap()>, but there might not
   # be a core visual corresponding to C<$mode_num> depth etc, hence this
   # separate way to create a colormap.
   #
   # C<$colormap> can be used the same as core protocol colormaps and can
   # be freed with C<$X-E<gt>FreeColormap($colormap)>.
   #
   #
   [ 'XDGACreateColormap',  # 26
     sub {
       shift;  # ($X, $screen, $id, $mode, $alloc)
       return pack 'LLLCxxx', @_;
     } ],
  ];

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### XF86DGA new() ...

  my $self = bless { }, $class;
  _ext_requests_install ($X, $request_num, $reqs);
  _ext_constants_install ($X, [ $self->constants_list ]);

  my ($server_major, $server_minor) = $X->XF86DGAQueryVersion;
  $self->{'major'} = $server_major;
  $self->{'minor'} = $server_minor;

  _ext_const_error_install ($X, $error_num,
                            'XF86DGAClientNotLocal',        # 0
                            'XF86DGANoDirectVideoMode',     # 1
                            'XF86DGAScreenNotActive',       # 2
                            'XF86DGADirectNotActivated',    # 3
                            ($server_major >= 2
                             ? 'XF86DGAOperationNotSupported' # 4
                             : ()));
  if ($server_major >= 2) {
    _ext_events_install ($X,
                         $event_num+2,  # to start at $event_num+2
                         [ $self->events_list ]);
  }

  return $self;
}

sub _unpack_info {
  my ($X, $data, $pos) = @_;
  my %h;
  @h{qw(byte_order depth
        num bpp name_len
        vsync_num vsync_den flags
        image_width image_height pixmap_width pixmap_height
        bytes_per_scanline red_mask green_mask blue_mask
        visual_class
        viewport_width viewport_height
        viewport_xstep viewport_ystep
        viewport_xmax viewport_ymax
        viewport_flags
      )}
    = unpack 'C2S3L3S4L4SxxS6L', substr($data,$pos,72);
  $pos += 72;
  ### %h

  # name_len a multiple of 4, string \0 nul-terminated
  # within that length
  my $name_len = delete $h{'name_len'};
  ($h{'name'} = substr($data, $pos, $name_len)) =~ s/\0.*//;
  # cf unpack 'Z', new in perl 5.6
  # $h{'name'} = unpack 'Z*', substr($data, $pos, $name_len);
  $pos += $name_len;
  ### $name_len
  ### name: $h{'name'}

  $h{'byte_order'}   = $X->interp('Significance', $h{'byte_order'});
  $h{'visual_class'} = $X->interp('VisualClass',  $h{'visual_class'});

  return \%h;
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
  ### _hilo_to_sv(): "$hi $lo, result ".(($hi << 32) + $lo)
  return ($hi << 32) + $lo;
}
1;
HERE
  } else {
     eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;
sub _hilo_to_card64 {
  my ($hi,$lo) = @_;
  if ($hi) {
     require Math::BigInt;
     return Math::BigInt->new($hi)->blsft(32)->badd($lo);
  } else {
     return $lo;
  }
}
1;
HERE
  }
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

sub _request_empty {
  # ($X)
  ### _request_empty() ...
  if (@_ > 1) {
    croak "No parameters in this request";
  }
  return '';
}

sub _ext_requests_install {
  my ($X, $request_num, $reqs) = @_;

  $X->{'ext_request'}->{$request_num} = $reqs;
  my $href = $X->{'ext_request_num'};
  my $i;
  foreach $i (0 .. $#$reqs) {
    if (defined $reqs->[$i]) {
      $href->{$reqs->[$i]->[0]} = [$request_num, $i];
    }
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

=for stopwords XID Ryde XFree86 DGA XFree86-DGA eg viewport colormap multi-buffering N-multi-buffering

=head1 NAME

X11::Protocol::Ext::XFree86_DGA - direct video memory access

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('XFree86-DGA')
   or print "XFree86-DGA extension not available";

=head1 DESCRIPTION

The XFree86-DGA extension provides direct access to the video RAM of the
server display.  A client program running on the same machine can use this
to read or write directly instead of going through the X protocol.

Accessing video memory will require some system-dependent trickery.  Under
the Linux kernel for example video RAM is part of the F</dev/mem> physical
address space and can be brought into program address space with an
C<mmap()> or accessed with C<sysread()> and C<syswrite()>.  This normally
requires root permissions.

The requests offered here are only XFree86-DGA version 1.0 as yet and they
don't say anything about the pixel layout etc in the memory -- that has to
be divined separately.  (Version 2.0 has more for that.)

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $ext_available = $X->init_extension('XFree86-DGA');

=head2 XFree86-DGA 1.0

=over

=item C<($server_major, $server_minor) = $X-E<gt>XF86DGAQueryVersion()>

Return the DGA protocol version implemented by the server.

=item C<$flags = $X-E<gt>XF86DGAQueryDirectVideo ($screen_num)>

Get flags describing direct video access on C<$screen_num> (integer 0
upwards).  The only flag bit is

    0x0001   direct video available

It's possible to have the extension available but no direct video on a
particular screen, or even on no screens at all.  When no direct video the
requests below give protocol error C<XF86DGANoDirectVideoMode>.

=item C<($address, $width, $bank_size_bytes, $ram_size_kbytes) = $X-E<gt>XF86DGAGetVideoLL ($screen_num)>

Return the location and size of the video memory for C<$screen_num> (integer
0 upwards).

C<$address> is a raw physical 32-bit address as an integer.  C<$width> is in
pixels.

C<$bank_size_bytes> is the size in bytes accessible at a given time.
C<$ram_size_kbytes> is the total memory in 1024 byte blocks.  If
C<$ram_size_kbytes*1024> is bigger than C<$bank_size_bytes> then
C<$X-E<gt>XF86DGASetVidPage()> below must be used to switch among the banks
to access all the RAM.

=item C<$X-E<gt>XF86DGADirectVideo ($screen_num, $flags)>

Enable or disable direct video access on C<$screen_num> (integer 0 upwards).
C<$flags> is bits

    0x0002    enable direct video graphics
    0x0004    enable mouse pointer reporting as relative
    0x0008    enable direct keyboard event reporting

When direct video graphics is enabled (bit 0x0002) the server gives up
control to the client program.

If the graphics card doesn't have a direct video mode then an
C<XF86DGANoDirectVideoMode> error results, or if the screen is not active
(eg. switched away to a different virtual terminal) then
C<XF86DGAScreenNotActive>.

=item C<($width, $height) = $X-E<gt>XF86DGAGetViewPortSize ($screen_num)>

Get the size of the viewport on C<$screen_num> (integer 0 upwards).  This is
the part of the video memory actually visible on the monitor.  The memory
might be bigger than the monitor.

=item C<$X-E<gt>XF86DGASetViewPort ($screen_num, $x, $y)>

Set the coordinates of the top-left corner of the visible part of the video
memory on C<$screen_num> (integer 0 upwards).

This can be used when the video memory is bigger than the monitor to pan
around that bigger area.  It can also be used for some double-buffering to
display one part of memory while drawing to another.

=item C<$vidpage = $X-E<gt>XF86DGAGetVidPage ($screen_num)>

=item C<$X-E<gt>XF86DGASetVidPage ($screen_num, $vidpage)>

Get or set the video page (bank) on C<$screen_num> (integer 0 upwards).
C<$vidpage> is an integer 0 upwards.

This is used to access all the RAM when when the bank size is less than the
total memory size (per C<XF86DGAGetVideoLL()> above).

=item C<$vidpage = $X-E<gt>XF86DGAInstallColormap ($screen_num, $colormap)>

Set the colormap on C<$screen_num> to C<$colormap> (integer XID).

This can only be used while direct video is enabled (per
C<XF86DGADirectVideo()> above) or an error C<XF86DGAScreenNotActive> or
C<XF86DGADirectNotActivated> results.

=item C<$bool = $X-E<gt>XF86DGAViewPortChanged ($screen_num, $num_pages)>

Check whether a previous C<XF86DGASetViewPort()> on C<$screen_num> (integer
0 upwards) has completed, meaning a vertical retrace has occurred since that
viewport location was set.

This is used for double-buffering (or N-multi-buffering) to check a viewport
change has become visible.  C<$num_pages> should be 2 for double-buffering
and can be higher for multi-buffering.

=back

=head1 SEE ALSO

L<X11::Protocol>

F</usr/share/doc/xserver-xfree86/README.DGA.gz>

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
