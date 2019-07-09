# id values as numbers ?
# struct forms ?

# XVideoShmPutImage arg order ...



# Copyright 2012, 2013, 2014, 2017 Kevin Ryde

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
package X11::Protocol::Ext::XVideo;
use strict;
use Carp;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 31;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
#use Smart::Comments;


# /usr/share/doc/x11proto-video-dev/xv-protocol-v2.txt.gz
#
# /usr/include/X11/extensions/Xv.h
# /usr/include/X11/extensions/Xvproto.h
#
# /usr/share/xcb/xv.xml
# http://cgit.freedesktop.org/xcb/proto/tree/src/xv.xml
#     xcb
#
# /usr/include/X11/extensions/Xvlib.h
#     Xlib.
#
# /so/xorg/xorg-server-1.10.0/Xext/xvdisp.c
#     server source
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
#
# /usr/include/X11/extensions/vldXvMC.h
# /usr/include/X11/extensions/XvMC.h
# /usr/include/X11/extensions/XvMCproto.h

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 2;
use constant CLIENT_MINOR_VERSION => 1;


#------------------------------------------------------------------------------
# symbolic constants

my %const_arrays
  = (
     # not the same as the core GrabStatus enum
     XVideoGrabStatus => [ 'Success',        # 0
                           'BadExtension',   # 1 internal??
                           'AlreadyGrabbed', # 2
                           'InvalidTime',    # 3
                           'BadReply',       # 4 internal??
                           'BadAlloc',       # 5 internal??
                         ],
     
     XVideoNotifyReason => ['Started',   # 0
                            'Stopped',   # 1
                            'Busy',      # 2
                            'Preempted', # 3
                            'HardError', # 4
                           ],
     XVideoScanlineOrder => ['TopToBottom', # 0
                             'BottomToTop', # 1
                            ],
     XVideoImageFormatType => [ 'RGB', # 0
                                'YUV', # 1
                              ],
     XVideoImageFormatType => [ 'RGB', # 0
                                'YUV', # 1
                              ],
    );

my %const_hashes
  = (map { $_ => { X11::Protocol::make_num_hash($const_arrays{$_}) } }
     keys %const_arrays);

#------------------------------------------------------------------------------
# events

my $XVideoNotify_event
  = [ 'xCxxLLLx16',
      ['reason','XVideoNotifyReason'],
      'time',
      'drawable',
      'port',
    ];
my $XVideoPortNotify_event
  = [ 'xxxxLLLlx12',
      'time',
      'port',
      'attribute', # atom
      'value',     # INT32
    ];

#------------------------------------------------------------------------------
# requests

my $reqs =
  [
   ['XVideoQueryExtension',  # 0
    \&_request_empty,
    sub {
      my ($X, $data) = @_;
      return unpack 'x8SS', $data;
    }],
   
   ['XVideoQueryAdaptors',  # 1
    \&_request_card32s,  # ($X, $window)
    sub {
      my ($X, $data) = @_;
      ### XVideoQueryAdaptors() reply ...
      
      # use Data::HexDump::XXD;
      # print scalar(Data::HexDump::XXD::xxd($data));
      # print "\n";
      
      my ($num_adaptors) = unpack 'x8S', $data;
      ### $num_adaptors
      
      my $pos = 32;
      my @ret;
      foreach (1 .. $num_adaptors) {
        ### $pos
        my ($port_base, $name_len, $num_ports, $num_formats, $type)
          = unpack 'LSSSC', substr($data,$pos,12);
        $pos += 12;
        
        my $name = substr($data,$pos,$name_len);
        $pos += $name_len + X11::Protocol::padding($name_len);
        
        my @formats;
        foreach (1 .. $num_formats) {
          my %h;
          @h{'visual','depth'} = unpack 'LC', substr($data,$pos,8);
          push @formats, \%h;
          $pos += 8;
        }
        
        push @ret, { port_base => $port_base,
                     name      => $name,
                     num_ports => $num_ports,
                     formats   => \@formats,
                     type      => $type };
      }
      return @ret;
    } ],
   
   ['XVideoQueryEncodings',  # 2
    \&_request_card32s,  # ($X, $port)
    sub {
      my ($X, $data) = @_;
      ### XVideoQueryEncodings() reply length: length($data)
      
      # use Data::HexDump::XXD;
      # print scalar(Data::HexDump::XXD::xxd($data));
      # print "\n";
      
      my ($num_encodings) = unpack 'x8S', $data;
      ### $num_encodings
      
      my $pos = 32;
      my @ret;
      foreach (1 .. $num_encodings) {
        ### $pos
        my ($encoding, $name_len,
            $width,$height,
            $rate_numerator,$rate_denominator)
          = unpack 'LSSSxxLL', substr($data,$pos,20);
        $pos += 20;
        
        my $name = substr($data,$pos,$name_len);
        $pos += $name_len + X11::Protocol::padding($name_len);
        
        push @ret, { encoding         => $encoding,
                     name             => $name,
                     width            => $width,
                     height           => $height,
                     rate_numerator   => $rate_numerator,
                     rate_denominator => $rate_denominator,
                   };
      }
      return @ret;
    }],
   
   ['XVideoGrabPort',  # 3
    sub {
      my ($X, $port, $time) = @_;
      return pack 'LL', $port, _num_time($time);
    },
    sub {
      my ($X, $data) = @_;
      my ($status) = unpack 'xC', $data;
      return $X->interp('XVideoGrabStatus',$status);
    } ],
   
   ['XVideoUngrabPort',  # 4
    sub {
      my ($X, $port, $time) = @_;
      return pack 'LL', $port, _num_time($time);
    } ],
   
   do {
     my $put = sub {
       shift;
       # ($X, $port, $drawable, $gc,
       #  $vid_x,$vid_y,$vid_w,$vid_h,
       #  $drw_x,$drw_y,$drw_w,$drw_h)
       return pack 'LLLssSSssSS', @_;
     };
     
     (
      ['XVideoPutVideo',  # 5
       $put ],
      
      ['XVideoPutStill',  # 6
       $put ],
      
      ['XVideoGetVideo',  # 7
       $put ],
      
      ['XVideoGetStill',  # 8
       $put ],
     )
   },
   
   ['XVideoStopVideo',  # 9
    \&_request_card32s ],
   
   do {
     my $select = sub {
       shift; # ($X, $drawable, $onoff)
       return pack 'LCxxx', @_;
     };
     
     (
      ['XVideoSelectVideoNotify',  # 10
       $select ],
      
      ['XVideoSelectPortNotify',  # 11
       $select ],
     )
   },
   
   ['XVideoQueryBestSize',  # 12
    sub {
      shift; # ($X, $port, $vid_w,$vid_h, $drw_w,$drw_h, $motion)
      return pack 'LSSSSCxxx', @_;
    } ],
   
   ['XVideoSetPortAttribute',  # 13
    sub {
      shift; # ($X, $port, $atom, $value)
      return pack 'LLl', @_;
    } ],
   
   ['XVideoGetPortAttribute',  # 14
    sub {
      shift; # ($X, $port, $atom)
      return pack 'Ll', @_;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8l', $data;
    }],
   
   ['XVideoQueryPortAttributes',  # 15
    \&_request_card32s,
    sub {
      my ($X, $data) = @_;
      my ($num_attributes, $text_len) = unpack 'x8LL', $data;
      
      my $pos = 32;
      my @ret;
      foreach (1 .. $num_attributes) {
        my %h;
        (@h{'flags','min','max'}, my $name_len)
          = unpack 'LllL', substr($data,$pos,16);
        $pos += 16;
        
        $h{'name'} = unpack 'Z*', substr($data,$pos,$name_len);
        $pos += $name_len + X11::Protocol::padding($name_len);
        
        push @ret, \%h;
      }
      return @ret;
    }],
   
   ['XVideoListImageFormats',  # 16
    \&_request_card32s,
    sub {
      my ($X, $data) = @_;
      my ($num_attributes, $text_len) = unpack 'x8LL', $data;
      
      # use Data::HexDump::XXD;
      # print scalar(Data::HexDump::XXD::xxd($data));
      # print "\n";
      
      my $pos = 32;
      my @ret;
      foreach (1 .. $num_attributes) {
        my %h;
        @h{ # hash slice
          qw(id
             type
             byte_order
             guid
             bpp
             num_planes
             
             depth
             
             red_mask
             green_mask
             blue_mask
             format
             
             y_sample_bits
             u_sample_bits
             v_sample_bits
             horz_y_period
             horz_u_period
             horz_v_period
             vert_y_period
             vert_u_period
             vert_v_period
             
             comp_order
             scanline_order
           )} = unpack 'LCCxxa16CCxxCxxxLLLCxxxL9Z32C', substr($data,$pos,128);
        $pos += 128;
        
        $h{'type'}
          = $X->interp('XVideoImageFormatType', $h{'type'});
        $h{'scanline_order'}
          = $X->interp('XVideoScanlineOrder', $h{'scanline_order'});
        $h{'byte_order'}
          = $X->interp('Significance', $h{'byte_order'});
        
        push @ret, \%h;
      }
      return @ret;
    }],
   
   ['XVideoQueryImageAttributes',  # 17
    sub {
      shift; # ($X, $port, $image_id, $width, $height)
      return pack 'LLSS', @_;
    },
    sub {
      my ($X, $data) = @_;
      my ($num_planes, $data_size, $width, $height) = unpack 'x8LLSS', $data;
      return ($data_size, $width, $height,
              unpack "L$num_planes", substr($data,32));
    }],
   
   ['XVideoPutImage',  # 18
    sub {
      shift;
      # ($X, $port, $drawable, $gc, $id,
      #  $src_x,$src_y,$src_w,$src_h,
      #  $drw_x,$drw_y,$drw_w,$drw_h,
      #  $width,$height)
      return pack 'LLLLssSSssSSSS', @_;
    } ],
   
   # FIXME: args cf ShmPutImage ?
   ['XVideoShmPutImage',  # 19
    sub {
      shift;
      # ($X, $port, $drawable, $gc, $shmseg, $id, $offset
      #  $src_x,$src_y,$src_w,$src_h,
      #  $drw_x,$drw_y,$drw_w,$drw_h,
      #  $width,$height, $send_event)
      return pack 'LLLLLLssSSssSSSS', @_;
    } ],
  ];

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### XVideo new()

  # Constants
  %{$X->{'ext_const'}}     = (%{$X->{'ext_const'}     ||= {}}, %const_arrays);
  %{$X->{'ext_const_num'}} = (%{$X->{'ext_const_num'} ||= {}}, %const_hashes);

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  # Errors
  _ext_const_error_install ($X, $error_num,
                            'XVideoPort',     # 0
                            'XVideoEncoding', # 1

                            # FIXME: this one in new enough protocol ?
                            'XVideoControl',  # 2
                           );

  # Events
  $X->{'ext_const'}{'Events'}[$event_num] = 'XVideoNotify';
  $X->{'ext_events'}[$event_num] = $XVideoNotify_event;
  $event_num++;
  $X->{'ext_const'}{'Events'}[$event_num] = 'XVideoPortNotify';
  $X->{'ext_events'}[$event_num] = $XVideoPortNotify_event;

  return bless { }, $class;
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
sub _request_card32s {
  shift;
  ### _request_card32s(): @_
  return pack 'L*', @_;
}

sub _num_time {
  my ($time) = @_;
  if (defined $time && $time eq 'CurrentTime') {
    return 0;
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

1;
__END__

=for stopwords XID Ryde

=head1 NAME

X11::Protocol::Ext::XVideo - video modes

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

=item C<($server_major, $server_minor) = $X-E<gt>XVideoQueryVersion ()>

Return the DGA protocol version implemented by the server.

=item C<@adaptors = $X-E<gt>XVideoQueryAdaptors ($window)>

Return a list of available video adaptors

    { name      => string,
      port_base => integer,
      num_ports => integer,
      type      => integer bits,
      formats   => [ { visual => integer visual ID,
                       depth  => integer,
                     },
                     ...
                   ],
    }

C<name> is a string describing the adaptor.

C<port_base> is the first port number for use as C<$port> below, and there
are C<num_ports> many ports.

The C<type> bits give the adaptor capabilities,

    0x01    Input
    0x02    Output
    0x04    Video
    0x08    Still
    0x10    Image

C<formats> is an arrayref of hashrefs giving the supported visuals for the
adaptor.  Each C<depth> is the depth of the visual, the same as in the core
C<$X> information.

=item C<@encodings = $X-E<gt>XVideoQueryEncodings ($port)>

        { encoding         => $encoding,
          name             => string,
          width            => integer,
          height           => integer,
          rate_numerator   => integer,
          rate_denominator => integer,
        }

=item C<$status = $X-E<gt>XVideoGrabPort ($port, $time)>

Grab C<$port>.  This means only video requests from the grabbing client are
processed.  The C<$status> result is an XVideoGrabStatus enum string

    "Success"             # 0
    "AlreadyGrabbed"      # 2
    "InvalidTime"         # 3

"AlreadyGrabbed" means another client has grabbed the port.  "InvalidTime"
means the given C<$time> is older than one of the following actions on the
port by another client,

    GrabPort, UngrabPort, PutVideo, PutStill, GetVideo, GetStill

C<$time> mechanism prevents a lagged client from making a mess of subsequent
actions by another client.  C<"CurrentTime"> can be given to skip the time
check.

=item C<$X-E<gt>XVideoUngrabPort ($port, $time)>

Ungrab C<$port>, allowing other clients to use it.  If C<$time> is before
than latest action on C<$port> then the request is ignored.
C<"CurrentTime"> can be given to always ungrab.

=item C<$X-E<gt>XVideoPutVideo ($port, $drawable, $gc, $video_x,$video_y,$video_width,$video_height, $drawable_x,$drawable_y,$drawable_w,$drawable_h)>

=item C<$X-E<gt>XVideoPutStill ($port, $drawable, $gc, $video_x,$video_y,$video_width,$video_height, $drawable_x,$drawable_y,$drawable_w,$drawable_h)>

=item C<$X-E<gt>XVideoGetVideo ($port, $drawable, $gc, $video_x,$video_y,$video_width,$video_height, $drawable_x,$drawable_y,$drawable_w,$drawable_h)>

=item C<$X-E<gt>XVideoGetStill ($port, $drawable, $gc, $video_x,$video_y,$video_width,$video_height, $drawable_x,$drawable_y,$drawable_w,$drawable_h)>

=item C<$X-E<gt>XVideoStopVideo ($port, $drawable)>

Stop any video for C<$port> and C<$drawable>.  If C<$port> is on a different
drawable or not running at all then the request is ignored.

=item C<$X-E<gt>XVideoSelectVideoNotify ($drawable, $onoff)>

=item C<$X-E<gt>XVideoSelectPortNotify ($drawable, $onoff)>

=item C<$X-E<gt>XVideoQueryBestSize ($port, $video_width,$video_height, $drawable_w,$drawable_h, $motion)>

=item C<$X-E<gt>XVideoSetPortAttribute ($port, $atom, $value)>

=item C<$value = $X-E<gt>XVideoGetPortAttribute ($port, $atom)>

Get or set an attribute on C<$port>.  The attribute name is C<$atom> (an
atom integer) and C<$value> is a signed INT32.

=item C<@attrs = $X-E<gt>XVideoQueryPortAttributes ($port)>

Return a list of available attributes on C<$port>.  Each return value is a
hashref

    {
      name  => string,
      flags => integer,
      min   => integer,
      max   => integer,
    }

The flag bits are

    0x01   attribute is gettable
    0x02   attribute is settable

=item C<@formats = $X-E<gt>XVideoListImageFormats ($port)>

    {
      id          => integer,
      type        => enum "RGB" or "YUV"
      byte_order  => enum "LeastSignificant" or "MostSignificant"
      guid        =>
      bpp         =>
      num_planes  =>

      depth       => integer,

      red_mask    => integer,
      green_mask  => integer,
      blue_mask   => integer,
      format      => integer,

      y_sample_bits => integer,
      u_sample_bits => integer,
      v_sample_bits => integer,
      horz_y_period => integer,
      horz_u_period => integer,
      horz_v_period => integer,
      vert_y_period => integer,
      vert_u_period => integer,
      vert_v_period => integer,

      comp_order     => ,
      scanline_order => enum "TopToBottom" or "BottomToTop"

    }

=item C<($data_size, $width, $height, @...) = $X-E<gt>XVideoQueryImageAttributes ($port, $image_id, $width, $height)>

=item C<$X-E<gt>XVideoPutImage ($port, $drawable, $gc, $id, $src_x,$src_y,$src_width,$src_height, $drawable_x,$drawable_y,$drawable_w,$drawable_h, $width,$height)>

=item C<$X-E<gt>XVideoShmPutImage ($port, $drawable, $gc, $shmseg, $id, $offset, $video_x,$video_y,$video_width,$video_height, $drawable_x,$drawable_y,$drawable_w,$drawable_h)>

=back

=head1 SEE ALSO

L<X11::Protocol>

F</usr/share/doc/x11proto-video-dev/xv-protocol-v2.txt.gz>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/x11-protocol-other/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2017 Kevin Ryde

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
