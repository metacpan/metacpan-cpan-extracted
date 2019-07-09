# Copyright 2011, 2012, 2013, 2014, 2016, 2017, 2019 Kevin Ryde

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
package X11::Protocol::ChooseWindow;
use strict;
use Carp;

use vars '$VERSION', '$_instance';
$VERSION = 31;

use X11::Protocol::WM;

# uncomment this to run the ### lines
# use Smart::Comments;


# undocumented yet ...
sub new {
  my $class = shift;
  return bless { want_client => 1,
                 @_ }, $class;
}

sub _X {
  my ($self) = @_;
  return ($self->{'X'} ||= do {
    require X11::Protocol;
    my $display = $self->{'display'};
    ### $display
    X11::Protocol->new (defined $display ? ($display) : ());
  });
}

sub choose {
  my ($self, %options) = @_;
  unless (ref $self) {
    $self = $self->new;  # X11::Protocol::ChooseWindow->choose()
  }
  local @{$self}{keys %options} = values %options;  # hash slice
  local $_instance = $self;

  my $X = _X($self);
  {
    my $old_event_handler = $X->{'event_handler'};
    local $X->{'event_handler'} = sub {
      $self->handle_event (@_);
      goto $old_event_handler;
    };

    $self->start;
    do {
      $X->handle_input;
    } until ($self->is_done);
  }

  return $self->chosen_window;
}

sub chosen_window {
  my ($self) = @_;
  if ($self->{'want_client'}) {
    return $self->client_window;
  } else {
    return $self->{'frame_window'};
  }
}
sub client_window {
  my ($self) = @_;
  if (! exists $self->{'client_window'}) {
    my $frame_window = $self->{'frame_window'};
    ### frame_window: $frame_window.sprintf('  0x%X',$frame_window)
    $self->{'client_window'}
      = (defined $frame_window && _num_none($frame_window) != 0
         ? X11::Protocol::WM::frame_window_to_client(_X($self),$frame_window)
         : undef);
    ### client_window: $self->{'client_window'}
  }
  return $self->{'client_window'};
}

# undocumented yet ...
sub start {
  my ($self) = @_;

  $self->abort;
  $self->{'frame_window'} = undef;
  delete $self->{'client_window'};
  $self->{'button_released'} = 0;
  my $X = _X($self);

  my $want_free_cursor;
  my $cursor = $self->{'cursor'};
  if (! defined $cursor) {
    my $cursor_glyph = $self->{'cursor_glyph'};
    if (! defined $cursor_glyph) {
      require X11::CursorFont;
      my $cursor_name = $self->{'cursor_name'};
      if (! defined $cursor_name) {
        $cursor_name = 'crosshair';  # default
      }
      $cursor_glyph = $X11::CursorFont::CURSOR_GLYPH{$cursor_name};
      if (! defined $cursor_glyph) {
        croak "Unrecognised cursor_name: ",$cursor_name;
      }
    }

    my $cursor_font = $X->new_rsrc;
    $X->OpenFont ($cursor_font, 'cursor');

    $cursor = $X->new_rsrc;
    $X->CreateGlyphCursor ($cursor,
                           $cursor_font,  # font
                           $cursor_font,  # mask font
                           $cursor_glyph,    # glyph number
                           $cursor_glyph+1,  # and its mask
                           0,0,0,                    # foreground, black
                           0xFFFF, 0xFFFF, 0xFFFF);  # background, white
    $want_free_cursor = 1;
    $X->CloseFont ($cursor_font);
  }
  ### cursor: sprintf '%d %#X', $cursor, $cursor

  my $root = $self->{'root'};
  if (! defined $root) {
    if (defined (my $screen_number = $self->{'screen'})) {
      $root = $X->{'screens'}->[$screen_number]->{'root'};
    } else {
      $root = $X->{'root'};
    }
  }
  ### $root

  # follow any __SWM_VROOT
  $root = (X11::Protocol::WM::root_to_virtual_root($X,$root) || $root);

  my $time = $self->{'time'} || $self->{'event'}->{'time'} || 'CurrentTime';
  ### $time

  my $status = $X->GrabPointer
    ($root,          # window
     0,              # owner events
     $X->pack_event_mask('ButtonPress','ButtonRelease'),
     'Synchronous',  # pointer mode
     'Asynchronous', # keyboard mode
     $root,          # confine window
     $cursor,        # crosshair cursor
     $time);
  if ($status eq 'Success') {
    $self->{'ungrab_time'} = $time;
  }
  if ($want_free_cursor) {
    $X->FreeCursor ($cursor);
  }
  if ($status ne 'Success') {
    croak "Cannot grab mouse pointer to choose a window: ",$status;
  }
  $X->AllowEvents ('SyncPointer', 'CurrentTime');
}

# undocumented yet ...
sub handle_event {
  my ($self, %h) = @_;
  ### ChooseWindow handle_event: %h
  return if $self->is_done;

  my $name = $h{'name'};
  my $X = _X($self);

  if ($name eq 'ButtonPress') {
    ### ButtonPress
    $self->{'frame_window'} = $h{'child'};
    $self->{'choose_time'} = $h{'time'};
    $X->AllowEvents ('SyncPointer', 'CurrentTime');

  } elsif ($name eq 'ButtonRelease') {
    ### ButtonRelease
    # wait for button pressed to choose window, and then released so the
    # release event doesn't go to the chosen window
    if ($self->{'frame_window'}) {
      # button press seen, and now release seen
      $self->{'button_released'} = 1;
      $self->{'ungrab_time'} = $h{'time'};
      $self->abort;  # ungrab
    } else {
      $X->AllowEvents ('SyncPointer', 'CurrentTime');
    }
  }
}

# undocumented yet ...
sub is_done {
  my ($self) = @_;
  return (! defined $self->{'ungrab_time'} # aborted or never started
          || ($self->{'frame_window'} && $self->{'button_released'}));
}

sub DESTROY {
  my ($self) = @_;
  my ($X, $ungrab_time);
  if (defined ($X = $self->{'X'})
      && defined ($ungrab_time = delete $self->{'ungrab_time'})) {
    # no errors if connection gone
    eval { $X->UngrabPointer ($ungrab_time) };
  }
}

# undocumented yet ...
sub abort {
  my ($self, $time) = @_;
  if (! ref $self) {
    # class method X11::Protocol::ChooseWindow->abort()
    $self = $_instance || return;  # if not in a ->choose()
  }
  my ($X, $ungrab_time);
  if (defined ($X = $self->{'X'})
      && defined ($ungrab_time = delete $self->{'ungrab_time'})) {
    $X->UngrabPointer ($time || $ungrab_time);
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

1;
__END__


# Not quite yet.

# =head2 Chooser Object
# 
# A chooser object can be created to choose in a state-driven style.
# 
# =over
# 
# =item C<$chooser = X11::Protocol::ChooseWindow-E<gt>new (key=E<gt>value,...)>
# 
# Create and return a chooser object.  The key/value parameters are the same
# as for C<choose()> above.
# 
# =item C<$window = $chooser-E<gt>choose (key=E<gt>value,...)>
# 
# Run a window choose on C<$chooser>.  Key/value parameters are as per the
# C<choose()> class method above.  They're apply to this choose, without
# changing the C<$chooser> object.
# 
# =item C<$boolean = $chooser-E<gt>start ()>
# 
# Start a window choose.  This means a mouse pointer grab, with cursor per the
# options in C<$chooser>.
# 
# =item C<$window = $chooser-E<gt>handle_event (@fields)>
# 
# Handle an event in C<$chooser>.  The C<@fields> arguments are the same as
# from the C<X11::Protocol> event handler function.  All events should be
# shown to the chooser this way while it's active.  Anything not relevant is
# ignored.
#
# For a C<ButtonPress> or C<ButtonRelease> event an C<AllowEvents> request
# is sent to get the next button event, in the usual way for an active
# pointer grab.
# 
# =item C<$boolean = $chooser-E<gt>is_done ()>
# 
# Return true if choosing is finished, meaning C<$chooser-E<gt>handle_event()>
# has seen button press and release events.
# 
# =item C<$chooser-E<gt>abort>
# 
# Stop a choose.
# 
# =item C<$chooser-E<gt>chosen_window>
# 
# Return the window chosen by the user, or C<undef> if aborted or not yet
# chosen.  This can be used after C<$chooser-E<gt>is_done()> is true (though
# actually the chosen window is recorded a little earlier, on the button
# press, where C<is_done()> is true only after the button release).
# 
# =back

#     want_frame_window   boolean, default false
# 
# C<want_frame_window> means return the immediate root window child chosen,
# which is generally the window manager's frame window.  The default is to
# seek the client toplevel window within the frame.  When there's no window
# manager or it doesn't use frame windows then the immediate child is the
# client window already and C<want_frame_window> has no effect.





=for stopwords Ryde ChooseWindow toplevel timestamp startup crosshair

=head1 NAME

X11::Protocol::ChooseWindow -- user click to choose window

=for test_synopsis my ($X)

=head1 SYNOPSIS

 use X11::Protocol::ChooseWindow;
 my $client_window = X11::Protocol::ChooseWindow->choose (X => $X);

=head1 DESCRIPTION

This spot of code lets the user click on a toplevel window to choose it, in
a similar style to the C<xwininfo> or C<xkill> programs.

=head2 Implementation

The choose is implemented in a similar way to the C<xwininfo> etc programs.
It consists of C<GrabPointer()> on the root window, wait for a
C<ButtonPress> and C<ButtonRelease> from the user, get the frame window from
the C<ButtonPress> event, then the client window under there from
C<frame_window_to_client()> of C<X11::Protocol::WM>.

C<KeyPress> events are not used and they go to the focus window in the usual
way.  This can be good in a command line program since it lets the user
press C<^C> (C<SIGINT>) in an C<xterm> or similar.  Perhaps in the future
there could be an option to watch for C<Esc> to cancel or some such.

A virtual root per C<root_to_virtual_root()> in C<X11::Protocol::WM> is used
if present.  This helps C<ChooseWindow> work with C<amiwm> and similar
virtual root window managers.

=head1 FUNCTIONS

The following C<choose()> is in class method style with the intention of
perhaps in the future having objects of type C<X11::Protocol::ChooseWindow>
holding state and advanced by events supplied by an external main loop.

=head2 Choosing

=over 4

=item C<$window = X11::Protocol::ChooseWindow-E<gt>choose (key=E<gt>value,...)>

Read a user button press to choose a toplevel window.  The key/value options
are as follows,

    X        => X11::Protocol object
    display  => string ":0:0" etc

    screen   => integer, eg. 0
    root     => XID of root window

    time     => integer server timestamp
    event    => hashref of event initiating the choose

    cursor       => XID of cursor
    cursor_glyph => integer glyph for cursor font
    cursor_name  => string name from cursor font

C<X> or C<display> gives the server, or the default is to open the
C<DISPLAY> environment variable.  C<X> for an C<X11::Protocol> object is
usual, but sometimes it can make sense to open a new connection just to
choose.

C<root> or C<screen> gives the root window to choose on, or the default is
the current screen of C<$X>, which in turn defaults to the screen part of
the display name.  If there's a window manager virtual root then that's
automatically used as necessary.

C<time> or the time field in C<event> is a server timestamp for the
C<GrabPointer()>.  This guards against stealing a grab from another client
if badly lagged.  Omitted or C<undef> means C<CurrentTime>.  In a command
line program there might be no initiating event, making C<CurrentTime> all
that's possible.

C<cursor> etc is the mouse pointer cursor to show during the choose, as a
visual indication to the user.  The default is a "crosshair".
C<cursor_name> or C<cursor_glyph> are from the usual cursor font.  See
L<X11::CursorFont> for available names.  For example perhaps the "exchange"
cursor to choose a window for some sort of swap or flip,

    $window = X11::Protocol::ChooseWindow->choose
                (X => $X,
                 cursor_name => "exchange");

A C<cursor> XID can be created by any client as usual.  Don't forget to
flush if creating a cursor from one connection, so it's ready for use from
another.

=back

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::WM>,
L<X11::CursorFont>

L<xwininfo(1)>, L<xkill(1)>, and their F<dsimple.c> C<Select_Window()> code

"Inter-Client Communication Conventions Manual" section "WM_STATE Property"
for notes on using C<WM_STATE> to identify client windows.

=head1 HOME PAGE

L<http://user42.tuxfamily.org/x11-protocol-other/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2017, 2019 Kevin Ryde

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


# Maybe:
#
# oopery
# ->new (want_frame => 1)
# ->choose
# ->start
# ->handle_input
# ->is_done
# ->chosen_frame
# ->chosen_client
# ->chosen_window

# /z/usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
# /usr/share/doc/x11proto-dev/


