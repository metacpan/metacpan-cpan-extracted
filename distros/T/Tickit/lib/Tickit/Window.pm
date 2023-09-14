#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2019 -- leonerd@leonerd.org.uk

package Tickit::Window 0.74;

use v5.14;
use warnings;

use Carp;

use Scalar::Util qw( weaken refaddr blessed );
use List::Util qw( first );

use Tickit::Pen;
use Tickit::Rect;
use Tickit::RectSet;
use Tickit::RenderBuffer;
use Tickit::Utils qw( string_countmore );

use Tickit::Debug;

use constant WEAKEN_CHILDREN => $ENV{TICKIT_CHILD_WINDOWS_WEAKEN} // 1;

=head1 NAME

C<Tickit::Window> - a window for drawing operations

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Pen;

 my $tickit = Tickit->new;

 my $rootwin = $tickit->rootwin;

 $rootwin->bind_event( expose => sub {
    my ( $win, undef, $info ) = @_;

    my $rb = $info->rb;

    $rb->clear;

    $rb->text_at(
       int( $win->lines / 2 ), int( ($win->cols - 12) / 2 ),
       "Hello, world"
    );
 });
 $rootwin->bind_event( geomchange => sub { shift->expose } );
 $rootwin->set_pen( Tickit::Pen->new( fg => "white" ) );

 $rootwin->expose;
 $tickit->run;

=head1 DESCRIPTION

Provides coordination of widget drawing activities. A C<Window> represents a
region of the screen that a widget occupies.

Windows cannot directly be constructed. Instead they are obtained by
sub-division of other windows, ultimately coming from the
root window associated with the terminal.

Normally all windows are visible, but a window may be hidden by calling the
C<hide> method. After this, the window will not respond to any of the drawing
methods, until it is made visible again with the C<show> method. A hidden
window will not receive focus or input events. It may still receive geometry
change events if it is resized.

=head2 Sub Windows

A division of a window made by calling C<make_sub> or C<make_float> obtains a
window that represents some portion of the drawing area of the parent window.
Child windows are stored in order; C<make_sub> adds a new child to the end of
the list, and C<make_float> adds one at the start.

Higher windows (windows more towards the start of the list), will always handle
input events before lower siblings. The extent of windows also obscures lower
windows; drawing on lower windows may not be visible because higher windows
are above it.

=head2 Deferred Child Window Operations

In order to minimise the chances of ordering-specific bugs in window event
handlers that cause child window creation, reordering or deletion, the actual
child window list is only mutated after the event processing has finished, by
using a L<Tickit> C<later> block.

=cut

# Internal constructor
sub new
{
   my $class = shift;
   my ( $tickit ) = @_;

   return $class->_new_root( $tickit->term, $tickit );
}

# We need to ensure all geomety changes happen before any redrawing

=head1 METHODS

=cut

=head2 close

   $win->close

Removes the window from its parent and clears any event handlers set using
L<bind_event>. Also recursively closes any child windows.

Currently this is an optional method, as child windows are stored as weakrefs,
so should be destroyed when the last reference to them is dropped. Widgets
should make sure to call this method anyway, because this will be changed in a
future version.

=cut

=head2 make_sub

   $sub = $win->make_sub( $top, $left, $lines, $cols )

Constructs a new sub-window of the given geometry, and places it at the end of
the child window list; below any other siblings.

=cut

sub make_sub
{
   my $self = shift;
   return $self->_make_sub( @_, WINDOW_LOWEST );
}

=head2 make_hidden_sub

   $sub = $win->make_hidden_sub( $top, $left, $lines, $cols )

Constructs a new sub-window like C<make_sub>, but the window starts initially
hidden. This avoids having to call C<hide> separately afterwards.

=cut

sub make_hidden_sub
{
   my $self = shift;
   return $self->_make_sub( @_, WINDOW_HIDDEN );
}

=head2 make_float

   $float = $win->make_float( $top, $left, $lines, $cols )

Constructs a new sub-window of the given geometry, and places it at the start
of the child window list; above any other siblings.

=cut

sub make_float
{
   my $self = shift;
   return $self->_make_sub( @_, 0 );
}

=head2 make_popup

   $popup = $win->make_popup( $top, $left, $lines, $cols )

Constructs a new floating popup window starting at the given coordinates
relative to this window. It will be sized to the given limits.

This window will have the root window as its parent, rather than the window
the method was called on. Additionally, a popup window will steal all keyboard
and mouse events that happen, regardless of focus or mouse position. It is
possible that, if the window has an C<on_mouse> handler, that it may receive
mouse events from outwide the bounds of the window.

=cut

sub make_popup
{
   my $self = shift;
   return $self->_make_sub( @_, WINDOW_POPUP );
}

=head2 bind_event

   $id = $win->bind_event( $ev, $code, $data )

Installs a new event handler to watch for the event specified by C<$ev>,
invoking the C<$code> reference when it occurs. C<$code> will be invoked with
the given window, the event name, an event information object, and the
C<$data> value it was installed with. C<bind_event> returns an ID value that
may be used to remove the handler by calling C<unbind_event_id>.

 $ret = $code->( $win, $ev, $info, $data )

The type of C<$info> will depend on the kind of event that was received, as
indicated by C<$ev>. The information structure types are documented in
L<Tickit::Event>.

=head2 bind_event (with flags)

   $id = $win->bind_event( $ev, $flags, $code, $data )

The C<$code> argument may optionally be preceded by an integer of flag
values. This should be zero to apply default semantics, or a bitmask of
constants. The constants are documented in
L<Tickit::Term/bind_event (with flags)>.

=cut

sub bind_event
{
   my $self = shift;
   my $ev = shift;
   my ( $flags, $code, $data ) = ( ref $_[0] ) ? ( 0, @_ ) : @_;

   $self->_bind_event( $ev, $flags, $code, $data );
}

=head2 unbind_event_id

   $win->unbind_event_id( $id )

Removes an event handler that returned the given C<$id> value.

=cut

=head2 raise

   $win->raise

=head2 lower

   $win->lower

Moves the order of the window in its parent one higher or lower relative to
its siblings.

=cut

=head2 raise_to_front

   $win->raise_to_front

Moves the order of the window in its parent to be the front-most among its
siblings.

=cut

=head2 lower_to_back

   $win->lower_to_back

Moves the order of the window in its parent to be the back-most among its
siblings.

=cut

=head2 parent

   $parentwin = $win->parent

Returns the parent window; i.e. the window on which C<make_sub> or
C<make_float> was called to create this one

=cut

=head2 subwindows

   @windows = $win->subwindows

Returns a list of the subwindows of this one. They are returned in order,
highest first.

=cut

=head2 root

   $rootwin = $win->root

Returns the root window

=cut

=head2 term

   $term = $win->term

Returns the L<Tickit::Term> instance of the terminal on which this window
lives.

Note that it is not guaranteed that this method will return the same
Perl-level terminal instance that the root window was constructed with. In
particular, if the root window in fact lives on a mock terminal created by
L<Tickit::Test::MockTerm> this method may "forget" this fact, returning an
object instance simply in the C<Tickit::Term> class instead. While the
instance will still be useable as a terminal, the fact it was a mock terminal
may get forgotten.

=cut

=head2 tickit

   $tickit = $win->tickit

Returns the L<Tickit> instance with which this window is associated.

=cut

sub tickit
{
   return shift->root->_tickit;
}

=head2 show

   $win->show

Makes the window visible. Allows drawing methods to output to the terminal.
Calling this method also exposes the window, invoking the C<on_expose>
handler. Shows the cursor if this window currently has focus.

=cut

=head2 hide

   $win->hide

Makes the window invisible. Prevents drawing methods outputting to the
terminal. Hides the cursor if this window currently has focus.

=cut

=head2 is_visible

   $visible = $win->is_visible

Returns true if the window is currently visible.

=cut

=head2 resize

   $win->resize( $lines, $cols )

Change the size of the window.

=cut

=head2 reposition

   $win->reposition( $top, $left )

Move the window relative to its parent.

=cut

=head2 change_geometry

   $win->change_geometry( $top, $left, $lines, $cols )

A combination of C<resize> and C<reposition>, to atomically change all the
coordinates of the window. Will only invoke C<on_geom_changed> once, rather
than twice as would be the case calling the above methods individually.

=cut

our $INDENT = "";
sub _do_expose
{
   my $self = shift;
   my ( $rect, $rb ) = @_;

   $rb->setpen( $self->pen );

   Tickit::Debug->log( Wx => "${INDENT}Expose %s %s", $self->sprintf, $rect->sprintf ) if DEBUG;
   local $INDENT = "| $INDENT";

   foreach my $win ( $self->subwindows ) {
      next unless $win->is_visible;

      if( my $winrect = $rect->intersect( $win->rect ) ) {
         $rb->save;

         $rb->clip( $winrect );
         $rb->translate( $win->top, $win->left );
         $win->_do_expose( $winrect->translate( -$win->top, -$win->left ), $rb );

         $rb->restore;
      }

      $rb->mask( $win->rect );
   }

   $rb->save;

   $self->_fire_event( expose => Tickit::Event::Expose->_new( $rb, $rect ) );

   $rb->restore;
}

=head2 expose

   $win->expose( $rect )

Marks the given region of the window as having been exposed, to invoke the
C<on_expose> event handler on itself, and all its child windows. The window's
own handler will be invoked first, followed by all the child windows, in
screen order (top to bottom, then left to right).

If C<$rect> is not supplied it defaults to exposing the entire window area.

The C<on_expose> event handler isn't invoked immediately; instead, the
C<Tickit> C<later> method is used to invoke it at the next round of IO event
handling. Until then, any other window could be exposed. Duplicates are
suppressed; so if a window and any of its ancestors are both queued for
expose, the actual handler will only be invoked once per unique region of the
window.

=cut

=head2 getctl

=head2 setctl

   $value = $win->getctl( $ctl )

   $success = $win->setctl( $ctl, $value )

Accessor and mutator for window control options. C<$ctl> should be one of the
following options:

=over 4

=item cursor-blink (bool)

=item cursor-shape (int)

=item cursor-visible (bool)

Cursor properties to set for the terminal cursor when this window has input
focus.

=item focus-child-notify (bool)

Whether the window will also receive focus events about child windows.

=item steal-input (bool)

Whether the window is currently stealing input from its siblings.

=back

=cut

=head2 set_focus_child_notify

   $win->set_focus_child_notify( $notify )

If set to a true value, the C<on_focus> event handler will also be invoked
when descendent windows gain or lose focus, in addition to when it gains or
loses focus itself. Defaults to false; meaning the C<on_focus> handler only
receives notifications about the window itself.

=cut

sub set_focus_child_notify
{
   my $self = shift;
   my ( $notify ) = @_;

   $self->setctl( 'focus-child-notify' => $notify );
}

=head2 top

=head2 bottom

=head2 left

=head2 right

   $top    = $win->top

   $bottom = $win->bottom

   $left   = $win->left

   $right  = $win->right

Returns the coordinates of the start of the window, relative to the parent
window.

=cut

sub bottom
{
   my $self = shift;
   return $self->top + $self->lines;
}

sub right
{
   my $self = shift;
   return $self->left + $self->cols;
}

=head2 abs_top

=head2 abs_left

   $top  = $win->abs_top

   $left = $win->abs_left

Returns the coordinates of the start of the window, relative to the root
window.

=cut

=head2 cols

=head2 lines

   $cols  = $win->cols

   $lines = $win->lines

Obtain the size of the window

=cut

=head2 selfrect

   $rect = $win->selfrect

Returns a L<Tickit::Rect> containing representing the window's extent within
itself. This will have C<top> and C<left> equal to 0.

=cut

sub selfrect
{
   my $self = shift;
   # TODO: Cache this, invalidate it in ->change_geometry
   return Tickit::Rect->new(
      top   => 0,
      left  => 0,
      lines => $self->lines,
      cols  => $self->cols,
   );
}

=head2 rect

   $rect = $win->rect

Returns a L<Tickit::Rect> containing representing the window's extent relative
to its parent

=cut

sub rect
{
   my $self = shift;
   # TODO: Cache this, invalidate it in ->change_geometry
   return Tickit::Rect->new(
      top   => $self->top,
      left  => $self->left,
      lines => $self->lines,
      cols  => $self->cols,
   );
}

=head2 pen

   $pen = $win->pen

Returns the current L<Tickit::Pen> object associated with this window

=cut

=head2 set_pen

   $win->set_pen( $pen )

Replace the current L<Tickit::Pen> object for this window with a new one. The
object reference will be stored, allowing it to be shared with other objects.
If C<undef> is set, then a new, blank pen will be constructed.

=cut

=head2 getpenattr

   $val = $win->getpenattr( $attr )

Returns a single attribue from the current pen

=cut

sub getpenattr
{
   my $self = shift;
   my ( $attr ) = @_;

   return $self->pen->getattr( $attr );
}

=head2 get_effective_pen

   $pen = $win->get_effective_pen

Returns a new L<Tickit::Pen> containing the effective pen attributes for the
window, combined by those of all its parents.

=cut

sub get_effective_pen
{
   my $win = shift;

   my $pen = $win->pen->as_mutable;
   for( my $parent = $win->parent; $parent; $parent = $parent->parent ) {
      $pen->default_from( $parent->pen );
   }

   return $pen;
}

=head2 get_effective_penattr

   $val = $win->get_effective_penattr( $attr )

Returns the effective value of a pen attribute. This will be the value of this
window's attribute if set, or the effective value of the attribute from its
parent.

=cut

sub get_effective_penattr
{
   my $win = shift;
   my ( $attr ) = @_;

   for( ; $win; $win = $win->parent ) {
      my $value = $win->pen->getattr( $attr );
      return $value if defined $value;
   }

   return undef;
}

=head2 scrollrect

   $success = $win->scrollrect( $rect, $downward, $rightward )

   $success = $win->scrollrect( $top, $left, $lines, $cols, $downward, $rightward )

   $success = $win->scrollrect( ..., $pen )

   $success = $win->scrollrect( ..., %attrs )

Attempt to scroll the rectangle of the window (either given by a
C<Tickit::Rect> or defined by the first four parameters) by an amount given
by the latter two. Since most terminals cannot perform arbitrary rectangle
scrolling, this method returns a boolean to indicate if it was successful.
The caller should test this return value and fall back to another drawing
strategy if the attempt was unsuccessful.

Optionally, a C<Tickit::Pen> instance or hash of pen attributes may be
provided, to override the background colour used for erased sections behind
the scroll.

The cursor may move as a result of calling this method; its location is
undefined if this method returns successful. The terminal pen, in particular
the background colour, may be modified by this method even if it fails to
scroll the terminal (and returns false).

This method will enqueue all of the required expose requests before returning,
so in this case the return value is not interesting.

=cut

sub scrollrect
{
   my $self = shift;
   my $rect;
   if( blessed $_[0] and $_[0]->isa( "Tickit::Rect" ) ) {
      $rect = shift;
   }
   else {
      my ( $top, $left, $lines, $cols ) = splice @_, 0, 4;
      $rect = Tickit::Rect->new(
         top   => $top,
         left  => $left,
         lines => $lines,
         cols  => $cols,
      );
   }
   my ( $downward, $rightward, @penargs ) = @_;
   die "PENARGS" if @penargs;

   my $pen = ( @penargs == 0 ) ? undef :
             ( @penargs == 1 ) ? $penargs[0]->as_mutable :
                                 Tickit::Pen::Mutable->new( @penargs );

   $self->_scrollrect( $rect, $downward, $rightward, $pen );
}

=head2 scroll

   $success = $win->scroll( $downward, $rightward )

A shortcut for calling C<scrollrect> on the entire region of the window.

=cut

sub scroll
{
   my $self = shift;
   my ( $downward, $rightward ) = @_;

   return $self->scrollrect(
      0, 0, $self->lines, $self->cols,
      $downward, $rightward
   );
}

=head2 scroll_with_children

   $win->scroll_with_children( $downward, $rightward )

Similar to C<scroll> but ignores child windows of this one, moving all of
the terminal content paying attention only to obscuring by newer siblings of
ancestor windows.

This method is experimental, intended only for use by
L<Tickit::Widget::ScrollBox>. After calling this method, the terminal content
will have moved and the windows drawing them will be confused unless the
window position was also updated. C<ScrollBox> takes care to do this.

=cut

sub scroll_with_children
{
   my $self = shift;
   my ( $downward, $rightward, @args ) = @_;
   die "PENARGS" if @args;

   my $pen = ( @args == 0 ) ? undef :
             ( @args == 1 ) ? $args[0]->as_mutable :
                              Tickit::Pen::Mutable->new( @args );

   $self->_scroll_with_children( $downward, $rightward );
}

=head2 cursor_at

   $win->cursor_at( $line, $col )

Sets the position in the window at which the terminal cursor will be placed if
this window has focus. This method does I<not> force the window to take the
focus though; for that see C<take_focus>.

=cut

sub cursor_at
{
   my $self = shift;
   $self->set_cursor_position( @_ );
}

=head2 cursor_visible

   $win->cursor_visible( $visible )

Sets whether the terminal cursor is visible on the window when it has focus.
Normally it is, but passing a false value will make the cursor hidden even
when the window is focused.

=cut

sub set_cursor_visible
{
   my $self = shift;
   my ( $visible ) = @_;

   $self->setctl( 'cursor-visible' => $visible );
}

*cursor_visible = \&set_cursor_visible;

=head2 cursor_shape

   $win->cursor_shape( $shape )

Sets the shape that the terminal cursor will have if this window has focus.
This method does I<not> force the window to take the focus though; for that
see C<take_focus>. Valid values for C<$shape> are the various
C<CURSORSHAPE_*> constants from L<Tickit::Term>.

=cut

sub set_cursor_shape
{
   my $self = shift;
   my ( $shape ) = @_;

   $self->setctl( 'cursor-shape' => $shape );
}

*cursor_shape = \&set_cursor_shape;

=head2 take_focus

   $win->take_focus

Causes this window to take the input focus, and updates the cursor position to
the stored active position given by C<cursor_at>.

=cut

=head2 focus

   $win->focus( $line, $col )

A convenient shortcut combining C<cursor_at> with C<take_focus>; setting the
focus cursor position and taking the input focus.

=cut

sub focus
{
   my $self = shift;
   $self->cursor_at( @_ );
   $self->take_focus;
}

=head2 is_focused

   $focused = $win->is_focused

Returns true if this window currently has the input focus

=cut

=head2 is_steal_input

   $steal = $win->is_steal_input

Returns true if this window is currently stealing input from its siblings

=cut

sub is_steal_input
{
   my $self = shift;

   return $self->getctl( 'steal-input' );
}

=head2 set_steal_input

   $win->set_steal_input( $steal )

Controls whether this window is currently stealing input from its siblings

=cut

sub set_steal_input
{
   my $self = shift;
   my ( $steal ) = @_;

   $self->setctl( 'steal-input' => $steal );
}

sub sprintf
{
   my $self = shift;
   return sprintf "[%dx%d abs@%d,%d]", $self->cols, $self->lines, $self->abs_left, $self->abs_top;
}

use overload
   '""' => sub {
      my $self = shift;
      return ref($self) . $self->sprintf,
   },
   '0+' => sub {
      my $self = shift;
      return $self;
   },
   bool => sub { 1 },
   fallback => 1;

=head1 EVENTS

The following event types are emitted and may be observed by L</bind_event>.

=head2 key

Emitted when a key on the keyboard is pressed while this window or one of its
child windows has the input focus, or is set to steal input anyway.

The event handler should return a true value if it considers the keypress
dealt with, or false to pass it up to its parent window.

Before passing it to its parent, a window will also try any other non-focused
sibling windows of the currently-focused window in order of creation (though
note this order is not necessarily the order the child widgets that own those
windows were created or added to their container).

If no window actually handles the keypress, then every window will eventually
be consulted about it, preferring windows closer to the focused one.

This broadcast-like behaviour allows widgets to handle keypresses that should
make sense even though their window does not actually have the keyboard focus.
This feature should be used sparingly, to only capture one or two keypresses
that really make sense; for example to capture the C<PageUp> and C<PageDown>
keys in a scrolling list, or a numbered function key that performs some
special action.

=head2 mouse

Emitted when a mouse button is pressed or released, the cursor moved while a
button is held (a dragging event), or the wheel is scrolled.

The following event names may be observed:

=over 8

=item press

A mouse button has been pressed down on this cell

=item drag_start

The mouse was moved while a button was held, and was initially in the given
cell

=item drag

The mouse was moved while a button was held, and is now in the given cell

=item drag_outside

The mouse was moved outside of the window that handled the C<drag_start>
event, and is still being dragged.

=item drag_drop

A mouse button was released after having been moved, while in the given cell

=item drag_stop

The drag operation has finished. This event is always given directly to the
window that handled the C<drag_start> event, rather than the window on which
the mouse release event happened.

=item release

A mouse button was released after being pressed

=item wheel

The mouse wheel was moved. C<button> will indicate the wheel direction as a
string C<up> or C<down>.

=back

The invoked code should return a true value if it considers the mouse event
dealt with, or false to pass it up to its parent window.

Once a dragging operation has begun via C<drag_start>, the window that handled
the event will always receive C<drag>, C<drag_outside>, and an eventual
C<drag_stop> event even if the mouse moves outside that window. No other
window will receive a C<drag_outside> or C<drag_stop> event than the one that
started the operation.

=head2 geomchange

Emitted when the window is resized or repositioned; i.e. whenever its geometry
changes.

=head2 expose

Emitted when a region of the window is exposed by the L<expose> method, or
implicitly because it or another window has changed size, been shown or
hidden, or the stacking order has been changed.

When invoked, render buffer passed in the event will have its origin set to
that of the window, and its clipping will be set to the damage rectangle.

If any child windows overlap the region, these will be exposed first, before
the containing window.

=head2 focus

Emitted when the window gains or loses input focus.

If the C<focus-child-notify> behavior is enabled, this callback is also
invoked for changes of focus on descendent windows. In this case, it is
passed an additional argument, being the immediate child window in which the
focus chain has now changed (which may or may not be the focused window
directly; it could itself be another ancestor).

When a window gains focus, any of its ancestors that have
C<focus-child-notify> enabled will be informed first, from the outermost
inwards, before the window itself. When one loses focus, it is notified
first, and then its parents from the innermost outwards.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
