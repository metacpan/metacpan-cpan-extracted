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


# /usr/share/doc/x11proto-xext-dev/tog-cup.txt.gz
#
# /usr/include/X11/extensions/cup.h
# /usr/include/X11/extensions/cupproto.h
#
# /usr/include/X11/extensions/Xcup.h
#     Xlib.
#     XcupGetReservedColormapEntries() etc
#
# http://www.xfree86.org/current/specindex.html
# http://www.xfree86.org/current/tog-cup.html
#
# CVE-2007-6428
#     http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2007-6428
#     xfree86 and x.org before 1.4.1 GetReservedColormapEntries read
#     arbitrary memory
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz


BEGIN { require 5 }
package X11::Protocol::Ext::TOG_CUP;
use strict;
use Carp;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 31;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
#use Smart::Comments;


# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 1;
use constant CLIENT_MINOR_VERSION => 0;


#------------------------------------------------------------------------------
# requests

sub _reply_listofcoloritem {
  my ($X, $data) = @_;
  ### CupGetReservedColormapEntries reply: $data

  # use Data::HexDump::XXD;
  # print scalar(Data::HexDump::XXD::xxd($data));
  # print "\n";

  my ($num) = unpack 'x4L', $data;
  $num /= 3;
  ### $num
  ### data len: length($data)

  # obey $num rather than the reply length
  # items start at offset 32
  return map {[unpack 'LSSSC', substr ($data, 20 + 12*$_, 12)]}
    1 .. $num;
}

my $reqs =
  [
   ["CupQueryVersion",  # 0
    sub {
      my ($X, $client_major, $client_minor) = @_;
      ### CupQueryVersion
      return pack 'SS', $client_major, $client_minor;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8SS', $data;
    }],

   ["CupGetReservedColormapEntries",  # 1
    sub {
      my ($X, $screen) = @_;
      ### CupGetReservedColormapEntries ...

      # don't normally bother about arg checking, but it's easy to forget
      # the screen here, and pack() quietly turns undef into 0
      @_ == 2 || croak "CupGetReservedColormapEntries() requires single screen number parameter";

      return pack 'L', $screen;
    },
    \&_reply_listofcoloritem ],

   ["CupStoreColors",  # 2
    sub {  # ($X, $colormap, [$pixel,$red,$green,$blue],...)
      my $X = shift;
      my $colormap = shift;
      return pack('L', $colormap)
        . join('', map {pack 'LSSSxx', @$_} @_);
    },
    \&_reply_listofcoloritem],
  ];

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### TOG-CUP new()
  ### $request_num
  ### $event_num
  ### $error_num

  _ext_requests_install ($X, $request_num, $reqs);

  # Any need to negotiate a version?
  #  my ($major, $minor) = $X->req('CupQueryVersion', 1, 0);
  # if ($major != 1) {
  #   carp "Unrecognised TOG-CUP major version, got $major want 1";
  #   return 0;
  # }
  return bless {
                # major => $major,
                # minor => $minor,
               }, $class;
}

#------------------------------------------------------------------------------
# generic

sub _ext_requests_install {
  my ($X, $request_num, $reqs) = @_;

  $X->{'ext_request'}->{$request_num} = $reqs;
  my $href = $X->{'ext_request_num'};
  my $i;
  foreach $i (0 .. $#$reqs) {
    $href->{$reqs->[$i]->[0]} = [$request_num, $i];
  }
}

1;
__END__

=for stopwords Colormap colormap colormaps arrayref RGB Ryde pre-allocated shareable

=head1 NAME

X11::Protocol::Ext::TOG_CUP - colormap utilization policy extension

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('TOG-CUP')
   or print "TOG-CUP extension not available";

=head1 DESCRIPTION

The TOG-CUP extension helps applications with private colormaps use the same
pixel for the same color in different colormaps.

Using common pixel values, were possible, means that when a private colormap
is in use (C<$x-E<gt>InstallColormap()>, usually done by the window manager)
some of the colours in other windows will still appear correctly.

Note that this extension makes a subtle change to the core
C<$X-E<gt>AllocColor()> and C<$X-E<gt>AllocNamedColor()> requests.  Normally
they allocate the first available pixel, but with TOG-CUP if there's a
matching colour in the default colormap and that same pixel in the target
colormap is free then that pixel is allocated, thus making that colour the
same in the two colormaps.

=head1 REQUESTS

The following are made available with an C<init_extension()> per
L<X11::Protocol/EXTENSIONS>.

    my $bool = $X->init_extension('TOG-CUP');

=over

=item C<($server_major, $server_minor) = $X-E<gt>CupQueryVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like, the returned
C<$server_major> and C<$server_minor> is what the server will do, which
might be different.

The current code supports up to 1.0.  The intention would be to
automatically negotiate in C<init_extension()> if necessary, which it's
currently not.

=item C<@colors = $X-E<gt>CupGetReservedColormapEntries ($screen)>

Return a list of reserved colormap entries in the default colormap of screen
number C<$screen> (an integer 0 upwards).  Each returned element is an
arrayref

    [ $pixel, $red16, $blue16, $green16, $alloc_flags ]

C<$red16>, C<$blue16> and C<$green16> are RGB colour components in the range
0 to 65535.  C<$alloc_flags> is currently unused.

Reserved colours are pre-allocated and unchanging.  The core protocol
specifies C<$X-E<gt>{'black_pixel'}> and C<$X-E<gt>{'white_pixel'}> and
they're included in the result, plus any further colours which might be
reserved.

For example under the MS-DOS graphical overlay manager there's a certain set
of "desktop" colours which a server on that system might treat as reserved.

=item C<@colors = $X-E<gt>CupStoreColors ($colormap, [$pixel,$red16,$green16,$blue16],...)>

Allocate read-only colours in C<$colormap> at particular pixels.

Each argument is an arrayref of desired pixel and RGB colour.
(A C<$do_mask> parameter can be present at the end too but is unused and can
be omitted.)

    [ $pixel, $red16, $blue16, $green16 ]

The desired colour is allocated shareable read-only (like
C<$X-E<gt>AllocColor()>) at the given C<$pixel> if possible, or another if
necessary.  The return is a similar list of arrayref elements, one for each
argument

    [ $pixel, $red16, $blue16, $green16, $alloc_flags ]

The returned C<$pixel> might differ from what was requested.  If the
requested C<$pixel> is already allocated, and it has a different colour,
then another pixel value is chosen.

The returned RGB components are the actual colour shade allocated.  This
might differ if the visual has limited colour resolution (which is likely).

The returned C<$alloc_flags> has bit 0x08 set if the pixel was successfully
allocated, or clear if not.  Other bits in C<$alloc_flags> are currently
unused.

For example

    my @ret = $X->CupStoreColors
                ($colormap,
                 [ 2,  65535,0,0],           # red   
                 [ 3,  0,65535,0],           # green
                 [ 4,  16383,16383,16383]);  # grey

    foreach my $elem (@ret) {
      my ($pixel, $red,$green,$blue, $alloc_ok) = @$elem;
      my $ok = ($alloc_ok & 8 ? "allocated" : "oops, not allocated");
      print "at $pixel actual $red,$green,$blue  $ok\n";
    }

=back

=head1 SEE ALSO

L<X11::Protocol>

Colormap Utilization Policy and Extension, Version 1.0
http://www.xfree86.org/current/tog-cup.html

F</usr/share/doc/x11proto-xext-dev/tog-cup.txt.gz>,
F</usr/share/X11/doc/hardcopy/Xext/tog-cup.PS.gz>

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
