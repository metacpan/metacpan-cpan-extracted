# Copyright 2010, 2011, 2012, 2013, 2014, 2017 Kevin Ryde

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


# Window Manager Notes:
#
# ctwm does it's workspaces by moving windows or unmapping or something.
# There's no virtual root but it does draw the root window to a
# per-workspace colour on each change which overwrites anything put there in
# xsetroot style.
#
# evilwm desktop workspaces done by hiding/mapping windows.
#
# tvtwm comes with an ssetroot which looks at __SWM_VROOT.
#
# awesome does desktops by hiding/mapping and a task bar across the top.


# Maybe:

# Maybe read /usr/include/X11/bitmaps/gray like xsetroot -grey.
# Or /usr/include/X11/bitmaps/root_weave which is the server default.
# Those files are bitmaps so foreground,background colours.
#
# bitmap_filename => '/blah...'
# bitmap_usr_include => 'gray'
# bitmap_include => 'gray'
# bitmap_type => 'gray','root_weave','default' builtins
# mod => x,y
# reverse_colors
# color => 
# background =>
# bitmap_foreground => 
# bitmap_background =>
#
#
# root=>
# virtual_root=> no look at root SWM_VROOT
#



BEGIN { require 5 }
package X11::Protocol::XSetRoot;
use strict;
use Carp;
use X11::AtomConstants;
use X11::Protocol::Other;
use X11::Protocol::WM;

use vars '$VERSION';
$VERSION = 31;

# uncomment this to run the ### lines
# use Smart::Comments;


sub set_background {
  my ($class, %option) = @_;
  ### XSetRoot set_background(): do { my %o = %option; delete $o{'X'}; %o }

  my $display;
  my $X = $option{'X'};
  if (! $X) {
    $display = $option{'display'};
    ### display: $display
    require X11::Protocol;
    $X = X11::Protocol->new (defined $display ? ($display) : ());
    $display ||= '';  # so not undef
  }
  ### X: "$X"

  my $root = $option{'root'};
  my $screen_number = $option{'screen'};

  if (! defined $root) {
    if (defined $screen_number) {
      $root = $X->{'screens'}->[$screen_number]->{'root'};
    } else {
      $root = $X->{'root'};
    }
  }
  if (! defined $screen_number) {
    $screen_number = X11::Protocol::Other::root_to_screen($X,$root);

    # Secret undocumented allowance for root=>$xid being something not an
    # actual root window.  Maybe a window_to_screen() checking among the
    # roots and then QueryTree().
    #
    if (! defined $screen_number) {
      my ($actual_root) = $X->QueryTree ($root);
      $screen_number = X11::Protocol::Other::root_to_screen($X,$actual_root);
    }
  }
  ### $root

  my $visual = X11::Protocol::Other::window_visual($X,$root);
  my $visual_is_dynamic = X11::Protocol::Other::visual_is_dynamic($X,$visual);
  my $allocated;

  my @window_attributes;
  my $pixmap = $option{'pixmap'};

  if (! defined $pixmap) {
    my $screen_info = $X->{'screens'}->[$screen_number];
    my $pixel;
    if (defined ($pixel = $option{'pixel'})) {
      ### pixel: $pixel

    } elsif (defined (my $color = $option{'color'})) {
      ($pixel) = _alloc_named_or_hex_color($X,
                                           $screen_info->{'default_colormap'},
                                           $color);
      # when we allocate the pixel here we don't need a specified $X
      # connection, one opened here is enough
      $option{'X'} = 1;
    } else {
      croak "No color, pixel or pixmap for background";
    }

    $allocated = $visual_is_dynamic
      && ! ($pixel == $screen_info->{'black_pixel'}
            || $pixel == $screen_info->{'white_pixel'}
            || _tog_cup_pixel_is_reserved($X,$screen_number,$pixel));
    ### $allocated

    if ($option{'use_esetroot'}) {
      ### create Esetroot 1x1 pixmap of pixel ...
      $pixmap = $X->new_rsrc;
      $X->CreatePixmap ($pixmap,
                        $root,                   # drawable
                        _window_depth($X,$root), # depth
                        1,1);                    # width,height
      my $gc = $X->new_rsrc;
      $X->CreateGC ($gc, $pixmap, foreground => $pixel);
      $X->PolyPoint ($pixmap, $gc, 'Origin', 0,0);
      $X->FreeGC($gc);

    } else {
      @window_attributes = (background_pixel => $pixel);
    }
  } else {
    $allocated = $option{'pixmap_allocated_colors'};
  }
  if (defined $pixmap) {
    ### pixmap: sprintf '%#X', $pixmap
    $pixmap = _num_none($pixmap);
    @window_attributes = (background_pixmap => $pixmap);
  }
  ### @window_attributes

  if ($allocated) {
    if ($visual_is_dynamic) {
      unless ($option{'X'}) {
        croak 'Need X connection to set given pixmap or allocated pixel';
      }
    } else {
      ### static visual, so no pixel allocation ...
      $allocated = 0;
    }
  }

  # follow any __SWM_VROOT
  $root = (X11::Protocol::WM::root_to_virtual_root($X,$root) || $root);

  # GrabServer() so atomic get/set of _XSETROOT_ID.
  #
  # After GetProperty() delete+kill old _XSETROOT_ID don't want another
  # client to be able to slip in a new value which ChangeProperty() here
  # would overwrite (and so leak resources).
  #
  # The QueryPointer() sync is under the grab too so that no-one else can
  # KillClient() on our new _XSETROOT_ID, until after QueryPointer().
  #
  require X11::Protocol::GrabServer;
  my $grab = X11::Protocol::GrabServer->new ($X);

  _kill_current ($X, $root);

  $X->ChangeWindowAttributes ($root, @window_attributes);
  $X->ClearArea ($root, 0,0,0,0); # whole window

  if ($option{'use_esetroot'}) {
    ### set _XROOTPMAP_ID, ESETROOT_PMAP_ID: sprintf '%#X', $pixmap
    my $data = pack ('L', $pixmap);
    $X->ChangeProperty($root,
                       $X->atom('ESETROOT_PMAP_ID'),
                       X11::AtomConstants::PIXMAP(),
                       32,   # format
                       'Replace',
                       $data);
    $X->ChangeProperty($root,
                       $X->atom('_XROOTPMAP_ID'),
                       X11::AtomConstants::PIXMAP(),
                       32,   # format
                       'Replace',
                       $data);
    $X->SetCloseDownMode('RetainPermanent');

  } else {
    ### xsetroot free the pixmap ...
    # if given, and if not $pixmap==0 meaning "None"
    if ($pixmap) {
      ### FreePixmap: $pixmap
      $X->FreePixmap($pixmap);
    }

    if ($allocated) {
      my $id_pixmap = $X->new_rsrc;
      ### save id_pixmap: sprintf('%#X', $id_pixmap)
      $X->CreatePixmap ($id_pixmap,    # 1x1 bitmap
                        $root, # drawable, for screen
                        1,     # depth
                        1,1);  # width,height
      $X->ChangeProperty($root,
                         $X->atom('_XSETROOT_ID'),
                         X11::AtomConstants::PIXMAP(),
                         32,   # format
                         'Replace',
                         pack ('L', $id_pixmap));
      $X->SetCloseDownMode('RetainPermanent');
    }
  }

  # Check for errors with a QueryPointer round trip, either if allocated
  # pixels because the application will do nothing more, or if $display
  # opened here.
  if ($allocated || defined $display) {
    ### sync with QueryPointer ...
    $X->QueryPointer($root);
  }
}

# Return true if $pixel is a TOG-CUP reserved colormap entry in the root
# colormap of $screen_number.  If it's not, or if no TOG-CUP available, then
# return false.
#
sub _tog_cup_pixel_is_reserved {
  my ($X, $screen_number, $pixel) = @_;
  ### _tog_cup_pixel_is_reserved(): $pixel

  if ($X->{'ext'}->{'TOG_CUP'}
      || $X->init_extension('TOG-CUP')) {
    my $c;
    foreach $c ($X->CupGetReservedColormapEntries($screen_number)) {
      if ($c->[0] == $pixel) {
        return 1;
      }
    }
  }
  return 0;
}

# Similar to window_size().
# Return the depth of $window.
# If $window is one of the root windows then the root_depth from the screen
# info in $X is returned, otherwise the depth is obtained from GetGeometry().
sub _window_depth {
  my ($X, $window) = @_;
  ### _window_depth(): $window
  my $screen_info = X11::Protocol::Other::root_to_screen_info($X,$window);
  if ($screen_info) {
    return $screen_info->{'root_depth'};
  }
  my %geom = $X->GetGeometry($window);
  return $geom{'depth'};
}


# Thought about making this a public method, but doubt it would find much
# use except another setroot.  After killing the saved resource properties
# the actual root window background ought to be set to something and a
# ClearArea() to draw.
#
# =item C<X11::Protocol::XSetRoot-E<gt>kill_current ($X)>
#
# =item C<X11::Protocol::XSetRoot-E<gt>kill_current ($X, $root)>
#
# Kill any existing C<_XSETROOT_ID> on the given C<$root> XID.  If C<$root>
# is C<undef> or omitted then the C<$X-E<gt>root> default is used.
#
# This is normally only used when changing or replacing the background in
# the way C<set_background()> above does.
#
sub _kill_current {
  my ($X, $root) = @_;
  ### XSetRoot kill_current() ...
  # $root ||= $X->{'root'};

  # Delete _XROOTPMAP_ID.
  # Do this before KillClient(ESETROOT_PMAP_ID) so that _XROOTPMAP_ID is not
  # left momentarily as a killed non-existent XID.  Though anyone using
  # _XROOTPMAP_ID must be prepared for the XID to be destroyed at any time
  # since it belongs to another client.  We're under a GrabServer() here
  # anyway, so no normal clients get in between the deletes and replacement.
  #
  $X->DeleteProperty($root, $X->atom('_XROOTPMAP_ID'));

  # Delete and kill _XSETROOT_ID and ESETROOT_PMAP_ID.
  #
  foreach my $atom_name ('ESETROOT_PMAP_ID', '_XSETROOT_ID') {
    ### atom: $X->atom($atom_name)
    ### $atom_name
    my ($value, $type, $format, $bytes_after)
      = $X->GetProperty($root,
                        $X->atom($atom_name),
                        0,  # AnyPropertyType
                        0,  # offset
                        1,  # length
                        1); # delete
    ### $type
    if ($type == X11::AtomConstants::PIXMAP() && $format == 32) {
      my $xid = unpack 'L', $value;
      ### kill _XSETROOT_ID: sprintf('%#X', $xid)

      # For safety check $xid!=0, since KillClient(0) would mean kill all
      # temporary clients (ie. all normal clients).
      if ($xid) {
        $X->KillClient($xid);
      }
    }
  }
  ### _kill_current() done ...
}

sub _alloc_named_or_hex_color {
  my ($X, $colormap, $str) = @_;
  ### _alloc_named_or_hex_color(): $str
  {
    my @exact;
    if (@exact = X11::Protocol::Other::hexstr_to_rgb($str)) {
      my ($pixel, @actual) = $X->AllocColor($colormap, @exact);
      return ($pixel, @exact, @actual);
    }
  }
  return $X->AllocNamedColor($colormap, $str);
}

# or maybe $X->num('IDorNone',$xid)
sub _num_none {
  my ($xid) = @_;
  if ($xid eq 'None') {
    return 0;
  } else {
    return $xid;
  }
}

1;
__END__

=for stopwords Ryde pixmap colormap RetainPermanent pre-defined lookup XID Pixmap XSetRoot recognised Esetroot

=head1 NAME

X11::Protocol::XSetRoot -- set root window background

=for test_synopsis my ($X, $pixmap_xid)

=head1 SYNOPSIS

 use X11::Protocol::XSetRoot;
 X11::Protocol::XSetRoot->set_background (color => 'green');

 # or given $X, but which then can't be used any more
 X11::Protocol::XSetRoot->set_background
                  (X       => $X,
                   pixmap  => $pixmap_xid,
                   pixmap_allocated_colors => 1);

=head1 DESCRIPTION

This module sets the X root window background in the style of the
C<xsetroot> program.

The simplest use is a named colour interpreted by the server's usual
C<AllocNamedColor()> or a 1 to 4 digit hex string like "#RRGGBB" or
"#RRRRGGGGBBBB".

    X11::Protocol::XSetRoot->set_background
                               (color => 'green');

    X11::Protocol::XSetRoot->set_background
                               (color => '#FF0000'); # red

A pattern can be set with a pixmap.  A pixmap the size of the screen can
give a full background picture.

    # draw $pixmap with say $X->black_pixel and $X->white_pixel,
    # then set it with
    X11::Protocol::XSetRoot->set_background
                               (X      => $X,
                                pixmap => $pixmap);

C<set_background()> takes ownership of the given C<$pixmap> and frees it
with C<FreePixmap()> once put into the window background.

Setting the root to a pixmap drawn by a program is the main use for this
module.  If you just want a solid colour then that can be done easily enough
with the actual C<xsetroot> program.

=head2 Retained Resources

Allocated pixel colours (in C<PseudoColor> etc) and any C<use_esetroot>
preserve pixels and the pixmap with C<SetCloseDownMode ('RetainPermanent')>
and leave root window properties C<_XSETROOT_ID> or C<ESETROOT_PMAP_ID>
ready to released by a C<KillClient()> in a future background change.

In these cases the C<$X> connection cannot be used any more since a further
background change and consequent C<KillClient()> could occur at any time,
perhaps immediately.

If a C<pixmap> is given then if it contains any allocated pixels
(C<AllocColor()> etc) then this should be indicated with the
C<pixmap_allocated_colors> option.  (Allocated pixels are noticed
automatically for C<pixel> and C<color> options.)

    # AllocColor colours, draw $pixmap with them, then
    #
    X11::Protocol::XSetRoot->set_background
                               (X      => $X,
                                pixmap => $pixmap,
                                pixmap_allocated_colors => 1);
    # don't use $X any more

The easiest thing is to close an C<$X> connection immediately after a
C<set_background()>.  Perhaps there could be a return value to say whether a
retain was done and thus the connection cannot be used again.  Or perhaps in
the future if C<X11::Protocol> had an explicit C<$X-E<gt>close()> then that
could be done here so a closed connection would indicate it cannot be used
further.

If the root visual is static (C<TrueColor> etc) then there's no colour
allocation as such (C<AllocColor()> is just a lookup).  In this case
C<set_background()> knows there's no need for C<RetainPermanent> for
colours, only for pixmaps.

If the C<color> or C<pixel> options are the screen C<black_pixel> or
C<white_pixel> then those pixels exist permanently in the root colormap and
C<set_background()> knows there's no need to C<RetainPermanent> for them.
If the server has the TOG-CUP extension (see L<X11::Protocol::Ext::TOG_CUP>)
then any permanent pixels there are recognised too.

=head1 Virtual Root

C<XSetRoot> looks for C<__SWM_VROOT> using L<X11::Protocol::WM>
C<root_to_virtual_root()> and acts on that when applicable.  Such a virtual
root is used by C<amiwm>, C<swm> and C<tvtwm> window managers and the
C<xscreensaver> program.

The enlightenment window manager, however, uses a background window covering
the root window.  This stops most root window programs from working,
including XSetRoot here.

=head1 Esetroot

The C<Esetroot> program and various compatible programs such as C<fvwm-root>
use a separate set of properties from what C<xsetroot> uses.  The
C<Esetroot> method records the root pixmap ready for use by programs such as
C<Eterm>, eg. to implement pseudo-transparency (its C<Eterm --trans>, which
the method was designed for).

The C<set_background()> option C<use_esetroot> uses the C<Esetroot> style
rather than the default C<xsetroot> style.  It can be used with the C<pixel>
or C<color> options too and in that case C<set_background()> makes a 1x1
pixmap to give a solid colour.

C<set_background()> always deletes and kills (as appropriate) both the
C<xsetroot> and C<Esetroot> properties since both are superseded by a new
background.

For reference, to use C<Eterm --trans> (as of its version 0.9.6 March 2011)
an C<Esetroot> background should be present when C<Eterm> starts and it
should not be removed later (and not set to "None").  C<Eterm> won't notice
an initial C<Esetroot> while it's running.  This means do an C<Esetroot>
before running C<Eterm> and then do all future background changes in
C<Esetroot> style.

The advantage of the C<Esetroot> method is that the root pixmap is available
for client programs to use in creative ways.  If the client draws some of
the root pixmap as its own background then it can appear semi-transparent.
This doesn't require the SHAPE extension and allows visual effects like
shading or dithering too.

For comparison, the C<xsetroot> style means the root pixmap is not available
to client programs.  In principle that allows the server to apply it to the
hardware and never refer to it again.  In practice that might not occur, for
example if multiple console "virtual terminals" mean the server must give up
the hardware when switched away.

=pod

=head1 FUNCTIONS

=over 4

=item C<X11::Protocol::XSetRoot-E<gt>set_background (key=E<gt>value, ...)>

Set the root window background to a pixmap or colour.  The key/value
parameters are

    X        => X11::Protocol object
    display  => string ":0.0" etc

    screen   => integer, eg. 0
    root     => XID of root window

    color    => string
    pixel    => integer pixel value
    pixmap   => XID of pixmap to display, or "None"
    pixmap_allocated_colors => boolean, default false
    use_esetroot => boolean, default false

The server is given by an C<X> connection object, or a C<display> name to
connect to, or the default is the C<DISPLAY> environment variable.

The root window is given by C<root> or C<screen>, or the default is the
default screen in C<$X> either per C<$X-E<gt>choose_screen()> or the default
from the display name.

The background to show is given by a colour name, pixel value, or pixmap.
C<color> can be anything understood by the server C<AllocNamedColor()>, plus
1 to 4 digit hex

    blue              named colours
    #RGB              hex digits
    #RRGGBB
    #RRRGGGBBB
    #RRRRGGGGBBBB

C<pixel> is an integer pixel value in the root window colormap.  It's
automatically recognised as allocated or not (the screen pre-defined black
or white and TOG-CUP reserved pixels are permanent and so reckoned not
allocated).

C<pixmap> is an XID integer.  C<set_background()> takes ownership of this
pixmap and will C<FreePixmap()> once installed.  "None" or 0 means no
pixmap, which gives the server's default root background (usually a black
and white weave pattern).

C<pixmap_allocated_colors> should be true if any of the pixels in C<pixmap>
were allocated with C<AllocColor()> etc, as opposed to just the screen
pre-defined black and white pixels (and any TOG-CUP permanent pixels).

C<use_esetroot> means use the root window properties in the style of
C<Esetroot>.  This allows programs such as C<Eterm> to use the root
background for "pseudo-transparency" or in other creative ways.

When an allocated pixel or a pixmap with allocated pixels is set as the
background the C<_XSETROOT_ID> mechanism described above means the C<$X>
connection could be killed by another C<xsetroot> at any time, perhaps
immediately, and for that reason C<$X> should not be used any more.  The
easiest way is to make C<set_background()> the last thing done on C<$X>.

Setting an allocated C<pixel> or any C<pixmap> can only be done on a C<$X>
connection as such, not with the C<display> option.  This is because
retaining the colours with the C<_XSETROOT_ID> mechanism can only be done
from the client connection which created the resources, not a new separate
client connection.

=back

=head1 ROOT WINDOW PROPERTIES

=over

=item C<_XSETROOT_ID>

For C<xsetroot>, if colours in the root window background are allocated by
C<AllocColor()> etc then C<_XSETROOT_ID> is a pixmap XID which can be killed
by C<KillClient()> to free those colours when the root background is
replaced.  C<_XSETROOT_ID> is only a 1x1 dummy pixmap, it's not the actual
root background pixmap.

=item C<_XROOTPMAP_ID>

For C<Esetroot> style, this is the current root window background pixmap.
It might be set by an C<Esetroot> which has run and exited, or it might be
set by a window manager or similar which is still running.

Client programs can use this to combine the root background into their own
window in interesting ways.  Listen to C<PropertyNotify> on the root window
for changes to C<_XROOTPMAP_ID>.  Note that this pixmap belongs to another
client so it could be freed at any time.  Protocol errors when copying or
drawing from it should generally be ignored, or cause a fallback to some
default.

=item C<ESETROOT_PMAP_ID>

For C<Esetroot> style, this is the same as C<_XROOTPMAP_ID> if that pixmap
was created by C<Esetroot> and saved by
C<SetCloseDownMode('RetainPermanent')>.  This should be freed by
C<KillClient()> if the background is replaced.

The specification L<http://www.eterm.org/docs/view.php?doc=ref#trans>
advises killing C<ESETROOT_PMAP_ID> only when equal to C<_XROOTPMAP_ID>.
Probably it's safer to always kill C<ESETROOT_PMAP_ID> if replacing its
value, to be sure of not leaking resources.  But perhaps if both
C<ESETROOT_PMAP_ID> and C<_XROOTPMAP_ID> exist then they are always equal.

=back

=head1 ENVIRONMENT

=over

=item C<DISPLAY>

The default X server.

=back

=head1 FILES

F</etc/X11/rgb.txt> on the server, being the usual colour names database for
the C<color> option above.

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::Ext::TOG_CUP>

L<xsetroot(1)>,
L<Esetroot(1)>,
L<Eterm(1)>,
L<fvwm-root(1)>

L<http://www.eterm.org/docs/view.php?doc=ref#trans>
L<http://www.eterm.org/doc/Eterm_reference.html#trans>
L<file:///usr/share/doc/eterm/Eterm_reference.html#trans>

See F<examples/view-root.pl> for a simple program to display the root window
contents.

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
