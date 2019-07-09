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
package X11::Protocol::Ext::XINERAMA;
use strict;
use Carp;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 31;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
#use Smart::Comments;

# /usr/include/X11/extensions/panoramiXproto.h
#    Protocol structs etc.
#    http://cgit.freedesktop.org/xorg/proto/xineramaproto/tree/panoramiXproto.h
#
# /usr/include/X11/extensions/Xinerama.h
# /usr/include/X11/extensions/panoramiXext.h
#    Xlib.
#
# http://www.kernel.org/doc/als1999/Conference/IMcCartney/xinerama.html
#
# XINERAMA 1.0 in X11R6.4
# XINERAMA 1.1 in X11R6.7
#

### XINERAMA.pm loads

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 1;
use constant CLIENT_MINOR_VERSION => 1;

my $reqs =
  [
   [ 'PanoramiXQueryVersion',  # 0
     sub {
       my ($X, $major, $minor) = @_;
       ### PanoramiXQueryVersion
       return pack 'CCxx', $major, $minor;
     },
     sub {
       my ($X, $data) = @_;
       return unpack 'x8SS', $data;
     }],

   [ 'PanoramiXGetState',  # 1
     \&_request_xids, # ($X, $window)
     sub {
       my ($X, $data) = @_;
       ### PanoramiXGetState reply
       ### state and window: unpack 'xCx6L', $data

       # Reply "window" field may be set only in XINERAMA 1.1, not the
       # X11R6.4 1.0.  It's a copy of the request, so think can ignore.
       return unpack 'xC', $data;
     }],

   [ 'PanoramiXGetScreenCount',  # 2
     \&_request_xids, # ($X, $window)
     sub {
       my ($X, $data) = @_;
       ### PanoramiXGetScreenCount reply: unpack "C*", $data
       ### count and window: unpack 'xCx6L', $data

       # Reply "window" field may be set only in XINERAMA 1.1, not the
       # X11R6.4 1.0.  It's a copy of the request, so think can ignore.
       return unpack 'xC', $data;
     }],

   [ 'PanoramiXGetScreenSize',  # 3
     # ($X, $window, $screen)
     # $screen is an integer not an xid, so ought not allow 'None' there
     \&_request_xids,
     sub {
       my ($X, $data) = @_;
       ### PanoramiXGetScreenSize reply
       ### w,h,win,screen: unpack 'x8L*', $data

       # Reply "window" and "screen" fields may be set only in XINERAMA 1.1,
       # not the X11R6.4 1.0.  They're a copy of the request, so think can
       # ignore.
       return unpack 'x8LL', $data;  # ($width,$height)
     }],

   #------------
   # version 1.1

   ["XineramaIsActive",  # 4
    \&_request_empty,  # ($X)
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data;
    }],

   ["XineramaQueryScreens",  # 5
    \&_request_empty,  # ($X)
    sub {
      my ($X, $data) = @_;
      ### XineramaQueryScreens reply: unpack 'x8L*', $data
      my $num = unpack 'x8L', $data;
      map {[ unpack 'ssSS', substr($data, 32+8*$_, 8) ]} 0 .. $num-1;
    }],
  ];

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### XINERAMA new()

  _ext_requests_install ($X, $request_num, $reqs);

  # Any need to negotiate?
  # my ($major, $minor) = $X->req('PanoramiXQueryVersion',
  #                               CLIENT_MAJOR_VERSION, CLIENT_MINOR_VERSION);
  # ### $major
  # ### $minor

  return bless {
                # major => $major,
                # minor => $minor,
               }, $class;
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

sub _request_empty {
  if (@_ > 1) {
    croak "No parameters in this request";
  }
  return '';
}

sub _request_xids {
  my $X = shift;
  ### _request_xids(): @_
  return _request_card32s ($X, map {_num_none($_)} @_);
}
sub _request_card32s {
  shift;
  ### _request_card32s(): @_
  return pack 'L*', @_;
}
sub _num_none {
  my ($xid) = @_;
  if (defined $xid && $xid eq 'None') {
    return 0;
  } else {
    return $xid;
  }
}

1;
__END__

=for stopwords XINERAMA Xinerama XID arrayrefs Ryde multi-monitor PanoramiX natively enquire ProcPanoramiXGetScreenSize

=head1 NAME

X11::Protocol::Ext::XINERAMA - multi-monitor display information

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('XINERAMA')
   or print "XINERAMA extension not available";

=head1 DESCRIPTION

Xinerama puts together two or more physical monitors to make a single large
screen.  The XINERAMA extension allows clients to enquire about the setup.

The 1.0 "PanoramiX" requests take a C<$window> parameter apparently to allow
for more than one X screen made up of multiple physical monitors, but in
practice the servers have only made one screen this way and the 1.1
"Xinerama" requests don't have that.

See F<examples/xinerama-info.pl> for a sample program dumping the Xinerama
state information.

=head1 REQUESTS

The following requests are made available with an C<init_extension()> per
L<X11::Protocol/EXTENSIONS>.

    my $bool = $X->init_extension('XINERAMA');

=head2 Xinerama 1.0

=over

=item C<($server_major, $server_minor) = $X-E<gt>PanoramiXQueryVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like, the returned
C<$server_major> and C<$server_minor> is what the server will do, which
might be less than requested (but not more).

The current code in this module supports up to 1.1.  The intention would be
to automatically negotiate within C<init_extension()> if/when necessary,

=item C<$flag = $X-E<gt>PanoramiXGetState ($window)>

Return non-zero if Xinerama is active on the screen of C<$window> (an XID).

=item C<$count = $X-E<gt>PanoramiXGetScreenCount ($window)>

Return the number of physical monitors on the screen of C<$window> (an XID).

=item C<($width, $height) = $X-E<gt>PanoramiXGetScreenSize ($window, $monitor)>

Return the size in pixels of physical monitor number C<$monitor> (integer, 0
for the first monitor) on the screen of C<$window> (an XID).

=back

=head2 Xinerama 1.1

=over

=item C<$bool = $X-E<gt>XineramaIsActive ()>

Return non-zero if Xinerama is active on the C<$X> server.

=item C<@rectangles = $X-E<gt>XineramaQueryScreens ()>

Return the rectangular areas made up by the physical monitors.  The return
is a list of arrayrefs,

    [ $x,$y, $width,$height ]

C<$x>,C<$y> is the top-left corner of the monitor in the combined screen.

=back

=head1 BUGS

=head2 C<Xsun>

Rumour has it the C<Xsun> server with Xinerama 1.0 had a different request
number 4 than the C<XineramaIsActive> of Xinerama 1.1 above.

=over

L<http://blogs.sun.com/alanc/entry/xinerama_protocol_clashes_on_solaris>

=back

There's no attempt to do anything about this here, as yet.  If
C<PanoramiXQueryVersion()> reports 1.0 then you shouldn't use
C<XineramaIsActive()> anyway, so no clash.  If you do and it's the C<Xsun>
server then expect either a Length error reply, or the server to adapt
itself to the request length and behave as C<XineramaIsActive>.

=head2 C<PanoramiXGetScreenSize()> Buffer Overrun

Early server code such as X11R6.4 might not range check the monitor number
in C<PanoramiXGetScreenSize()>.  Did big values read out fragments of
arbitrary memory, or cause a segfault?  Don't do that.

=over

X.org some time post 1.5.x,
"Prevent buffer overrun in ProcPanoramiXGetScreenSize",
L<http://cgit.freedesktop.org/xorg/xserver/commit/?id=2b266eda6e23d16116f8a8e258192df353970279>

=back

=head1 OTHER NOTES

To simulate some Xinerama for testing the C<Xdmx> server can multiplex
together two or more other servers to present one big screen.  Those
sub-servers can even be C<Xnest> or C<Xephyr> windows on an existing X
display.  For example running up C<Xdmx> as display ":102",

    Xephyr :5 -screen 200x100 &
    Xephyr :6 -screen 190x110 &
    sleep 1
    Xdmx -display :5 -display :6 +xinerama -input :5 -input :6 :102

C<Xephyr> implements some extensions natively, whereas C<Xnest> relies on
the target server capabilities.  Or to run up without bothering to look at
anything C<Xvfb> in memory or a disk file.

=head1 SEE ALSO

L<X11::Protocol>

Initial technical details
C<http://www.kernel.org/doc/als1999/Conference/IMcCartney/xinerama.html>

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
