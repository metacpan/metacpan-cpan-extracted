# Copyright 2010, 2011, 2012, 2013, 2014, 2017 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.


package X11::Protocol::GrabServer;
BEGIN { require 5 }
use strict;
use Carp;
BEGIN {
  # weaken() if available, which means new enough Perl to have weakening,
  # and Scalar::Util with its XS code
  eval "use Scalar::Util 'weaken'; 1"
    or eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;
sub weaken {} # otherwise noop
HERE
}

# uncomment this to run the ### lines
#use Smart::Comments;

use vars '$VERSION';
$VERSION = 31;

sub new {
  my ($class, $X) = @_;
  ### GrabServer-object new(): "$X"
  if (! defined $X) {
    croak "No X connection given";
  }
  my $self = bless { X => $X }, $class;
  weaken ($self->{'X'});
  $self->grab;
  return $self;
}
sub DESTROY {
  my ($self) = @_;
  ### GrabServer-object DESTROY()

  $self->ungrab;

  # ### initial error: $@
  # local $@;  # don't clobber if destroyed during a die() unwind
  # eval { $self->ungrab };  # ignore EPIPE write if server already closed
  # ### DESTROY error: $@
}

sub grab {
  my ($self) = @_;
  ### GrabServer-object grab()
  unless ($self->{'grabbed'}) {
    my $X = $self->{'X'} || return;
    $self->{'grabbed'} = 1;
    if (! $X->{__PACKAGE__.'.count'}++) {
      ### initial X->GrabServer
      $X->GrabServer;
    }
  }
  ### grab count now: $self->{'X'} && $self->{'X'}->{__PACKAGE__.'.count'}
}

sub ungrab {
  my ($self) = @_;
  ### GrabServer-object ungrab()
  if (delete $self->{'grabbed'}) {
    my $X = $self->{'X'} || return;
    if (--$X->{__PACKAGE__.'.count'} <= 0) {
      delete $X->{__PACKAGE__.'.count'}; # cleanup
      ### final X->UngrabServer
      $X->UngrabServer;
      $X->flush;
    }
  }
  ### grab count now: $self->{'X'} && $self->{'X'}->{__PACKAGE__.'.count'}
}

sub is_grabbed {
  my ($self) = @_;
  return $self->{'grabbed'};
}

# # not sure about this ...
# sub call_with_grab {
#   my $class = shift;
#   my $X = shift;
#   my $subr = shift;
#   my $grab = $class->new ($X);
#   &$subr (@_);
# }

1;
__END__

=for stopwords Ryde GrabServer UngrabServer ungrab ungrabs ungrabbed TCP ie

=head1 NAME

X11::Protocol::GrabServer -- object-oriented server grabbing

=for test_synopsis my ($X)

=head1 SYNOPSIS

 use X11::Protocol::GrabServer;
 {
   my $grab = X11::Protocol::GrabServer->new ($X); 
   do_some_things();
   # UngrabServer when $grab destroyed
 }

=head1 DESCRIPTION

This is an object-oriented approach to GrabServer / UngrabServer on an
C<X11::Protocol> connection.  A grab object represents a desired server grab
and destroying it ungrabs.

The first grab object on a connection does a C<GrabServer()> and the last
destroyed does an C<UngrabServer()>.  The idea is that it's easier to manage
the lifespan of a grabbing object in a block etc than to be sure of catching
all exits.

Multiple grab objects can overlap or nest.  A single C<GrabServer()> is done
and it remains until the last object is destroyed.  This is good in a
library or sub-function where an C<UngrabServer()> should wait until the end
of outermost desired grab.

A server grab is usually to make a few operations atomic, for instance
something global like root window properties.  A block-based temporary
object like the synopsis above is typical.  It's also possible to hold a
grab object for an extended time, perhaps for some state driven interaction
with the server.

Care must be taken not to grab for too long since other client programs are
locked out.  Also if a grabbing program hangs then the server will be
unusable until the program is killed, or its TCP etc server connection is
broken.

=head2 Weak C<$X>

If Perl weak references are available (which means Perl 5.6 and up and
C<Scalar::Util> with its usual XS code), then a grab object holds only a
weak reference to the target C<$X> connection.  This means the grab doesn't
keep the connection alive once nothing else is interested.  When a
connection is destroyed the server ungrabs automatically and so there's no
need for an explicit C<UngrabServer()> in that case.

The main effect of the weakening is that C<$X> can be garbage collected
anywhere within a grabbing block, the same as if there was no grab.  Without
the weakening it would wait until the end of the block.  In practice this
only rarely makes a difference.

In the future if an C<X11::Protocol> connection gets a notion of an explicit
close then the intention would be to skip any C<UngrabServer()> in that case
too, ie. treat a closed connection the same as a weakened away connection.

Currently no attention is paid to whether the server has disconnected the
link.  A C<UngrabServer()> is done on destroy in the usual way.  If the
server has disconnected then a C<SIGPIPE> or C<EPIPE> occurs the same as for
any other request sent to the C<$X>.

=head1 FUNCTIONS

=over 4

=item C<$g = X11::Protocol::GrabServer-E<gt>new ($X)>

C<$X> is an C<X11::Protocol> object.  Create and return a C<$g> object
representing a grab of the C<$X> server.

If this new C<$g> is the first new grab on C<$X> then an
C<$X-E<gt>GrabServer> is done.

=item C<$g-E<gt>ungrab ()>

Ungrab the C<$g> object explicitly.  An ungrab is done automatically when
C<$g> is destroyed, but C<$g-E<gt>ungrab()> can do it sooner.

If C<$g> is already ungrabbed then do nothing.

=item C<$g-E<gt>grab ()>

Re-grab with the C<$g> object.  This can be used after a C<$g-E<gt>ungrab()>
to grab again with the same object, the same as if newly created.

If C<$g> is already grabbing then do nothing.

=item C<$bool = $g-E<gt>is_grabbed ()>

Return true if C<$g> is grabbing.  This is true when first created, or false
after a C<$g-E<gt>ungrab()>.

This function is only the state of C<$g>.  There might be other
C<GrabServer> objects which grabbing the server.

=back

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::Other>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/x11-protocol-other/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2017 Kevin Ryde

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
