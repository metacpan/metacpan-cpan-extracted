package X11::Xlib::XEvent;
use X11::Xlib; # need constants loaded
use parent 'X11::Xlib::Struct';

=head1 NAME

X11::Xlib::XEvent - Polymorphic class for XEvent structures

=head1 DESCRiPTION

This object wraps an XEvent.  XEvent is a union of many different C structs,
though they all share a few common fields.  The storage space of an XEvent is
constant regardless of type, and so this class is backed by a simple scalar
ref.

The active struct of the union is determined by the L</type> field.  This object
heirarchy attempts to help you make correct usage of the union with respect to
the current C<type>, so as you change the value of C<type> the object will
automatically re-bless itself into the appropriate subclass, giving you access
to new struct fields.

Most of the "magic" occurs from Perl code, not XS, so it is possible to define
new event types if this module lacks any in your local copy of Xlib.  You can
also access the L</bytes> directly any time you want.  And, you don't even have
to use this object at all; any scalar or scalarref of the correct length can be
passed to the L<X11::Xlib> methods that expect an XEvent pointer.

=head1 METHODS

=head2 new

  my $xevent= X11::Xlib::XEvent->new();
  my $xevent= X11::Xlib::XEvent->new( %fields );
  my $xevent= X11::Xlib::XEvent->new( \%fields );

You can construct XEvent as an empty buffer, or initialize it with a hash or
hashref of fields.  Initialization is performed via L</pack>.  Un-set fields
are initialized to zero, and the L</bytes> is always padded to the length
of an XEvent.

=head2 bytes

Direct access to the bytes of the XEvent.

=head2 apply

  $xevent->apply( %fields );

Alias for C< pack( \%fields, 1, 1 ) >

=head2 pack

  $xevent->pack( \%fields, $consume, $warn );

Assign a set of fields to the packed struct, optionally removing them from
the hashref (C<$consume>) and warning about un-known names (C<$warn>).
If you supply a new value for L</type>, the XEvent will get re-blessed to
the appropriate type and all union-specific fields will be zeroed before
applying the rest of the supplied fields.

=head2 unpack

  my $field_hashref= $xevent->unpack;

Unpack the fields of an XEvent into a hashref.  The Display field gets
inflated to an X11::Xlib object.

=head1 COMMON ATTRIBUTES

All XEvent subclasses have the following attributes:

=head2 type

This is the key attribute that determines all the rest.  Setting this value
will re-bless the object to the relevant sub-class.  If the type is unknown,
it becomes C<X11::Xlib::XEvent>.

=head2 display

The handle to the X11 connection that this message came from.

=head2 serial

The X11 serial number

=head2 send_event

Boolean indicating whether the event was sent with C<XSendEvent>

=head1 SUBCLASS ATTRIBUTES

For detailed information about these structures, consult the
L<official documentation|https://www.x.org/releases/X11R7.7/doc/libX11/libX11/libX11.html>

=cut

sub pack {
    my $self= shift;
    # As a special case, convert type enum codes into numeric values
    if (my $type= $_[0]{type}) {
        unless ($type =~ /^[0-9]+$/) {
            # Look up the symbolic constant
            if (grep { $_ eq $type } @{ $X11::Xlib::EXPORT_TAGS{const_event} }) {
                $_[0]{type}= X11::Xlib->$type();
            } else {
                Carp::croak "Unknown XEvent type '$type'";
            }
        }
    }
    $self->SUPER::pack(@_);
}

# ----------------------------------------------------------------------------
# BEGIN GENERATED X11_Xlib_XEvent



@X11::Xlib::XButtonEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XButtonEvent::button= *_button;
*X11::Xlib::XButtonEvent::root= *_root;
*X11::Xlib::XButtonEvent::same_screen= *_same_screen;
*X11::Xlib::XButtonEvent::state= *_state;
*X11::Xlib::XButtonEvent::subwindow= *_subwindow;
*X11::Xlib::XButtonEvent::time= *_time;
*X11::Xlib::XButtonEvent::window= *_window;
*X11::Xlib::XButtonEvent::x= *_x;
*X11::Xlib::XButtonEvent::x_root= *_x_root;
*X11::Xlib::XButtonEvent::y= *_y;
*X11::Xlib::XButtonEvent::y_root= *_y_root;


@X11::Xlib::XCirculateEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XCirculateEvent::event= *_event;
*X11::Xlib::XCirculateEvent::place= *_place;
*X11::Xlib::XCirculateEvent::window= *_window;


@X11::Xlib::XCirculateRequestEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XCirculateRequestEvent::parent= *_parent;
*X11::Xlib::XCirculateRequestEvent::place= *_place;
*X11::Xlib::XCirculateRequestEvent::window= *_window;


@X11::Xlib::XClientMessageEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XClientMessageEvent::b= *_b;
*X11::Xlib::XClientMessageEvent::l= *_l;
*X11::Xlib::XClientMessageEvent::s= *_s;
*X11::Xlib::XClientMessageEvent::format= *_format;
*X11::Xlib::XClientMessageEvent::message_type= *_message_type;
*X11::Xlib::XClientMessageEvent::window= *_window;


@X11::Xlib::XColormapEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XColormapEvent::colormap= *_colormap;
*X11::Xlib::XColormapEvent::new= *_new;
*X11::Xlib::XColormapEvent::state= *_state;
*X11::Xlib::XColormapEvent::window= *_window;


@X11::Xlib::XConfigureEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XConfigureEvent::above= *_above;
*X11::Xlib::XConfigureEvent::border_width= *_border_width;
*X11::Xlib::XConfigureEvent::event= *_event;
*X11::Xlib::XConfigureEvent::height= *_height;
*X11::Xlib::XConfigureEvent::override_redirect= *_override_redirect;
*X11::Xlib::XConfigureEvent::width= *_width;
*X11::Xlib::XConfigureEvent::window= *_window;
*X11::Xlib::XConfigureEvent::x= *_x;
*X11::Xlib::XConfigureEvent::y= *_y;


@X11::Xlib::XConfigureRequestEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XConfigureRequestEvent::above= *_above;
*X11::Xlib::XConfigureRequestEvent::border_width= *_border_width;
*X11::Xlib::XConfigureRequestEvent::detail= *_detail;
*X11::Xlib::XConfigureRequestEvent::height= *_height;
*X11::Xlib::XConfigureRequestEvent::parent= *_parent;
*X11::Xlib::XConfigureRequestEvent::value_mask= *_value_mask;
*X11::Xlib::XConfigureRequestEvent::width= *_width;
*X11::Xlib::XConfigureRequestEvent::window= *_window;
*X11::Xlib::XConfigureRequestEvent::x= *_x;
*X11::Xlib::XConfigureRequestEvent::y= *_y;


@X11::Xlib::XCreateWindowEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XCreateWindowEvent::border_width= *_border_width;
*X11::Xlib::XCreateWindowEvent::height= *_height;
*X11::Xlib::XCreateWindowEvent::override_redirect= *_override_redirect;
*X11::Xlib::XCreateWindowEvent::parent= *_parent;
*X11::Xlib::XCreateWindowEvent::width= *_width;
*X11::Xlib::XCreateWindowEvent::window= *_window;
*X11::Xlib::XCreateWindowEvent::x= *_x;
*X11::Xlib::XCreateWindowEvent::y= *_y;


@X11::Xlib::XCrossingEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XCrossingEvent::detail= *_detail;
*X11::Xlib::XCrossingEvent::focus= *_focus;
*X11::Xlib::XCrossingEvent::mode= *_mode;
*X11::Xlib::XCrossingEvent::root= *_root;
*X11::Xlib::XCrossingEvent::same_screen= *_same_screen;
*X11::Xlib::XCrossingEvent::state= *_state;
*X11::Xlib::XCrossingEvent::subwindow= *_subwindow;
*X11::Xlib::XCrossingEvent::time= *_time;
*X11::Xlib::XCrossingEvent::window= *_window;
*X11::Xlib::XCrossingEvent::x= *_x;
*X11::Xlib::XCrossingEvent::x_root= *_x_root;
*X11::Xlib::XCrossingEvent::y= *_y;
*X11::Xlib::XCrossingEvent::y_root= *_y_root;


@X11::Xlib::XDestroyWindowEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XDestroyWindowEvent::event= *_event;
*X11::Xlib::XDestroyWindowEvent::window= *_window;


@X11::Xlib::XExposeEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XExposeEvent::count= *_count;
*X11::Xlib::XExposeEvent::height= *_height;
*X11::Xlib::XExposeEvent::width= *_width;
*X11::Xlib::XExposeEvent::window= *_window;
*X11::Xlib::XExposeEvent::x= *_x;
*X11::Xlib::XExposeEvent::y= *_y;


@X11::Xlib::XFocusChangeEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XFocusChangeEvent::detail= *_detail;
*X11::Xlib::XFocusChangeEvent::mode= *_mode;
*X11::Xlib::XFocusChangeEvent::window= *_window;


@X11::Xlib::XGenericEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XGenericEvent::evtype= *_evtype;
*X11::Xlib::XGenericEvent::extension= *_extension;


@X11::Xlib::XGraphicsExposeEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XGraphicsExposeEvent::count= *_count;
*X11::Xlib::XGraphicsExposeEvent::drawable= *_drawable;
*X11::Xlib::XGraphicsExposeEvent::height= *_height;
*X11::Xlib::XGraphicsExposeEvent::major_code= *_major_code;
*X11::Xlib::XGraphicsExposeEvent::minor_code= *_minor_code;
*X11::Xlib::XGraphicsExposeEvent::width= *_width;
*X11::Xlib::XGraphicsExposeEvent::x= *_x;
*X11::Xlib::XGraphicsExposeEvent::y= *_y;


@X11::Xlib::XGravityEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XGravityEvent::event= *_event;
*X11::Xlib::XGravityEvent::window= *_window;
*X11::Xlib::XGravityEvent::x= *_x;
*X11::Xlib::XGravityEvent::y= *_y;


@X11::Xlib::XKeyEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XKeyEvent::keycode= *_keycode;
*X11::Xlib::XKeyEvent::root= *_root;
*X11::Xlib::XKeyEvent::same_screen= *_same_screen;
*X11::Xlib::XKeyEvent::state= *_state;
*X11::Xlib::XKeyEvent::subwindow= *_subwindow;
*X11::Xlib::XKeyEvent::time= *_time;
*X11::Xlib::XKeyEvent::window= *_window;
*X11::Xlib::XKeyEvent::x= *_x;
*X11::Xlib::XKeyEvent::x_root= *_x_root;
*X11::Xlib::XKeyEvent::y= *_y;
*X11::Xlib::XKeyEvent::y_root= *_y_root;


@X11::Xlib::XKeymapEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XKeymapEvent::key_vector= *_key_vector;
*X11::Xlib::XKeymapEvent::window= *_window;


@X11::Xlib::XMapEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XMapEvent::event= *_event;
*X11::Xlib::XMapEvent::override_redirect= *_override_redirect;
*X11::Xlib::XMapEvent::window= *_window;


@X11::Xlib::XMapRequestEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XMapRequestEvent::parent= *_parent;
*X11::Xlib::XMapRequestEvent::window= *_window;


@X11::Xlib::XMappingEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XMappingEvent::count= *_count;
*X11::Xlib::XMappingEvent::first_keycode= *_first_keycode;
*X11::Xlib::XMappingEvent::request= *_request;
*X11::Xlib::XMappingEvent::window= *_window;


@X11::Xlib::XMotionEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XMotionEvent::is_hint= *_is_hint;
*X11::Xlib::XMotionEvent::root= *_root;
*X11::Xlib::XMotionEvent::same_screen= *_same_screen;
*X11::Xlib::XMotionEvent::state= *_state;
*X11::Xlib::XMotionEvent::subwindow= *_subwindow;
*X11::Xlib::XMotionEvent::time= *_time;
*X11::Xlib::XMotionEvent::window= *_window;
*X11::Xlib::XMotionEvent::x= *_x;
*X11::Xlib::XMotionEvent::x_root= *_x_root;
*X11::Xlib::XMotionEvent::y= *_y;
*X11::Xlib::XMotionEvent::y_root= *_y_root;


@X11::Xlib::XNoExposeEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XNoExposeEvent::drawable= *_drawable;
*X11::Xlib::XNoExposeEvent::major_code= *_major_code;
*X11::Xlib::XNoExposeEvent::minor_code= *_minor_code;


@X11::Xlib::XPropertyEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XPropertyEvent::atom= *_atom;
*X11::Xlib::XPropertyEvent::state= *_state;
*X11::Xlib::XPropertyEvent::time= *_time;
*X11::Xlib::XPropertyEvent::window= *_window;


@X11::Xlib::XReparentEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XReparentEvent::event= *_event;
*X11::Xlib::XReparentEvent::override_redirect= *_override_redirect;
*X11::Xlib::XReparentEvent::parent= *_parent;
*X11::Xlib::XReparentEvent::window= *_window;
*X11::Xlib::XReparentEvent::x= *_x;
*X11::Xlib::XReparentEvent::y= *_y;


@X11::Xlib::XResizeRequestEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XResizeRequestEvent::height= *_height;
*X11::Xlib::XResizeRequestEvent::width= *_width;
*X11::Xlib::XResizeRequestEvent::window= *_window;


@X11::Xlib::XSelectionClearEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XSelectionClearEvent::selection= *_selection;
*X11::Xlib::XSelectionClearEvent::time= *_time;
*X11::Xlib::XSelectionClearEvent::window= *_window;


@X11::Xlib::XSelectionEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XSelectionEvent::property= *_property;
*X11::Xlib::XSelectionEvent::requestor= *_requestor;
*X11::Xlib::XSelectionEvent::selection= *_selection;
*X11::Xlib::XSelectionEvent::target= *_target;
*X11::Xlib::XSelectionEvent::time= *_time;


@X11::Xlib::XSelectionRequestEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XSelectionRequestEvent::owner= *_owner;
*X11::Xlib::XSelectionRequestEvent::property= *_property;
*X11::Xlib::XSelectionRequestEvent::requestor= *_requestor;
*X11::Xlib::XSelectionRequestEvent::selection= *_selection;
*X11::Xlib::XSelectionRequestEvent::target= *_target;
*X11::Xlib::XSelectionRequestEvent::time= *_time;


@X11::Xlib::XUnmapEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XUnmapEvent::event= *_event;
*X11::Xlib::XUnmapEvent::from_configure= *_from_configure;
*X11::Xlib::XUnmapEvent::window= *_window;


@X11::Xlib::XVisibilityEvent::ISA= ( __PACKAGE__ );
*X11::Xlib::XVisibilityEvent::state= *_state;
*X11::Xlib::XVisibilityEvent::window= *_window;

=head2 XButtonEvent

Used for event type: ButtonPress, ButtonRelease

  button            - unsigned int
  root              - Window
  same_screen       - Bool
  state             - unsigned int
  subwindow         - Window
  time              - Time
  window            - Window
  x                 - int
  x_root            - int
  y                 - int
  y_root            - int

=head2 XCirculateEvent

Used for event type: CirculateNotify

  event             - Window
  place             - int
  window            - Window

=head2 XCirculateRequestEvent

Used for event type: CirculateRequest

  parent            - Window
  place             - int
  window            - Window

=head2 XClientMessageEvent

Used for event type: ClientMessage

  b                 - char [ 20 ]
  l                 - long [ 5 ]
  s                 - short [ 10 ]
  format            - int
  message_type      - Atom
  window            - Window

=head2 XColormapEvent

Used for event type: ColormapNotify

  colormap          - Colormap
  new               - Bool
  state             - int
  window            - Window

=head2 XConfigureEvent

Used for event type: ConfigureNotify

  above             - Window
  border_width      - int
  event             - Window
  height            - int
  override_redirect - Bool
  width             - int
  window            - Window
  x                 - int
  y                 - int

=head2 XConfigureRequestEvent

Used for event type: ConfigureRequest

  above             - Window
  border_width      - int
  detail            - int
  height            - int
  parent            - Window
  value_mask        - unsigned long
  width             - int
  window            - Window
  x                 - int
  y                 - int

=head2 XCreateWindowEvent

Used for event type: CreateNotify

  border_width      - int
  height            - int
  override_redirect - Bool
  parent            - Window
  width             - int
  window            - Window
  x                 - int
  y                 - int

=head2 XCrossingEvent

Used for event type: EnterNotify, LeaveNotify

  detail            - int
  focus             - Bool
  mode              - int
  root              - Window
  same_screen       - Bool
  state             - unsigned int
  subwindow         - Window
  time              - Time
  window            - Window
  x                 - int
  x_root            - int
  y                 - int
  y_root            - int

=head2 XDestroyWindowEvent

Used for event type: DestroyNotify

  event             - Window
  window            - Window

=head2 XExposeEvent

Used for event type: Expose

  count             - int
  height            - int
  width             - int
  window            - Window
  x                 - int
  y                 - int

=head2 XFocusChangeEvent

Used for event type: FocusIn, FocusOut

  detail            - int
  mode              - int
  window            - Window

=head2 XGenericEvent

Used for event type: GenericEvent

  evtype            - int
  extension         - int

=head2 XGraphicsExposeEvent

Used for event type: GraphicsExpose

  count             - int
  drawable          - Drawable
  height            - int
  major_code        - int
  minor_code        - int
  width             - int
  x                 - int
  y                 - int

=head2 XGravityEvent

Used for event type: GravityNotify

  event             - Window
  window            - Window
  x                 - int
  y                 - int

=head2 XKeyEvent

Used for event type: KeyPress, KeyRelease

  keycode           - unsigned int
  root              - Window
  same_screen       - Bool
  state             - unsigned int
  subwindow         - Window
  time              - Time
  window            - Window
  x                 - int
  x_root            - int
  y                 - int
  y_root            - int

=head2 XKeymapEvent

Used for event type: KeymapNotify

  key_vector        - char [ 32 ]
  window            - Window

=head2 XMapEvent

Used for event type: MapNotify

  event             - Window
  override_redirect - Bool
  window            - Window

=head2 XMapRequestEvent

Used for event type: MapRequest

  parent            - Window
  window            - Window

=head2 XMappingEvent

Used for event type: MappingNotify

  count             - int
  first_keycode     - int
  request           - int
  window            - Window

=head2 XMotionEvent

Used for event type: MotionNotify

  is_hint           - char
  root              - Window
  same_screen       - Bool
  state             - unsigned int
  subwindow         - Window
  time              - Time
  window            - Window
  x                 - int
  x_root            - int
  y                 - int
  y_root            - int

=head2 XNoExposeEvent

Used for event type: NoExpose

  drawable          - Drawable
  major_code        - int
  minor_code        - int

=head2 XPropertyEvent

Used for event type: PropertyNotify

  atom              - Atom
  state             - int
  time              - Time
  window            - Window

=head2 XReparentEvent

Used for event type: ReparentNotify

  event             - Window
  override_redirect - Bool
  parent            - Window
  window            - Window
  x                 - int
  y                 - int

=head2 XResizeRequestEvent

Used for event type: ResizeRequest

  height            - int
  width             - int
  window            - Window

=head2 XSelectionClearEvent

Used for event type: SelectionClear

  selection         - Atom
  time              - Time
  window            - Window

=head2 XSelectionEvent

Used for event type: SelectionNotify

  property          - Atom
  requestor         - Window
  selection         - Atom
  target            - Atom
  time              - Time

=head2 XSelectionRequestEvent

Used for event type: SelectionRequest

  owner             - Window
  property          - Atom
  requestor         - Window
  selection         - Atom
  target            - Atom
  time              - Time

=head2 XUnmapEvent

Used for event type: UnmapNotify

  event             - Window
  from_configure    - Bool
  window            - Window

=head2 XVisibilityEvent

Used for event type: VisibilityNotify

  state             - int
  window            - Window

=cut

# END GENERATED X11_Xlib_XEvent
# ----------------------------------------------------------------------------

1;

__END__

=head1 AUTHOR

Olivier Thauvin, E<lt>nanardon@nanardon.zarb.orgE<gt>

Michael Conrad, E<lt>mike@nrdvana.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Olivier Thauvin

Copyright (C) 2017 by Michael Conrad

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
