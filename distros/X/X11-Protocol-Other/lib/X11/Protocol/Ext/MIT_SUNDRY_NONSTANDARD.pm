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
package X11::Protocol::Ext::MIT_SUNDRY_NONSTANDARD;
use strict;
use Carp;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 31;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
#use Smart::Comments;


# /usr/include/X11/extensions/mitmiscproto.h
# /usr/include/X11/extensions/mitmiscconst.h
#     Protocol.
#
# /usr/include/X11/extensions/MITMisc.h
#     Xlib.


my $reqs =
  [
   ["MitSundryNonstandardSetBugMode",  # 0
    sub {
      my ($X, $onoff) = @_;
      return pack 'Cxxx', $onoff;
    } ],

   ["MitSundryNonstandardGetBugMode",  # 1
    \&_request_empty,
    sub {
      my ($X, $data) = @_;
      return unpack 'xC', $data;
    }],
  ];

sub _request_empty {
  if (@_ > 1) {
    croak "No parameters in this request";
  }
  return '';
}

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### MIT-SUNDRY-NONSTANDARD new()

  _ext_requests_install ($X, $request_num, $reqs);
  return bless { }, $class;
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

1;
__END__

=for stopwords Ryde keycode Xt bc startup

=head1 NAME

X11::Protocol::Ext::MIT_SUNDRY_NONSTANDARD - X11R2/R3 compatibility mode

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('MIT-SUNDRY-NONSTANDARD')
   or print "MIT-SUNDRY-NONSTANDARD extension not available";

=head1 DESCRIPTION

The MIT-SUNDRY-NONSTANDARD extension controls a "bug mode" setting in the
server which helps some X11R2 and X11R3 client programs, including C<xterm>
from those releases.

Bug mode means: relaxing event mask checking in grab pointer and button
requests and window do-not-propagate attributes (to ignore mask bits which
are not applicable); something for non-overlapping sibling window stacking
order; and keeping maximum keycode below 255 to avoid an Xt toolkit
segfault.  Unless working with old client programs then these things are
unlikely to be of interest.

=head1 REQUESTS

The following are made available with an C<init_extension()> per
L<X11::Protocol/EXTENSIONS>.

    my $bool = $X->init_extension('MIT-SUNDRY-NONSTANDARD');

=over

=item C<$X-E<gt>MitSundryNonstandardSetBugMode ($flag)>

=item C<$flag = $X-E<gt>MitSundryNonstandardGetBugMode ()>

Get or set the bug mode flag.  1 means compatibility mode is on, 0 means
off.

=back

=head1 SEE ALSO

L<X11::Protocol>

L<xset(1)> "bc" option to control the bug flag from the command line.

L<Xserver(1)> "bc" command-line option to set the flag at server startup.

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
