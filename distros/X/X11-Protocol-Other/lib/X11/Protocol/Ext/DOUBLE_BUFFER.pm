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


# /usr/share/doc/x11proto-xext-dev/dbe.txt.gz
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
# /usr/include/X11/extensions/dbe.h
# /usr/include/X11/extensions/dbeproto.h
#    Protocol.
#
# /usr/share/doc/libxext-dev/dbelib.txt.gz
# /so/xfree/xfree86-3.3.2.3a/lib/Xext/Xdbe.c
#    Xlib.
#
# /so/xfree/xfree86-3.3.2.3a/programs/Xserver/dbe/dbe.c
# /so/xorg/xorg-server-1.10.0/dbe/dbe.c
#    Server.


BEGIN { require 5 }
package X11::Protocol::Ext::DOUBLE_BUFFER;
use strict;
use Carp;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 31;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
#use Smart::Comments;


# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 1;
use constant CLIENT_MINOR_VERSION => 0;

my $reqs =
  [
   [ 'DbeGetVersion',  # 0
     sub {
       my ($X, $client_major, $client_minor) = @_;
       ### DbeGetVersion request
       return pack 'CCxx', $client_major, $client_minor;
     },
     sub {
       my ($X, $data) = @_;
       return unpack 'x8CC', $data;
     }],

   [ 'DbeAllocateBackBufferName',  # 1
     sub {
       my ($X, $window, $buffer, $action_hint) = @_;
       ### DbeAllocateBackBufferName request
       return pack 'LLCxxx',
         $window, $buffer, $X->num('DbeSwapAction',$action_hint);
     } ],

   [ 'DbeDeallocateBackBufferName',  # 2
     \&_request_card32s ],  # ($X,$buffer)

   [ 'DbeSwapBuffers',  # 3
     sub {
       my $X = shift;   # ($X, $window,$action, $window,$action, ...)
       my $ret = pack 'L', scalar(@_)/2;  # number of pairs
       while (@_) {
         $ret .= pack 'LCxxx', shift, $X->num('DbeSwapAction',shift);
       }
       return $ret;
     }],

   [ 'DbeBeginIdiom',     # 4
     \&_request_empty ],
   [ 'DbeEndIdiom',       # 5
     \&_request_empty ],

   [ 'DbeGetVisualInfo',  # 6
     sub {
       ### DbeGetVisualInfo request ...
       my $X = shift;   # ($X, $window, $window, ...)
       ### num_windows: scalar(@_)
       ### windows: @_
       return pack 'L*', scalar(@_), @_; # (num_windows, window, window, ...)
     },
     sub {
       my ($X, $data) = @_;
       ### DbeGetVisualInfo reply ...

       my $num_screens = unpack 'x8L', $data;
       ### $num_screens

       my $pos = 32;
       # Maybe should return single aref in scalar context.
       # The map{} ends up giving a count in scalar context (or does it?).
       return map {
         my $num_visuals = unpack 'L', substr($data,$pos,4);
         $pos += 4;
         [ map { my ($visual_id, $depth, $performance)
                   =  unpack 'LCC', substr($data,($pos+=8)-8,6);
                 $visual_id => [ $depth, $performance ] }
           1 .. $num_visuals ]
       } 1 .. $num_screens;
     }],

   [ 'DbeGetBackBufferAttributes',  # 7
     \&_request_card32s,   # ($X,$buffer)
     sub {
       my ($X, $data) = @_;
       return _interp_none($X, unpack('x8L',$data));
     }],

  ];

my $DbeSwapAction_array = ['Undefined', 'Background', 'Untouched', 'Copied'];
my $DbeSwapAction_hash
  = { X11::Protocol::make_num_hash($DbeSwapAction_array) };

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### DOUBLE_BUFFER new() ...

  # Constants
  $X->{'ext_const'}->{'DbeSwapAction'} = $DbeSwapAction_array;
  $X->{'ext_const_num'}->{'DbeSwapAction'} = $DbeSwapAction_hash;

  _ext_requests_install ($X, $request_num, $reqs);

  # Protocol spec says must negotiate version or the extension may or may
  # not work.
  my ($server_major, $server_minor) = $X->req('DbeGetVersion', 1, 0);
  ### $server_major
  ### $server_minor
  return bless { major => $server_major,
                 minor => $server_minor,
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

sub _request_card32s {
  shift;
  ### _request_card32s(): @_
  return pack 'L*', @_;
}

sub _interp_none {
  my ($X, $xid) = @_;
  if ($X->{'do_interp'} && $xid == 0) {
    return 'None';
  } else {
    return $xid;
  }
}

1;
__END__

=for stopwords XID arrayrefs Ryde pixmap Deallocate deallocated XIDs enum arrayref arrayrefs drawable drawable's recognise drawables enquiring XFree86 Xlib DbeSwapAction

=head1 NAME

X11::Protocol::Ext::DOUBLE_BUFFER - window off-screen double buffering

=for test_synopsis my ($X)

=head1 SYNOPSIS

 use X11::Protocol;
 $X = X11::Protocol->new;
 $X->init_extension('DOUBLE-BUFFER')
   or print "DOUBLE-BUFFER extension not available";

=head1 DESCRIPTION

The DOUBLE-BUFFER extension lets a program draw into an off-screen "back
buffer" on a window and when ready swap it to the user-visible "front".
A back buffer is a drawable with the same size, depth, visibility, etc as
the window proper.

Drawing off-screen then swapping to visible is good for smooth frame by
frame animations or if some drawing is complex or poorly implemented and has
clears or overwriting which would flash if done directly to the window.

Off-screen drawing can also be implemented by a pixmap and copy into the
window but the server might implement a back buffer more efficiently.  In
particular the back buffer only needs to be visible portions of a window so
memory is not used for overlapped areas.

The server might support double buffering only on certain visuals.
C<DbeGetVisualInfo()> lists those which are supported, or just try to create
a back buffer for a window and watch for an error reply.

See F<examples/dbe-swap.pl> for a simple program drawing with double
buffering.

=head1 REQUESTS

The following requests are made available with an C<init_extension()> per
L<X11::Protocol/EXTENSIONS>.

    my $bool = $X->init_extension('DOUBLE-BUFFER');

=over

=item C<($server_major, $server_minor) = $X-E<gt>DbeGetVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like, the returned
C<$server_major> and C<$server_minor> is what the server will do, which
might be less than requested (but not higher).

The code here supports 1.0 and automatically negotiates within
C<init_extension()> so direct use of C<DbeGetVersion()> is not necessary.

=item C<$X-E<gt>DbeAllocateBackBufferName ($window, $buffer, $action_hint)>

Create C<$buffer> (a new XID) as the back buffer on C<$window>.  C<$buffer>
is a drawable and can be used with all usual drawing operations.

    my $buffer = $X->new_rsrc;
    $X->DbeAllocateBackBufferName ($window, $buffer, 'Copied');

C<$action_hint> is the most likely C<$action> in later C<DbeSwapBuffers()>
requests (see below).  But this is just a hint and doesn't restrict what can
be done.

If C<$window> is already double buffered then C<$buffer> becomes another
reference to that back buffer.

If C<$window> is destroyed (C<DestroyWindow()>) then C<$buffer> continues to
exist and should still be deallocated (below), but attempting to draw into
it gives a C<Resource> error reply.

=item C<$X-E<gt>DbeDellocateBackBufferName ($buffer)>

Deallocate C<$buffer> and release that XID.

If multiple C<DbeAllocateBackBufferName()> requests have been made on a
window then all the other XIDs continue to refer to the window back buffer.
The underlying buffer remains until all buffer XIDs for it are deallocated.

=item C<$X-E<gt>DbeSwapBuffers ($window1,$action1, $window2,$action2,...)>

Swap the front and back buffers on each given C<$window> (XIDs).  The back
buffer becomes visible and what was the front becomes the back.

  $X->DbeSwapBuffers ($window1, 'Background',
                      $window2, 'Untouched');

Only the content is swapped, the XIDs are unchanged, so C<$window> is still
the visible window front and any C<$buffer> XIDs to it are still the back.

The contents of each back buffer after swapping are controlled by the
corresponding C<$action> for each window (string type L</DbeSwapAction>),

     $action        new back buffer contents
    ---------       --------------------------
    "Undefined"     undefined contents
    "Background"    cleared to the window background
    "Untouched"     left at current content (previous visible)
    "Copied"        content of the old back buffer (unchanged)

"Untouched" means the contents of the front buffer are swapped to the back
buffer unchanged.

"Copied" is as if the back buffer content is copied to the front, making
both now the same.

=item C<$X-E<gt>DbeBeginIdiom ()>

=item C<$X-E<gt>DbeEndIdiom ()>

Hint to the server that a sequence of swap and/or drawing operations between
Begin and End might be done as an atomic combination for higher performance.
If the server doesn't recognise the sequence then it runs it sequentially as
normal.

If a C<DbeSwapBuffers()> is in the idiom then it should be the first
request, immediately following the Begin.

    # swap then clear back buffer to a GC stipple
    # no guarantee any server would actually optimize this!
    $X->DbeBeginIdiom;
    $X->DbeSwapBuffers ($window, 'Undefined');
    $X->PolyFillRectangle ($buffer, $gc, [0,0,$width,$height]);
    $X->DbeEndIdiom;

There doesn't need to be a swap in an idiom.  For example a C<CopyArea()> of
some parts of the back buffer to the window might be in a Begin/End and
might perhaps be optimized by the server.

    $X->DbeBeginIdiom;
    $X->CopyArea ($buffer, $window,  # from buffer to window
                  $gc, $x,$y,$width,$height, $dstx,$dsty);
    # more stuff ...
    $X->DbeEndIdiom;

The idea of idiom groupings is to have a flexible way to express combination
operations, including things not yet imagined, rather than adding specific
requests to the protocol.  In principle the server can always optimize
consecutive requests but that depends on them arriving at the server
together.  A C<DbeBeginIdiom()> is like permission to the server to defer
performing the requests and wait, if it wishes, to see if what follows can
be combined.

=item C<@infos = $X-E<gt>DbeGetVisualInfo ($drawable1, $drawable2, ...)>

=item C<@infos = $X-E<gt>DbeGetVisualInfo ()>

For each C<$drawable>, return a list of the visual IDs on that screen which
support double-buffering.

    my ($info_aref_drawable1, $info_aref_drawable2)
      = $X->DbeGetVisualInfo ($drawable1, $drawable2);

If no drawables are given then return information
about each screen on the server.

    my @list_of_info_aref = $X->DbeGetVisualInfo ();

Each returned value is an arrayref.  Each arrayref contains a list of visual
ID and visual data pairs,

    # each $info_aref is
    [ $visual_id1, [ $depth, $perflevel ],
      $visual_id2, [ $depth, $perflevel ],
      ...
    ]

C<$depth> is the visual's depth the same as in the server info
C<$X-E<gt>{'visuals'}-E<gt>{$visual_id}-E<gt>{'depth'}>.

C<$perflevel> is an integer indicating how good the performance of double
buffering is on this visual.  A higher value means higher performance, but
the actual number has no meaning and in particular cannot be compared
between different servers.

If enquiring about a single drawable's screen then use a list context like
the following.  The result in scalar context is unspecified as yet.

    my ($info_aref) = $X->DbeGetVisualInfo ($X->root);

The visual+perf are pairs so they can be put into a hash to check support
for double buffering on a given visual,

    my %hash = @$info_aref;   # pairs $visualid => [$d,$p]
    if ($hash{$my_visual_id}) {
      print "double buffering is available on my_visual_id\n";
    }

If you've got a choice of equally suitable visuals for application display
then the performance level might be compared to choose the best.

C<List::Pairwise> has some grep and map functions for pair lists like the
C<$info_aref>.

See F<examples/dbe-info.pl> for a simple program printing this info.

=item C<$window = $X-E<gt>DbeGetBackBufferAttributes ($buffer)>

Return the window (an integer XID) which C<$buffer> is for.  If its target
window has been destroyed (C<DestroyWindow()>) then the return is "None".

=back

=head1 ENUM TYPES

The following types are available for C<$X-E<gt>interp()> and
C<$X-E<gt>num()>, after C<init_extension()>.

=over

=item DbeSwapAction

    "Undefined"    0
    "Background"   1
    "Untouched"    2
    "Copied"       3

=back

For example,

    my $num = $X->num("DbeSwapAction", "Background");
    # sets $num to 2

=head1 BUGS

In some XFree86 3.x servers there was a bug in C<DbeGetVisualInfo()> where
the reply length was miscalculated, being bytes instead of CARD32s,
resulting in a length value bigger than the actual data sent.  The symptom
is the client hangs waiting for data the length says should follow but which
never does.

This affects all client code, including the Xlib C<XdbeGetVisualInfo()> as
used for instance by the C<xdpyinfo> program.

Is there a good way to notice the problem?  Probably not beyond looking at
the server name and version and either forbidding the request or doing
something nasty to the way C<handle_input()> reads as a workaround.

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::Ext::Composite>

F</usr/share/doc/x11proto-xext-dev/dbe.txt.gz>

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
