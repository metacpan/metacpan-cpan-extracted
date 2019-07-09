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


# /usr/share/doc/x11proto-damage-dev/damageproto.txt.gz
#     http://cgit.freedesktop.org/xorg/proto/damageproto/tree/damageproto.txt
#
# /usr/include/X11/extensions/Xdamage.h
# /usr/include/X11/extensions/damageproto.h
# /usr/include/X11/extensions/damagewire.h
#
# server side source:
#     http://cgit.freedesktop.org/xorg/xserver/tree/damageext/damageext.c
#


BEGIN { require 5 }
package X11::Protocol::Ext::DAMAGE;
use strict;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 31;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
#use Smart::Comments;


# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 1;
use constant CLIENT_MINOR_VERSION => 1;

my $reqs
  = [
     #------------
     # version 1.0

     ["DamageQueryVersion",  # 0
      sub {
        my ($X, $major, $minor) = @_;
        ### DamageQueryVersion request
        return pack 'LL', $major, $minor;
      },
      sub {
        my ($X, $data) = @_;
        ### DamageQueryVersion reply
        my @ret = unpack 'x8LL', $data;

        # Any interest in holding onto the version?
        # Remove DamageAdd if downgrading?
        my $self;
        if ($self = $X->{'ext'}->{'DAMAGE'}->[3]) {
          ($self->{'major'}, $self->{'minor'}) = @ret;
        }
        return @ret;
      }],

     ["DamageCreate",  # 1
      sub {
        my ($X, $damage, $drawable, $level) = @_;
        ### DamageCreate
        return pack ('LLCxxx',
                     $damage,
                     $drawable,
                     $X->num('DamageReportLevel',$level));
      }],

     ["DamageDestroy",   # 2
      \&_request_xids ], # ($damage)

     ["DamageSubtract",  # 3
      \&_request_xids ], # ($damage, $repair_region, $parts_region)

     #------------
     # version 1.1

     ["DamageAdd",       # 4
      \&_request_xids ], # ($damage, $region)
    ];

my $DamageNotify_event
  = [ sub {
        my $X = shift;
        my $data = shift;
        ### DamageNotify unpack: @_[1..$#_]
        my ($level, $drawable, $damage, $time, $area, $geometry)
          = unpack 'xCxxL3a8a8', $data;
        ### fields: $level, $drawable, $damage, $time, $area, $geometry
        ### area: _unpack_rectangle($area)
        ### geometry: _unpack_rectangle($geometry)
        my $more = ($level >> 7) & 1;  # bit 0x80
        $level &= 0x7F;
        return (@_,  # base fields
                drawable => $drawable,
                damage   => $damage,
                level    => $X->interp('DamageReportLevel',$level),
                more     => $more,
                time     => _interp_time($time),
                area     => _unpack_rectangle($area),
                geometry => _unpack_rectangle($geometry),
               );
      }, sub {
        my ($X, %h) = @_;
        my $level = ($X->num('DamageReportLevel', $h{'level'})
                     + ($h{'more'} ? 0x80 : 0));
        return (pack('xCxxL3ssSSssSS',
                     $level,
                     $h{'drawable'},
                     $h{'damage'},
                     _num_time($h{'time'}),
                     @{$h{'area'}},      # [$x,$y,$w,$h]
                     @{$h{'geometry'}}), # [$x,$y,$w,$h]
                1); # "do_seq" put in sequence number
      } ];

my $DamageReportLevel_array = [ 'RawRectangles',
                                'DeltaRectangles',
                                'BoundingBox',
                                'NonEmpty' ];
my $DamageReportLevel_hash
  = { X11::Protocol::make_num_hash($DamageReportLevel_array) };

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### DAMAGE new()

  # Constants
  $X->{'ext_const'}->{'DamageReportLevel'} = $DamageReportLevel_array;
  $X->{'ext_const_num'}->{'DamageReportLevel'} = $DamageReportLevel_hash;

  # Errors
  $X->{'ext_const'}->{'Error'}->[$error_num] = 'Damage';
  $X->{'ext_const_num'}->{'Error'}->{'Damage'} = $error_num;
  $X->{'ext_error_type'}->[$error_num] = 1; # bad resource

  # Events
  $X->{'ext_const'}->{'Events'}->[$event_num] = 'DamageNotify';
  $X->{'ext_events'}->[$event_num] = $DamageNotify_event;

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  # Must DamageQueryVersion to negotiate desired version, or at least X.org
  # server 1.9.x gives "Opcode" errors to all other requests if not.
  my ($major, $minor) = $X->req ('DamageQueryVersion',
                                 CLIENT_MAJOR_VERSION,
                                 CLIENT_MINOR_VERSION);
  return bless { major => $major,
                 minor => $minor,
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

sub _unpack_rectangle {
  my ($data) = @_;
  return [ unpack 'ssSS', $data ];
}

sub _interp_time {
  my ($time) = @_;
  if ($time == 0) {
    return 'CurrentTime';
  } else {
    return $time;
  }
}
sub _num_time {
  my ($time) = @_;
  if ($time eq 'CurrentTime') {
    return 0;
  } else {
    return $time;
  }
}

1;
__END__

=for stopwords drawables pixmaps XFIXES DamageNotify XID subwindows enum unhandled GL arrayref umm pixmap Ryde Opcode DamageReportLevel MIT-SHM drawable

=head1 NAME

X11::Protocol::Ext::DAMAGE - drawing notifications

=for test_synopsis my ($drawable, $parts_region);

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('DAMAGE')
   or print "DAMAGE extension not available";

 my $damage = $X->new_rsrc;
 $X->DamageCreate ($damage, $drawable, 'NonEmpty');

 sub my_event_handler {
   my %h = @_;
   if ($h{'name'} eq 'DamageNotify') {
     my $drawable = $h{'drawable'};
     $X->DamageSubtract ($damage, 'None', $parts_region);
     # do something for $parts_region changed in $drawable
   }
 }

=head1 DESCRIPTION

The DAMAGE extension lets a client listen for changes to drawables (windows,
pixmaps, etc) due to drawing operations, including drawing into sub-windows
which appears in the parent.

This can be used for various kinds of efficient copying or replicating of
window contents, such as cloning to another screen, showing a magnified
view, etc.  The root window can be monitored to get changes on the whole
screen.

Content changes due to drawing are conceived as "damage".  A server-side
damage object accumulates areas as rectangles to make a server-side "region"
per the XFIXES 2.0 extension (see L<X11::Protocol::Ext::XFIXES>)

A DamageNotify event is sent from a damage object.  A reporting level
controls the level of detail, ranging from just one event on becoming
non-empty, up to an event for every drawing operation affecting the relevant
drawable.

Fetching an accumulated damage region (or part of it) is reckoned as a
"repair".  It doesn't change any drawables in any way, just fetches the
region from the damage object.  This fetch is atomic, so nothing is lost if
the listening client is a bit lagged etc.

See F<examples/damage-duplicate.pl> for one way to use damage to duplicate a
window in real-time.

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('DAMAGE');

=head2 DAMAGE 1.0

=over

=item C<($server_major, $server_minor) = $X-E<gt>DamageQueryVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like, the returned
C<$server_major> and C<$server_minor> is what the server will do, which
might be less than requested (but not more).

The current code supports up to 1.1.  If asking for higher then be careful
that it's upwardly compatible.  The module code negotiates a version in
C<init_extension()> so explicit C<DamageQueryVersion()> is normally not
needed.

=item C<$X-E<gt>DamageCreate ($damage, $drawable, $level)>

Create a new damage object in C<$damage> (a new XID) which monitors changes
to C<$drawable>.  If C<$drawable> is a window then changes to its subwindows
are included too.

    # listening to every change on the whole screen
    my $damage = $X->new_rsrc;
    $X->DamageCreate ($damage, $X->root, 'RawRectangles');

C<$level> is an enum string controlling how often C<DamageNotify> events are
emitted (see L</"EVENTS"> below).

    RawRectangles      every change
    DeltaRectangles    when damage region expands
    BoundingBox        when damage bounding box expands
    NonEmpty           when damage first becomes non-empty

=item C<$X-E<gt>DamageDestroy ($damage)>

Destroy C<$damage>.

=item C<$X-E<gt>DamageSubtract ($damage, $repair_region, $parts_region)>

Move the accumulated region in C<$damage> to C<$parts_region> (a region
XID), and clear it from C<$damage>.

If C<$parts_region> is "None" then C<$damage> is cleared and the region
discarded.  This can be used if for example the entire C<$drawable> will be
copied or re-examined, so the exact parts are not needed.

C<$repair_region> is what portion of C<$damage> to consider.  "None" means
move and clear everything in C<$damage>.  Otherwise C<$repair_region> is a
region XID and the portion of the damage region within C<$repair_region> is
moved and cleared.  Anything outside is left in C<$damage>.

If anything is left in C<$damage> then a new C<DamageNotify> event is
immediately sent.  This can be good for instance if you picked out a
C<$repair_region> corresponding to what you thought was the window size
(perhaps from the C<geometry> field of a C<DamageNotify> event), but it has
grown in the interim.

Region objects here can be created with the XFIXES 2.0 extension (see
L<X11::Protocol::Ext::XFIXES>).  It should be available whenever DAMAGE is
available.  If using "None" and "None" to clear and discard then region
objects are not required and there's no need for an
C<init_extension('XFIXES')>.

=back

=head2 DAMAGE 1.1

=over

=item C<$X-E<gt>DamageAdd ($drawable, $region)>

Report to any interested damage objects that changes have occurred in
C<$region> (a region XID) of C<$drawable>.

This is used by clients which modify a drawable in ways not seen by the
normal protocol drawing operations.  For example an MIT-SHM shared memory
pixmap modified by writing to the memory (see
L<X11::Protocol::Ext::MIT_SHM>), or the various "direct rendering" to
graphics hardware or GL etc.

=back

=head1 EVENTS

C<DamageNotify> events are sent to the client which created the damage
object.  These events are always generated, there's nothing to select or
deselect them.  The event has the usual fields

    name             "DamageNotify"
    synthetic        true if from a SendEvent
    code             integer opcode
    sequence_number  integer

and event-specific fields

    damage        XID, damage object
    drawable      XID, as from DamageCreate
    level         enum, as from DamageCreate
    more          boolean, if more DamageNotify on the way
    time          integer, server timestamp
    area          arrayref [$x,$y,$width,$height]
    geometry      arrayref [$rootx,$rooty,$width,$height]

C<drawable> and C<level> are as from the C<DamageCreate()> which made the
C<damage> object.

C<more> is true if there's further C<DamageNotify> events on the way for
this damage object.  This can happen when the "level" means there's a set of
C<area> rectangles to report.

C<area> is a rectangle within C<drawable>, as a 4-element arrayref,

    [ $x, $y, $width, $height ]

What it covers depends on the reporting level requested,

=over

=item *

C<RawRectangles> -- a rectangle around an arc, line, etc, drawing operation
which changed C<drawable>.

=item *

C<DeltaRectangles> -- an additional rectangle extending the damage region.
Only new rectangles are reported, not any of the existing damage region.
Reporting a region addition may require multiple C<DamageNotify> events.

=item *

C<BoundingBox> -- a bounding box around the damage region accumulated,
bigger than previously reported.

=item *

C<NonEmpty> -- umm, something, maybe the entire drawable.

=back

C<geometry> is the current size and position of the drawable as a 4-element
arrayref in root window coordinates.  For a pixmap C<$root_x> and C<$root_y>
are 0.

    [ $root_x, $root_y, $width, $height ]

=head1 ENUM TYPES

The reporting level above is type "DamageReportLevel".  So for example
(after a successful C<$X-E<gt>init_extension('DAMAGE')>),

    $number = $X->num('DamageReportLevel', 'RawRectangles');

    $string = $X->interp('DamageReportLevel', 3);

See L<X11::Protocol/SYMBOLIC CONSTANTS>.

=head1 ERRORS

Error type "Damage" is a bad C<$damage> resource XID in a request.

=head1 BUGS

The server extension version number is queried in the C<init_extension()>,
but not yet made available as such.  The version determines whether
C<DamageAdd()> ought to work.  Currently that request is always setup, but
presumably generates an Opcode error if the server doesn't have it.

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::Ext::XFIXES>

F</usr/share/doc/x11proto-damage-dev/damageproto.txt.gz>,
L<http://cgit.freedesktop.org/xorg/proto/damageproto/tree/damageproto.txt>

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
