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


# /usr/share/doc/x11proto-composite-dev/compositeproto.txt.gz
# http://cgit.freedesktop.org/xorg/proto/compositeproto/plain/compositeproto.txt
#
# /usr/include/X11/extensions/Xcomposite.h       Xlib
# /usr/include/X11/extensions/composite.h        constants
# /usr/include/X11/extensions/compositeproto.h   structs
#
# http://ktown.kde.org/~fredrik/composite_howto.html
#
# server side source:
#     http://cgit.freedesktop.org/xorg/xserver/tree/composite/compext.c
#


BEGIN { require 5 }
package X11::Protocol::Ext::Composite;
use strict;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 31;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
#use Smart::Comments;


# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 0;
use constant CLIENT_MINOR_VERSION => 3;

my $reqs =
  [
   ['CompositeQueryVersion',  # 0
    sub {
      my ($X, $major, $minor) = @_;
      ### CompositeQueryVersion request
      return pack 'LL', $major, $minor;
    },
    sub {
      my ($X, $data) = @_;
      ### CompositeQueryVersion reply
      return unpack 'x8LL', $data;

      # Any interest in holding onto the version?
      #  my ($server_major, $server_minor) = unpack 'x8LL', $data;
      # ### $server_major
      # ### $server_minor
      # my $self;
      # if ($self = $self->{'ext'}{'Composite'}->[3]) {
      #   $self->{'major'} = $server_major;
      #   $self->{'minor'} = $server_minor;
      # }
      # return ($server_major, $server_minor);
    }],

   ['CompositeRedirectWindow',  # 1
    \&_request_window_and_update ],

   ['CompositeRedirectSubwindows',  # 2
    \&_request_window_and_update ],

   ['CompositeUnredirectWindow',  # 3
    \&_request_window_and_update ],

   ['CompositeUnredirectSubwindows',  # 4
    \&_request_window_and_update ],

   ['CompositeCreateRegionFromBorderClip',  # 5
    \&_request_xids ], # ($X, $region, $window)

   #----------------------------------------------
   # version 0.2

   ['CompositeNameWindowPixmap',  # 6
    \&_request_xids ], # ($X, $window, $pixmap)

   #----------------------------------------------
   # version 0.3

   ['CompositeGetOverlayWindow',  # 7
    \&_request_xids, # ($X, $window)
    sub {
      my ($X, $data) = @_;
      ### CompositeGetOverlayWindow reply
      return unpack 'x8L', $data;
    }],

   ['CompositeReleaseOverlayWindow',  # 8
    \&_request_xids ], # ($X, $window)

   #----------------------------------------------
   # version 0.4

   # these untested, probably not working

   # ['CompositeRedirectCoordinate',  # 9
   #  sub {
   #    my ($X, $window, $bool) = @_;
   #    ### CompositeRedirectCoordinate request
   #    return pack 'LL', $major, $minor;
   #  },
   # ['CompositeTransformCoordinate',  # 10
   #  sub {
   #    my $X = shift;
   #    my $serial = shift;
   #    my $x = shift;
   #    my $y = shift;
   #    # FIXME: padding ?
   #    return pack('Lss', $serial, $x, $y) . join ('', map {pack 'Lss', @$_});
   #  },

  ];

sub _request_window_and_update {
  my ($X, $window, $update) = @_;
  ### _request_window_and_update()
  return pack ('LCxxx',
               $window,
               $X->num('CompositeUpdate',$update));
}

my $CompositeUpdate_array = [ 'Automatic', 'Manual' ];
my $CompositeUpdate_hash =
  { X11::Protocol::make_num_hash($CompositeUpdate_array) };

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### Composite new()

  # Constants
  $X->{'ext_const'}->{'CompositeUpdate'} = $CompositeUpdate_array;
  $X->{'ext_const_num'}->{'CompositeUpdate'} = $CompositeUpdate_hash;

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  # Events
  # untested, probably not working
  #
  # $X->{'ext_const'}{'Events'}[$event_num] = 'CompositeTransformCoordinate';
  # $X->{'ext_events'}[$event_num] =
  #   [ sub {
  #       my $X = shift;
  #       my $data = shift;
  #       ### CompositeTransformCoordinate unpack: @_[1..$#_]
  #       my ($window, $serial, $x, $y) = unpack 'xxxxLLss', $data;
  # 
  #       return (@_,
  #               name     => 'CompositeTransformCoordinate',
  #               serial   => $serial,
  #               window   => $window,
  #               x        => $x,
  #               y        => $y,
  #               coordinates => [ map {unpack 'Lss', substr($data,$_*8,8)} 4 .. length($data)/8 ],
  #              );
  #     }, sub {
  #       my ($X, %h) = @_;
  #       return (pack('x4LLss',
  #                    $h{'window'},
  #                    $h{'serial'},
  #                    $h{'x'},
  #                    $h{'y'})
  #                   . join('',map{pack 'Lss', @$_} $h{'coordinates'}),
  #               1); # "do_seq" put in sequence number
  #     } ];

  # Any need to negotiate the version before using?
  #  my ($major, $minor) = $X->req('CompositeQueryVersion',
  #                                              CLIENT_MAJOR_VERSION,
  #                                              CLIENT_MINOR_VERSION);
  # if ($major != 1) {
  #   carp "Unrecognised Composite major version, got $major want 1";
  #   return 0;
  # }
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

=for stopwords subwindows unredirect unredirected XID umm XFIXES Ryde pixmap viewable unmapped

=head1 NAME

X11::Protocol::Ext::Composite - off-screen window contents

=for test_synopsis my ($mywindow)

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('Composite')
   or print "Composite extension not available";

 $X->CompositeRedirectWindow ($mywindow, 'Automatic');

=head1 DESCRIPTION

The Composite extension holds the full pixel contents of windows in
off-screen storage, ready for things like C<CopyArea()>.  Normally the
server only keeps the visible parts of a window, not areas overlapped or
obscured.

In "Automatic" mode the visible parts of a window are displayed on screen as
normal.  The off-screen storage is then a little like the backing store
feature, but just when one or more clients declare an interest in the full
content.

In "Manual" mode the window contents are not drawn on screen, only kept
off-screen.  This mode is for use by special "composite manager" programs
which might make a composite display (hence the name of the extension) of
the overlapping windows with partial-transparency or shadowing effects.

There's nothing here to draw or combine to actually make a composite window
result.  When required that's done with the usual core protocol drawing or
with drawing extensions such as RENDER (see L<X11::Protocol::Ext::RENDER>).

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('Composite');

=head2 Composite 0.1

=over

=item C<($server_major, $server_minor) = $X-E<gt>CompositeQueryVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like, the returned
C<$server_major> and C<$server_minor> is what the server will do, which
might be less than requested (but not more than).

Actually the X.org server circa 1.10 will return a higher minor version than
the client requests.

The current code supports up to 0.3 and the intention is to automatically
negotiate in C<init_extension()> if/when necessary.

=item C<$X-E<gt>CompositeRedirectWindow ($window, $update)>

=item C<$X-E<gt>CompositeRedirectSubwindows ($window, $update)>

=item C<$X-E<gt>CompositeUnredirectWindow ($window, $update)>

=item C<$X-E<gt>CompositeUnredirectSubwindows ($window, $update)>

Enable or disable a redirect of C<$window> to off-screen storage.

C<Window()> acts on just the given C<$window>.  C<Subwindows()> acts on
C<$window> and also any subwindows it has now or in the future.  The root
window cannot be redirected.

C<$update> is string "Automatic" or "Manual".  Only one client at a time may
use Manual mode on a given C<$window> (normally a "composite manager"
program).

Redirection is a per-client setting and is automatically unredirected if the
client disconnects.  An unredirect when not redirected is a C<BadValue>
error.  Off-screen storage remains in effect while at least one current
client has requested it.

=item C<$X-E<gt>CompositeCreateRegionFromBorderClip ($region, $window)>

Create C<$region> (a new XID) as a server-side region object initialized to,
umm, something about C<$window> and its current border or visible parts or
whatnot.

Region objects are from XFIXES 2.0 (L<X11::Protocol::Ext::XFIXES>).
C<CompositeCreateRegionFromBorderClip()> can be used without
C<init_extension()> of XFIXES, but there's not much which can be done with a
region except through XFIXES.

=back

=head2 Composite 0.2

=over

=item C<$X-E<gt>CompositeNameWindowPixmap ($window, $pixmap)>

Set C<$pixmap> (a new XID) to refer to the off-screen storage of C<$window>.
C<$window> must be viewable (mapped and all of its parents mapped) and must
be redirected (by any client).

    my $pixmap = $X->new_rsrc;
    $X->CompositeNameWindowPixmap ($window, $pixmap);

C<$pixmap> is released with C<FreePixmap()> in the usual way.  If C<$window>
or a parent is unmapped then C<$pixmap> continues to exist, but it's
association with C<$window> is lost.  If C<$window> is mapped and redirected
again later then it has a new off-screen storage and a new
C<CompositeNameWindowPixmap()> must be called to get a new pixmap for it.

=back

=head2 Composite 0.3

=over

=item C<$overlay_window = $X-E<gt>CompositeGetOverlayWindow ($window)>

Return the composite overlay window for the screen of C<$window>.

This window covers the whole screen and is always above ordinary windows but
below any screen saver, and doesn't appear in a C<QueryTree()>.  It's
created when the first client asks for it, and shared by any further clients
who ask.

=item C<$X-E<gt>CompositeReleaseOverlayWindow ($window)>

Release the composite overlay window for the screen of C<$window>.  When all
clients release it the overlay window is destroyed.

=back

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::Ext::XFIXES>,
L<X11::Protocol::Ext::DOUBLE_BUFFER>

"Composite Extension", Version 0.4, 2007-7-3,
F</usr/share/doc/x11proto-composite-dev/compositeproto.txt.gz>,
C<http://cgit.freedesktop.org/xorg/proto/compositeproto/plain/compositeproto.txt>

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
