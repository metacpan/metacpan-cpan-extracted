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
package X11::Protocol::Ext::X_Resource;
use strict;
use Carp;

use vars '$VERSION';
$VERSION = 31;

# uncomment this to run the ### lines
#use Smart::Comments;

# /usr/include/X11/extensions/XResproto.h
#     protocol
#
# http://cgit.freedesktop.org/xorg/xserver/tree/Xext/xres.c
# http://cgit.freedesktop.org/xorg/xserver/plain/Xext/xres.c
#     server side source
#
# /usr/include/X11/extensions/XRes.h
#     Xlib.
#

### X_Resource.pm loads

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 1;
use constant CLIENT_MINOR_VERSION => 0;

#------------------------------------------------------------------------------

my $reqs =
  [
   ["XResourceQueryVersion",  # 0
    sub {
      ### XResourceQueryVersion request
      shift;  # $X
      return pack 'CCxx', @_;   # ($client_major, $client_minor)
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8SS', $data;   # ($server_major, $server_minor)
    }],

   ["XResourceQueryClients",  # 1
    \&_request_empty,
    sub {
      my ($X, $data) = @_;
      ### XResourceQueryClients reply
      my $num = unpack 'x8L', $data;
      ### $num
      # obey $num rather than the reply length
      # Other way to do it: List::Pairwise::pair(unpack 'x32L'.(2*$num))
      return map {[ unpack 'LL', substr($data,32+$_*8,8) ]} 0 .. $num-1;
    } ],

   ["XResourceQueryClientResources",  # 2
    \&_request_card32s,  # ($X, $client_xid)
    sub {
      my ($X, $data) = @_;
      ### XResourceQueryClientResources reply
      my ($num) = unpack 'x8L', $data;
      ### $num
      # obey $num rather than the reply length
      return unpack 'x32L'.(2*$num), $data;
    }],

   ["XResourceQueryClientPixmapBytes",  # 3
    \&_request_card32s,  # ($X, $client_xid)
    do {
      # see if 2^64-1 survives an sprintf %d, if so then 64-bit UV integers
      my $v = ((0xFFFFFFFF * (2.0**32)) + 0xFFFFFFFF);
      ($v == sprintf("%u",$v))
    }
    ? sub {
      my ($X, $data) = @_;
      ### XResourceQueryClientPixmapBytes reply, 64-bit system
      my ($lo, $hi) = unpack('x8LL', $data);
      return $lo + ($hi << 32);
    }
    : do {
      # probe for where floating point loses precision
      # if $hi<$hi_limit then $hi*2**32 + $lo is exact
      my $hi_limit = 1;
      foreach (1 .. 32) {
        my $float = $hi_limit * (2.0**32);
        my $plus1 = $float+1;
        my $plus2 = $float+2;
        if (! ($plus1 > $float && $plus1 < $plus2)) {
          last;
        }
        $hi_limit *= 2.0;
      }
      ### $hi_limit
      ### hex: sprintf "%X", $hi_limit
      sub {
        my ($X, $data) = @_;
        ### XResourceQueryClientPixmapBytes reply, 32-bit system
        my ($lo, $hi) = unpack('x8LL', $data);
        ### $lo
        ### $hi
        ### hex lo: sprintf "%X", $lo
        ### hex hi: sprintf "%X", $hi
        if ($hi == 0) {
          return $lo;
        } elsif ($hi < $hi_limit) {
          return $lo + $hi * (2 ** 32);
        } else {
          require Math::BigInt;
          return (Math::BigInt->new($hi) << 32) + $lo;
        }
      }
    } ],


   # #----------------------
   # # protocol 1.2
   #
   # # mask bits ...
   # # ClientXIDMask      0x01
   # # LocalClientPIDMask 0x02
   # # xid_or_pid 'None'
   # ["XResourceQueryClientIds",  # 4
   #  sub {
   #    my $X = shift;  # ($X, $xid_or_pid, $mask, ...)
   #    return pack 'L*',
   #      scalar(@_)/2, # num specs
   #        @_;
   #  },
   #  sub {
   #    my ($X, $data) = @_;
   #    ### XResourceQueryClientResources reply
   #    my ($num) = unpack 'x8L', $data;
   #    ### $num
   #    my $pos = 32;
   #    my @ret;
   #    # obey $num rather than the reply length
   #    for (1 .. $num) {
   #      my @elem = unpack 'L3', substr($data,$pos,12);
   #      my ($client_xid, $mask, $length) = unpack 'L3', substr($data,$pos,12);
   #      $pos += 12;
   #      my $length = 4 * pop @elem;
   #      push @elem, unpack 'L*', substr($data,$pos,$length);
   #      $pos += $length;
   #      push @ret, \@elem;
   #    }
   #    return @ret;
   #  }],
   #
   # ["XResourceQueryResourceBytes",  # 5
   #  sub {
   #    my $X = shift;  # ($X, $client_xid, $resource,$type, ...)
   #    my $client_xid = shift;
   #    return pack 'L*',
   #      $client_xid,
   #        scalar(@_)/2, # num specs
   #          @_;
   #  },
   #  sub {
   #    my ($X, $data) = @_;
   #    ### XResourceQueryClientResources reply
   #    my ($num) = unpack 'x8L', $data;
   #    ### $num
   #    my $pos = 32;
   #    my @ret;
   #    # obey $num rather than the reply length
   #    for (1 .. $num) {
   #      my @elem = unpack 'L6', # $resource,$type,$bytes,$refcount,$usecount
   #        substr($data,$pos,24);
   #      $pos += 24;
   #      my $length = 20 * pop @elem;
   #      push @elem, unpack 'L*', substr($data,$pos,$length);
   #      $pos += $length;
   #      push @ret, \@elem;
   #    }
   #    return @ret;
   #  }],

  ];

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


#------------------------------------------------------------------------------

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### X_Resource new()

  $X->{'ext_request'}{$request_num} = $reqs;
  _ext_request_num_fill ($X, $request_num, $reqs);

  # Any need to query/negotiate the protocol version first?
  # Xlib XRes.c doesn't seem to.
  # my ($server_major, $server_minor) = $X->req('XResourceQueryVersion',
  #                                              CLIENT_MAJOR_VERSION,
  #                                              CLIENT_MINOR_VERSION);
  return bless {
                # major => $server_major,
                # minor => $server_minor,
               }, $class;
}

sub _ext_request_num_fill {
  my ($X, $request_num, $reqs) = @_;
  my $i;
  foreach $i (0 .. $#$reqs) {
    $X->{'ext_request_num'}{$reqs->[$i]->[0]} = [$request_num, $i];
  }
}

1;
__END__

=for stopwords pixmap pixmaps GCs XID XIDs arrayref 0xA00000 0x1FFFFF 0xBFFFFF lookup GC Gbytes Ryde enquire

=head1 NAME

X11::Protocol::Ext::X_Resource - server resource usage

=for test_synopsis my ($client_xid)

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('X-Resource')
   or print "X-Resource extension not available";

 my @clients = $X->XResourceQueryClients();

 my %resources = $X->XResourceQueryClientResources ($client_xid);

 my $bytes = $X->XResourceQueryClientPixmapBytes ($client_xid);

=head1 DESCRIPTION

The X-Resource extension gives some server resource utilization information,
mainly for use as diagnostics.

=over

=item *

Current client connections and their XID ranges.

=item *

How many windows, pixmaps, GCs, etc in use by a given client.

=item *

Total memory used by all the pixmaps of a given client.

=back

"Resources" here means memory, objects, etc, not to be confused with the
resource database of user preferences and widget settings of
L<X(7)/RESOURCES>.

See F<examples/xresource-print.pl> for a simple dump of the resources
reported.

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('X-Resource');

=over

=item C<($server_major, $server_minor) = $X-E<gt>XResourceQueryVersion ($client_major, $client_minor)>

Negotiate the extension version.  C<$client_major> and C<$client_minor> is
what the client would like, the returned C<$server_major> and
C<$server_minor> is what the server will do, which might be lower than
requested (but not higher).

The current code supports X-Resource 1.0.  The intention is for this module
to automatically negotiate in C<$X-E<gt>init_extension()> if/when needed.

=item C<@clients = $X-E<gt>XResourceQueryClients ()>

Return a list of client connections on the server.  Each returned value is
an arrayref pair

    [ $xid_base, $xid_mask ]

C<$xid_base> (an integer) is the start of XIDs for the client.

C<$xid_mask> (an integer) is a bit mask for the XIDs above that base which
the client may use.  For example C<$xid_base> might be 0xA00000 and
C<$xid_mask> 0x1FFFFF, meaning 0xA00000 through 0xBFFFFF is this client.

    my @clients = $X->XResourceQueryClients;
    print "there are ",scalar(@clients)," clients\n";
    foreach my $aref (@clients) {
      my $xid_base = $aref->[0];
      my $xid_mask = $aref->[1];
      printf "client base %X mask %X\n", $xid_base, $xid_mask;
    }

The given C<$X> connection itself is included in the return.  Its base and
mask are per C<$X-E<gt>{'resource_id_base'}> and
C<$X-E<gt>{'resource_id_mask'}>.

=item C<($atom,$count,...) = $X-E<gt>XResourceQueryClientResources ($xid)>

Return a list of how many of various server things are used by a given
client.

The client is identified by an C<$xid>.  It can be anything in the client's
XID range and doesn't have to be currently allocated or created.  For
example to enquire about the current client use
C<$X-E<gt>{'resource_id_base'}>.

The return is a list of resource type (an atom integer) and count of those
things,

    ($atom, $count, $atom, $count, ...)

So for example to print all resources,

    my @res = $X->XResourceQueryClientResources ($xid);
    while (@res) {
      my $type_atom = shift @res;
      my $count = shift @res;
      my $type_name = $X->atom_name($type_atom);
      printf "type $type_name count $count\n";
    }

Or put the list into a hash to lookup a particular resource type,

    my %res = $X->XResourceQueryClientResources ($xid);

    my $window_atom = X11::AtomConstants::WINDOW();
    my $windows = $res{$window_atom} || 0;

    my $grab_atom = $X->atom('PASSIVE GRAB');
    my $grabs = $res{$grab_atom} || 'no';

    print "using $windows many windows, and $grabs passive grabs";

C<List::Pairwise> has C<mapp()> and other things to work with this sort of
two-at-a-time list.  See F<examples/xresource-pairwise.pl> for a complete
program.

Generally a count entry is only present when the client has 1 or more of the
thing.  So if no pixmaps then no C<PIXMAP> entry at all.

Basics like C<WINDOW>, C<PIXMAP>, C<GC> C<COLORMAP>, C<FONT> and C<CURSOR>
are how many of those in use.  The server might also report things like
S<C<PASSIVE GRAB>> or S<C<COLORMAP ENTRY>> (atoms with spaces in their
names).  The X.org server (circa version 1.9) even sometimes reports things
like "Unregistered resource 30" (an atom with that name), which is something
or other.

If the given C<$xid> is not a connected client then a C<BadValue> error
results.  Be careful of that when querying resources of another client since
the client might disconnect at any time.  C<$X-E<gt>robust_req()> is good,
or maybe C<GrabServer> to hold connections between
C<XResourceQueryClients()> and C<XResourceQueryClientResources()>.

=item C<$bytes = $X-E<gt>XResourceQueryClientPixmapBytes ($xid)>

Return the total bytes of memory on the server used by all the pixmaps of a
given client.  Pixmaps which only exist as window backgrounds or GC tiles or
stipples are included, or should be.  If the client has no pixmaps at all
the return is 0.

The client is identified by an C<$xid> as per
C<XResourceQueryClientResources()> above.  It can be anything in the
client's XID range, allocated or not.

    my $pixmap = $X->new_rsrc;
    $X->CreatePixmap ($pixmap,
                      $X->{'root'},
                      $X->{'root_depth'},
                      100, 100);  # width,height

    my $xid = $X->{'resource_id_base'};  # own usage
    my $bytes = $X->XResourceQueryClientPixmapBytes ($xid);
    print "total of all pixmaps is $bytes bytes of memory\n";

The return is a 64-bit value.  On a 32-bit Perl a bigger than 32 bits is
returned as floating point, or bigger than 53 bit float as C<Math::BigInt>.
Most of the time 32 bits is enough, since that would be 4 Gbytes of pixmaps,
and or 53-bit float should be plenty, that being about 8192 terabytes!

For reference, the X.org server circa version 1.11.4 had a bug where it
didn't count space used by pixmaps of depth less than 8 (including depth 1
bitmaps) in the bytes returned.

=back

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::AtomConstants>

X.org server source code
C<http://cgit.freedesktop.org/xorg/xserver/tree/Xext/xres.c>

L<xrestop(1)>

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
