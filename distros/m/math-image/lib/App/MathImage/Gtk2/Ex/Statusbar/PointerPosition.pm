# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.


package App::MathImage::Gtk2::Ex::Statusbar::PointerPosition;
use 5.008;
use strict;
use warnings;
use Gtk2 1.220;
use Scalar::Util 1.18 'refaddr'; # 1.18 for pure-perl refaddr() fix
use Gtk2::Ex::SyncCall 12; # v.12 workaround gtk 2.12 bug

our $VERSION = 110;

# uncomment this to run the ### lines
#use Smart::Comments;

use Gtk2::Ex::Statusbar::Message;
use Glib::Object::Subclass
  'Gtk2::Ex::Statusbar::Message',
  properties => [ Glib::ParamSpec->object
                  ('widget',
                   (do {
                     my $str = 'Widget';
                     # translated from gtk20-properties.mo
                     eval { require Locale::Messages;
                            Locale::Messages::dgettext('gtk20-properties',$str)
                            } || $str }),
                   'Blurb.',
                   'Gtk2::Widget',
                   Glib::G_PARAM_READWRITE),
                ],
  signals => { 'message-string' => { param_types => [ 'Gtk2::Widget',
                                                      'Glib::Int',
                                                      'Glib::Int' ],
                                     return_type => 'Glib::String',
                                     flags       => ['run-last'],
                                   },
             };

# sub INIT_INSTANCE {
#   my ($self) = @_;
# }

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### PointerPosition SET_PROPERTY(): $pname
  ### $newval

  $self->{$pname} = $newval;
  if ($pname eq 'widget') {
    Scalar::Util::weaken ($self->{'widget'});

    # Must listen to enter-notify since that's the only event when the widget
    # is realized underneath the mouse pointer -- there's no motion-notify in
    # that case.
    #
    my $widget = $self->{'widget'};
    $self->{'widget_ids'} = $widget && do {
      Scalar::Util::weaken (my $weak_self = $self);
      require Glib::Ex::SignalIds;
      Glib::Ex::SignalIds->new
          ($widget,
           $widget->signal_connect ('motion_notify_event',
                                    \&_do_enter_or_motion_notify,
                                    \$weak_self),
           $widget->signal_connect ('enter_notify_event',
                                    \&_do_enter_or_motion_notify,
                                    \$weak_self),
           $widget->signal_connect ('leave_notify_event',
                                    \&_do_leave_notify,
                                    \$weak_self));
    };
    $self->{'wevents'} = $widget && do {
      require Gtk2::Ex::WidgetEvents;
      Gtk2::Ex::WidgetEvents->new
          ($widget,
           ['pointer-motion-mask',
            'enter-notify-mask',
            'leave-notify-mask']);
    };

    # initial display
    if ($widget && $self->{'widget'}->realized) {
      $self->{'want_query_pointer'} = 1;
      Scalar::Util::weaken (my $weak_self = $self);
      _queue_synccall($self, \$weak_self);
    }
  }

  ### widget_ids: $self->{'widget_ids'}
}

# $self->{'statusbar_ids'} = $self->{'statusbar'} && do {
#   Scalar::Util::weaken (my $weak_self = $self);
#   require Glib::Ex::SignalIds;
#   Glib::Ex::SignalIds->new
#       ($self->{'statusbar'},
#        $self->{'statusbar'}->signal_connect ('destroy',
#                                              \&_do_statusbar_destroy,
#                                              \$weak_self));
# };
# sub _do_statusbar_destroy {
#   my ($statusbar, $ref_weak_self) = @_;
#   ### PointerPosition _do_statusbar_destroy() ...
#   if (my $self = $$ref_weak_self) {
#     undef $self->{'statusbar'};
#   }
# }

# 'enter-notify-event' signal on the widgets
# 'motion-notify-event' signal on the widgets
sub _do_enter_or_motion_notify {
  my ($widget, $event, $ref_weak_self) = @_;
  ### PointerPosition _do_enter_or_motion_notify(): "$widget"

  if (my $self = $$ref_weak_self) {
    # ignore signals on a previously installed widget
    if ($self->{'widget'} && $self->{'widget'} == $widget) {
      $self->{'x'} = $event->x;
      $self->{'y'} = $event->y;
      $self->{'want_query_pointer'} = 0;

      # If someone else has set pointer-motion-hint then it's their
      # responsibility to get_pointer ... presumably.
      # if ($event->can('is_hint') && $event->is_hint) {
      #   ($self->{'x'},$self->{'y'}) = $widget->get_pointer;
      # } else {
      # }

      _queue_synccall($self, $ref_weak_self);
    }
  }
  return Gtk2::EVENT_PROPAGATE;
}

# 'leave-notify-event' signal on one of the widgets
sub _do_leave_notify {
  my ($widget, $event, $ref_weak_self) = @_;
  ### PointerPosition _do_leave_notify(): "$widget"

  if (my $self = $$ref_weak_self) {
    undef $self->{'x'};
    undef $self->{'y'};
    $self->{'want_query_pointer'} = 0;
    _queue_synccall ($self, $ref_weak_self);
  }
  return Gtk2::EVENT_PROPAGATE;
}

sub _queue_synccall {
  my ($self, $ref_weak_self) = @_;
  ### _queue_synccall(): "$ref_weak_self"

  if ($self->{'widget'}) {
    $self->{'sync_call_pending'} ||= do {
      Gtk2::Ex::SyncCall->sync ($self->{'widget'},
                                \&_do_synccall,
                                $ref_weak_self);
      1;
    };
  }
}
sub _do_synccall {
  my ($ref_weak_self) = @_;
  ### _do_synccall() ...

  my $self = $$ref_weak_self || return;
  $self->{'sync_call_pending'} = 0;

  my $message;
  if (my $widget = $self->{'widget'}) {
    if ($self->{'want_query_pointer'}) {
      my ($x,$y) = $widget->get_pointer;
      if (! _widget_xy_in_widget($widget,$x,$y)) {
        undef $x;
        undef $y;
      }
      $self->{'x'} = $x;
      $self->{'y'} = $x;
    }

    if (defined $self->{'x'}) {
      $message = $self->signal_emit ('message-string',
                                     $self->{'widget'},
                                     $self->{'x'}, $self->{'y'});
    }
  }
  $self->set_message ($message);
}

1;
__END__

=for stopwords Math-Image Ryde

=head1 NAME

App::MathImage::Gtk2::Ex::Statusbar::PointerPosition -- widget pointer position message in a statusbar

=for test_synopsis my ($my_widget, $my_statusbar)

=head1 SYNOPSIS

 use App::MathImage::Gtk2::Ex::Statusbar::PointerPosition;
 my $ppos = App::MathImage::Gtk2::Ex::Statusbar::PointerPosition->new
              (widget => $my_widget,
               statusbar => $my_statusbar);

=head1 WIDGET HIERARCHY

C<App::MathImage::Gtk2::Ex::Statusbar::PointerPosition> is a C<Glib::Object>
subclass,

    Glib::Object
      Gtk2::Ex::Statusbar::Message
        App::MathImage::Gtk2::Ex::Statusbar::PointerPosition

=head1 DESCRIPTION

B<Experimental!>

A PointerPosition object displays a message in a C<Gtk2::Statusbar>
following the mouse pointer position in a given widget.

    +--------------------------------------------+
    |                                            |
    |            *                               |
    |             \__mouse pointer               |
    |                                            |
    |                                            |
    +--------------------------------------------+
    | statusbar message about pointer position   |
    +--------------------------------------------+

The basic operation is a C<motion-notify-event> handler on the widget and a
C<message-string> callback to get a string to show.  But the advantage of
PointerPosition is that it also blanks on leave and it defers updates with
the C<Gtk2::Ex::SyncCall> mechanism so as not to do more statusbar updates
than can be actually displayed.

=head1 FUNCTIONS

=over 4

=item C<< $ppos = App::MathImage::Gtk2::Ex::Statusbar::PointerPosition->new (key=>value,...) >>

Create and return a new PointerPosition object.  Optional key/value pairs
set initial properties per C<< Glib::Object->new >>.

    $ppos = App::MathImage::Gtk2::Ex::Statusbar::PointerPosition->new
               (widget => $my_widget,
                statusbar => $my_statusbar);


=back

=head1 PROPERTIES

=over 4

=item C<widget> (C<Gtk2::Widget> object, default C<undef>)

The widget to watch for mouse motion.

In the current code this must be a windowed widget.  It doesn't have to be
realized or visible yet -- a statusbar message will be shown if or when that
happens (and the mouse is in it).

=item C<statusbar> (C<Gtk2::Statusbar> object, default C<undef>)

The statusbar to display a message in.

=back

=head1 SIGNALS

=over 4

=item C<message-string> (parameters: widget, x, y)

Emitted as a callback to the application asking it for a message string to
display for the mouse at x,y within widget.

The widget is always the PointerPosition widget parameter value, but is
included as a parameter since making a message will very often want to get
or check something from the widget.

    $ppos->signal_connect
        (message_string => \&my_message_string);

    sub my_message_string {
      my ($ppos, $widget, $x, $y, $userdata) = @_;
      return "mouse at X=$x Y=$y, in widget coordinates";
    }

If no message should be shown then return C<undef> from the handler.

=back

=head1 BUILDABLE

C<App::MathImage::Gtk2::Ex::Statusbar::PointerPosition> can be built in a
C<Gtk2::Builder> spec the same as any other C<Glib::Object>.  The class name
is "App__MathImage__Gtk2__Ex__Statusbar__PointerPosition" as usual for
Perl-Gtk package name to class name conversion.

The target C<widget> and C<statusbar> properties can be set to objects
created in the builder spec.  For example

  <object class="App__MathImage__Gtk2__Ex__Statusbar__PointerPosition"
          id="pointerposition">
    <property name="widget">my_drawing</property>
    <property name="statusbar">my_statusbar</property>
  </object>

=cut

  # <object class="GtkDrawingArea" id="my_drawing">
  #   ...
  # </object>
  # <object class="GtkStatusbar" id="my_statusbar">
  #   ...
  # </object>


=head1 SEE ALSO

L<Glib::Object>,
L<Gtk2::Statusbar>,
L<Gtk2::Widget>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-image/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013 Kevin Ryde

Math-Image is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Math-Image is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-Image.  If not, see L<http://www.gnu.org/licenses/>.

=cut
