#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2022 -- leonerd@leonerd.org.uk

use v5.20;
use Object::Pad 0.70 ':experimental(adjust_params)';

package Tickit::Widget 0.57;
class Tickit::Widget :repr(HASH);

use experimental 'postderef';

use Carp;
use Scalar::Util qw( blessed weaken );
use List::Util 1.33 qw( all );

use Tickit::Pen;
use Tickit::Style;
use Tickit::Utils qw( textwidth );
use Tickit::Window 0.57;  # $win->bind_event
use Tickit::Event 0.66;  # $info->type newapi

use constant PEN_ATTR_MAP => { map { $_ => 1 } @Tickit::Pen::ALL_ATTRS };

use constant KEYPRESSES_FROM_STYLE => 0;

use constant CAN_FOCUS => 0;

=head1 NAME

C<Tickit::Widget> - abstract base class for on-screen widgets

=head1 DESCRIPTION

This class acts as an abstract base class for on-screen widget objects. It
provides the lower-level machinery required by most or all widget types.

Objects cannot be directly constructed in this class. Instead, a subclass of
this class which provides a suitable implementation of the C<render_to_rb> and
other provided methods is derived. Instances in that class are then
constructed.

See the C<EXAMPLES> section below.

The core F<Tickit> distribution only contains a couple of simple widget
classes. Many more widget types are available on CPAN. Almost certainly for
any widget-based program you will want to at least install the
L<Tickit::Widgets> distribution, which provides many of the basic UI types of
widget.

=head1 STYLE

The following style tags are used on all widget classes that use Style:

=over 4

=item :focus

Set when this widget has the input focus

=back

The following style actions are used:

=over 4

=item focus_next_before (<Tab>)

=item focus_next_after (<S-Tab>)

Requests the focus move to the next or previous focusable widget in display
order.

=back

=cut

style_definition base =>
   '<Tab>'   => "focus_next_after",
   '<S-Tab>' => "focus_next_before";

=head1 CONSTRUCTOR

=cut

=head2 new

   $widget = Tickit::Widget->new( %args )

Constructs a new C<Tickit::Widget> object. Must be called on a subclass that
implements the required methods; see the B<SUBCLASS METHODS> section below.

Any pen attributes present in C<%args> will be used to set the default values
on the widget's pen object, other than the following:

=over 8

=item class => STRING

=item classes => ARRAY of STRING

If present, gives the C<Tickit::Style> class name or names applied to this
widget.

=item style => HASH

If present, gives a set of "direct applied" style to the Widget. This is
treated as an extra set of style definitions that apply more directly than any
of the style classes or the default definitions.

The hash should contain style keys, optionally suffixed by style tags, giving
values.

   style => {
     'fg'        => 3,
     'fg:active' => 5,
   }

=back

=cut

field @_style_classes;
field $_style_direct;
field %_style_tag;

ADJUST
{
   my $class = ref $self;
   foreach my $method (qw( lines cols render_to_rb )) {
      $class->can( $method ) or
         croak "$class cannot ->$method - do you subclass and implement it?";
   }
}

ADJUST :params (
   :$class = undef,
   :$classes = [ $class ],
) {
   @_style_classes = $classes->@*;
}

ADJUST :params (
   :$style = undef,
   %params
) {
   # Legacy direct-applied-style argument support
   foreach my $attr ( @Tickit::Pen::ALL_ATTRS ) {
      next unless defined( my $val = delete $params{$attr} );

      carp "Applying legacy direct pen attribute '$attr' for ${\ref $self}";
      $style->{$attr} = $val;
   }

   if( $style ) {
      my $tagset = $_style_direct = Tickit::Style::_Tagset->new;
      foreach my $key ( keys %$style ) {
         $tagset->add( $key, $style->{$key} );
      }
   }

   $self->_update_pen( $self->get_style_pen );
}

field $_parent :reader;
field $_window :reader;
field $_pen    :reader;

field $_focus_pending;

field %_event_ids;

=head1 METHODS

=cut

=head2 style_classes

   @classes = $widget->style_classes

Returns a list of the style class names this Widget has.

=cut

method style_classes
{
   return @_style_classes;
}

=head2 set_style_tag

   $widget->set_style_tag( $tag, $value )

Sets the (boolean) state of the named style tag. After calling this method,
the C<get_style_*> methods may return different results. No resizing or
redrawing is necessarily performed; but the widget can use
C<style_reshape_keys>, C<style_reshape_textwidth_keys> or C<style_redraw_keys>
to declare which style keys should cause automatic reshaping or redrawing. In
addition it can override the C<on_style_changed_values> method to inspect the
changes and decide for itself.

=cut

# This is cached, so will need invalidating on style loads
my %KEYS_BY_TYPE_CLASS_TAG;
Tickit::Style::on_style_load( sub { undef %KEYS_BY_TYPE_CLASS_TAG } );

method set_style_tag
{
   my ( $tag, $value ) = @_;

   # Early-return on no change
   return if !$_style_tag{$tag} == !$value;

   # Work out what style keys might depend on this tag
   my %values;

   if( $_style_direct ) {
      KEYSET: foreach my $keyset ( $_style_direct->keysets ) {
         $keyset->tags->{$tag} or next KEYSET;

         $values{$_} ||= [] for keys $keyset->style->%*;
      }
   }

   my $type = $self->_widget_style_type;
   foreach my $class ( $self->style_classes, undef ) {
      my $keys = $KEYS_BY_TYPE_CLASS_TAG{$type}{$class//""}{$tag} ||= do {
         my $tagset = Tickit::Style::_ref_tagset( $type, $class );

         my %keys;
         KEYSET: foreach my $keyset ( $tagset->keysets ) {
            $keyset->tags->{$tag} or next KEYSET;

            $keys{$_}++ for keys $keyset->style->%*;
         }

         [ keys %keys ];
      };

      $values{$_} ||= [] for @$keys;
   }

   my @keys = keys %values;

   my @old_values = $self->get_style_values( @keys );
   $values{$keys[$_]}[0] = $old_values[$_] for 0 .. $#keys;

   $_style_tag{$tag} = !!$value;

   $self->_style_changed_values( \%values );
}

method _style_tags
{
   return join "|", sort grep { $_style_tag{$_} } keys %_style_tag;
}

=head2 get_style_values

   @values = $widget->get_style_values( @keys )

   $value = $widget->get_style_values( $key )

Returns a list of values for the given keys of the currently-applied style.
For more detail see the L<Tickit::Style> documentation. Returns just one value
in scalar context.

=cut

field %_style_cache;

method get_style_values
{
   my @keys = @_;

   my $type = $self->_widget_style_type;

   my @set = ( 0 ) x @keys;
   my @values = ( undef ) x @keys;

   my $cache = $_style_cache{$self->_style_tags} ||= {};

   foreach my $i ( 0 .. $#keys ) {
      next unless exists $cache->{$keys[$i]};

      $set[$i] = 1;
      $values[$i] = $cache->{$keys[$i]};
   }

   my @classes = ( $self->style_classes, undef );
   my $tagset = $_style_direct;

   while( !all { $_ } @set and @classes ) {
      # First time around this uses the direct style, if set. Thereafter uses
      # the style classes in order, finally the unclassed base.
      defined $tagset or $tagset = Tickit::Style::_ref_tagset( $type, shift @classes );

      KEYSET: foreach my $keyset ( $tagset->keysets ) {
         $_style_tag{$_} or next KEYSET for keys $keyset->tags->%*;

         my $style = $keyset->style;

         foreach ( 0 .. $#keys ) {
            exists $style->{$keys[$_]} or next;
            $set[$_] and next;

            $values[$_] = $style->{$keys[$_]};
            $set[$_] = 1;
         }
      }

      undef $tagset;

      # After all the classes, try again with type as "*"
      if( $type ne "*" and !@classes ) {
         $type = "*";
         @classes = ( $self->style_classes, undef );
      }
   }

   foreach my $i ( 0 .. $#keys ) {
      next if exists $cache->{$keys[$i]};

      $cache->{$keys[$i]} = $values[$i];
   }

   return @values if wantarray;
   return $values[0];
}

=head2 get_style_pen

   $pen = $widget->get_style_pen( $prefix )

A shortcut to calling C<get_style_values> to collect up the pen attributes,
and form a L<Tickit::Pen::Immutable> object from them. If C<$prefix> is
supplied, it will be prefixed on the pen attribute names with an underscore
(which would be read from the stylesheet file as a hyphen). Note that the
returned pen instance is immutable, and may be cached.

=cut

field %_style_pen_cache;

method get_style_pen
{
   my $class = ref $self;
   my ( $prefix ) = @_;

   return $_style_pen_cache{$self->_style_tags}{$prefix//""} ||= do {
      my @keys = map { defined $prefix ? "${prefix}_$_" : $_ } @Tickit::Pen::ALL_ATTRS;

      my %attrs;
      @attrs{@Tickit::Pen::ALL_ATTRS} = $self->get_style_values( @keys );

      Tickit::Pen::Immutable->new( %attrs );
   };
}

=head2 get_style_text

   $text = $widget->get_style_text

A shortcut to calling C<get_style_values> for a single key called C<"text">.

=cut

method get_style_text
{
   my $class = ref $self;

   return $self->get_style_values( "text" ) // croak "$class style does not define text";
}

=head2 set_style

   $widget->set_style( %defs )

Changes the widget's direct-applied style.

C<%defs> should contain style keys optionally suffixed with tags in the same
form as that given to the C<style> key to the constructor. Defined values will
add to or replace values already stored by the widget. Keys mapping to
C<undef> are deleted from the stored style.

Note that changing the direct applied style is moderately costly because it
must invalidate all of the cached style values and pens that depend on the
changed keys. For normal runtime changes of style, consider using a tag if
possible, because style caching takes tags into account, and simply changing
applied style tags does not invalidate the caches.

=cut

method set_style
{
   my %defs = @_;

   my $new = Tickit::Style::_Tagset->new;
   $new->add( $_, $defs{$_} ) for keys %defs;

   my %values;
   foreach my $keyset ( $new->keysets ) {
      $values{$_} ||= [] for keys $keyset->style->%*;
   }

   my @keys = keys %values;

   my @old_values = $self->get_style_values( @keys );
   $values{$keys[$_]}[0] = $old_values[$_] for 0 .. $#keys;

   if( $_style_direct ) {
      $_style_direct->merge( $new );
   }
   else {
      $_style_direct = $new;
   }

   $self->_style_changed_values( \%values, 1 );
}

method _style_changed_values
{
   my ( $values, $invalidate_caches ) = @_;

   my @keys = keys %$values;

   if( $invalidate_caches ) {
      foreach my $keyset ( values %_style_cache ) {
         delete $keyset->{$_} for @keys;
      }
   }

   my @new_values = $self->get_style_values( @keys );

   # Remove unchanged keys
   foreach ( 0 .. $#keys ) {
      my $key = $keys[$_];
      my $old = $values->{$key}[0];
      my $new = $new_values[$_];

      delete $values->{$key}, next if !defined $old and !defined $new;
      delete $values->{$key}, next if defined $old and defined $new and $old eq $new;

      $values->{$key}[1] = $new;
   }

   my %changed_pens;
   foreach my $key ( @keys ) {
      PEN_ATTR_MAP->{$key} and
         $changed_pens{""}++;

      $key =~ m/^(.*)_([^_]+)$/ && PEN_ATTR_MAP->{$2} and
         $changed_pens{$1}++;
   }

   if( $invalidate_caches ) {
      foreach my $penset ( values %_style_pen_cache ) {
         delete $penset->{$_} for keys %changed_pens;
      }
   }

   if( $changed_pens{""} ) {
      $self->_update_pen( $self->get_style_pen );
   }

   my $reshape = 0;
   my $redraw  = 0;

   my $type = $self->_widget_style_type;
   foreach ( Tickit::Style::_reshape_keys( $type ) ) {
      next unless $values->{$_};

      $reshape = 1;
      last;
   }

   foreach ( Tickit::Style::_reshape_textwidth_keys( $type ) ) {
      next unless $values->{$_};
      next if textwidth( $values->{$_}[0] ) == textwidth( $values->{$_}[1] );

      $reshape = 1;
      last;
   }

   foreach ( Tickit::Style::_redraw_keys( $type ) ) {
      next unless $values->{$_};

      $redraw = 1;
      last;
   }

   my $code = $self->can( "on_style_changed_values" );
   $self->$code( %$values ) if $code;

   if( $reshape ) {
      $self->reshape;
      $self->redraw;
   }
   elsif( keys %changed_pens or $redraw ) {
      $self->redraw;
   }
}

=head2 set_window

   $widget->set_window( $window )

Sets the L<Tickit::Window> for the widget to draw on. Setting C<undef> removes
the window.

If a window is associated to the widget, that window's pen is set to the
current widget pen. The widget is then drawn to the window by calling the
C<render_to_rb> method. If a window is removed (by setting C<undef>) then no
cleanup of the window is performed; the new owner of the window is expected to
do this.

This method may invoke the C<window_gained> and C<window_lost> methods.

=cut

method set_window
{
   my ( $window ) = @_;

   # Early out if no change
   return if !$window and !$_window;
   return if $window and $_window and $_window == $window;

   if( $_window and !$window ) {
      $_window->set_pen( undef );
      $self->window_lost( $_window );
   }

   $_window = $window;

   if( $window ) {
      $window->set_pen( $_pen );

      $self->window_gained( $_window );

      $window->take_focus, undef $_focus_pending if $_focus_pending;

      $self->reshape;

      $window->expose;
   }
}

method window_gained
{
   my $window = $self->window;

   weaken $self;

   $_event_ids{geomchange} = $window->bind_event( geomchange => sub {
      $self->reshape;
      $self->redraw if !$self->parent;
   } );

   $_event_ids{expose} = $window->bind_event( expose => sub {
      my ( $win, undef, $info ) = @_;
      $win->is_visible or return 1;

      $info->rb->setpen( $_pen );

      $self->render_to_rb( $info->rb, $info->rect );
      return 1;
   });

   $_event_ids{focus} = $window->bind_event( focus => sub {
      my ( $win, undef, $info ) = @_;
      $self->_on_win_focus( $win, $info->type, $info->win );
   } ) if $self->can( "_widget_style_type" );

   if( $self->can( "on_key" ) or $self->KEYPRESSES_FROM_STYLE ) {
      $_event_ids{key} = $window->bind_event( key => sub {
         my ( $win, undef, $info ) = @_;

         {
            # Space comes as " " but we'd prefer to use "Space" in styles
            my $keystr = $info->str eq " " ? "Space" : $info->str;

            my $action;
            $action = $self->get_style_values( "<$keystr>" ) if $self->KEYPRESSES_FROM_STYLE;

            last unless $action;

            my $code = $self->can( "key_$action" );
            return 1 if $code and $code->( $self, $info );
         }
         my $code = $self->can( "on_key" );
         return 1 if $code and $code->( $self, $info );
      } );
   }

   $_event_ids{mouse} = $window->bind_event( mouse => sub {
      my ( $win, undef, $info ) = @_;
      $self->take_focus if $self->CAN_FOCUS and $info->type eq "press" and $info->button == 1;
      $self->on_mouse( $info ) if $self->can( "on_mouse" );
   } );
}

method _on_win_focus
{
   my ( $win, $focus ) = @_;

   $self->set_style_tag( focus => $focus eq "in" );
}

method key_focus_next_after
{
   $self->parent and $self->parent->focus_next( after => $self );
   return 1;
}

method key_focus_next_before
{
   $self->parent and $self->parent->focus_next( before => $self );
   return 1;
}

method window_lost
{
   my $window = $self->window;

   $window->unbind_event_id( $_ ) for values %_event_ids;
}

=head2 window

   $window = $widget->window

Returns the current window of the widget, if one has been set using
C<set_window>.

=cut

# generated

=head2 set_parent

   $widget->set_parent( $parent )

Sets the parent widget; pass C<undef> to remove the parent.

C<$parent>, if defined, must be a subclass of L<Tickit::ContainerWidget>.

=cut

method set_parent
{
   my ( $parent ) = @_;

   !$parent or $parent->isa( "Tickit::ContainerWidget" ) or croak "Parent must be a ContainerWidget";

   weaken( $_parent = $parent );
}

=head2 parent

   $parent = $widget->parent

Returns the current container widget

=cut

# generated accessor

=head2 resized

   $widget->resized

Provided for subclasses to call when their size requirements have or may have
changed. Re-calculates the size requirements by calling C<lines> and C<cols>
again, then calls C<set_requested_size>.

=cut

method resized
{
   # 'scalar' just in case of odd behaviour in subclasses
   $self->set_requested_size( scalar $self->lines, scalar $self->cols );
}

=head2 set_requested_size

   $widget->set_requested_size( $lines, $cols )

Provided for subclasses to call when their size requirements have or may have
changed. Informs the parent that the widget requires a differently-sized
window if the dimensions are now different to last time.

=cut

field $_req_lines;
field $_req_cols;

method set_requested_size
{
   my ( $new_lines, $new_cols ) = @_;

   return if defined $_req_lines and $_req_lines == $new_lines and
             defined $_req_cols  and $_req_cols  == $new_cols;

   $_req_lines = $new_lines;
   $_req_cols  = $new_cols;

   if( $self->parent ) {
      $self->parent->child_resized( $self );
   }
   else {
      $self->reshape if $self->window;
      $self->redraw;
   }
}

=head2 requested_size

   ( $lines, $cols ) = $widget->requested_size

Returns the requested size of the widget; its preferred dimensions. This
method calls C<lines> and C<cols> and caches the result until the next call to
C<resized>. Container widgets should use this method in preference to calling
C<lines> and C<cols> directly.

=head2 requested_lines

   $lines = $widget->requested_lines

=head2 requested_cols

   $cols  = $widget->requested_cols

Returns one or other of the requested dimensions. Shortcuts for calling
C<requested_size>. These are I<temporary> convenience methods to assist
container widgets during the transition to the new sizing model.

=cut

method requested_size
{
   return ( $_req_lines //= $self->lines,
            $_req_cols  //= $self->cols );
}

method requested_lines { ( $self->requested_size )[0] }
method requested_cols  { ( $self->requested_size )[1] }

=head2 redraw

   $widget->redraw

Clears the widget's window then invokes the C<render> method. This should
completely redraw the widget.

This redraw doesn't happen immediately. The widget is marked as needing to
redraw, and its parent is marked that it has a child needing redraw,
recursively to the root widget. These will then be flushed out down the widget
tree using an C<Tickit> C<later> call. This allows other widgets to register a
requirement to redraw, and have them all flushed in a fairly efficient manner.

=cut

method redraw
{
   $self->window or return;
   $self->window->expose;
}

=head2 pen

   $pen = $widget->pen

Returns the widget's L<Tickit::Pen>.

=cut

# generated accessor

method _update_pen
{
   my ( $newpen ) = @_;

   return if $_pen and $_pen == $newpen;

   $_pen = $newpen;

   if( $self->window ) {
      $self->window->set_pen( $newpen );
      $self->redraw;
   }
}

# Default empty implementation
method reshape { }

=head2 take_focus

   $widget->take_focus

Calls C<take_focus> on the Widget's underlying Window, if present, or stores
that the window should take focus when one is eventually set by C<set_window>.

May only be called on Widget subclasses that override C<CAN_FOCUS> to return a
true value.

=cut

method take_focus
{
   croak ref($self) . " cannot ->take_focus" unless $self->CAN_FOCUS;

   if( my $win = $self->window ) {
      $win->take_focus if $win->is_visible;
   }
   else {
      $_focus_pending = 1;
   }
}

=head1 SUBCLASS METHODS

Because this is an abstract class, the constructor must be called on a
subclass which implements the following methods.

=head2 render_to_rb

   $widget->render_to_rb( $renderbuffer, $rect )

Called to redraw the widget's content to the given L<Tickit::RenderBuffer>.

Will be passed the clipping rectangle region to be rendered as a
L<Tickit::Rect>. the method does not have to render any content outside of
this region.

=head2 reshape

   $widget->reshape

Optional. Called after the window geometry is changed. Useful to distribute
window change sizes to contained child widgets.

=head2 lines

   $lines = $widget->lines

=head2 cols

   $cols = $widget->cols

Called to enquire on the requested window for this widget. It is possible that
the actual allocated window may be larger, or smaller than this amount.

=head2 window_gained

   $widget->window_gained( $window )

Optional. Called by C<set_window> when a window has been set for this widget.

=head2 window_lost

   $widget->window_lost( $window )

Optional. Called by C<set_window> when C<undef> has been set as the window for
this widget. The old window object is passed in.

=head2 on_key

   $handled = $widget->on_key( $ev )

Optional. If provided, this method will be set as the C<on_key> callback for
any window set on the widget. By providing this method a subclass can
implement widgets that respond to user input. It receives the same event
arguments structure as the underlying window C<on_key> event.

=head2 on_mouse

   $handled = $widget->on_mouse( $ev )

Optional. If provided, this method will be set as the C<on_mouse> callback for
any window set on the widget. By providing this method a subclass can
implement widgets that respond to user input. If receives the same event
arguments structure as the underlying window C<on_mouse> event.

=head2 on_style_changed_values

   $widget->on_style_changed_values( %values )

Optional. If provided, this method will be called by C<set_style_tag> to
inform the widget which style keys may have changed values, as a result of the
tag change. The style values are passed in ARRAY references of two elements,
containing the old and new values.

The C<%values> hash may contain false positives in some cases, if the old and
the new value are actually the same, but it still appears from the style
definitions that certain keys are changed.

Most of the time this method may not be necessary as the C<style_reshape_keys>
C<style_reshape_textwidth_keys>, and C<style_redraw_keys> declarations should
suffice for most purposes.

=head2 CAN_FOCUS

   $widget->CAN_FOCUS

Optional, normally false. If this constant method returns a true value, the
widget is allowed to take focus using the C<take_focus> method. It will also
take focus automatically if it receives a mouse button 1 press event.

=head2 KEYPRESSES_FROM_STYLE

   $widget->KEYPRESSES_FROM_STYLE

Optional, normally false. If this constant method returns a true value, the
widget will use style information to invoke named methods on keypresses. When
the window's C<on_key> event is invoked, the widget will first attempt to look
up a style key with the name of the pressed key, including its modifier key
prefixes, surrounded by C<< <angle brackets> >>. If this gives the name of a,
method prefixed by C<key_> then that method is invoked as a special-purpose
C<on_key> handler. If this does not exist, or does not return true, then the
widget's regular C<on_key> handler is invoked, if present.

As a special case, space is given the key name C<< <Space> >> instead of being
notated by a literal space character in brackets, for neatness of the style
information.

=cut

=head1 UTILITY FUNCTIONS

The following functions (not methods) are not exported by this package, but
intended to be called by widget subclasses fully-qualified.

=cut

=head2 split_widget_opts

   ( $widget, %opts ) = split_widget_opts( $arg )

If C<$arg> is an object reference derived from C<Tickit::Widget>, return it
directly with no extra options.

If C<$arg> is a reference to an unblessed hash, return the C<widget> value
from it (which must exist), followed by any other keys and values in no
particular order.

This function is intended for methods that add an entire collection of child
widgets in a single call (for example L<Tickit::Widget::LinearBox>'s
C<add_children>) where the caller wants to override options on specific ones.

=cut

sub split_widget_opts
{
   my ( $arg ) = @_;

   my $child;
   my %opts;

   if( blessed $arg and $arg->isa( "Tickit::Widget" ) ) {
      $child = $arg;
   }
   elsif( ref $arg eq "HASH" ) {
      %opts = %$arg;
      $child = delete $opts{child} or
         croak "Expected to find a 'child' key";
   }
   else {
      croak "Unsure what to do with argument $arg";
   }

   return ( $child, %opts );
}

=head1 EXAMPLES

=head2 A Trivial "Hello, World" Widget

The following is about the smallest possible C<Tickit::Widget> implementation,
containing the bare minimum of functionality. It displays the fixed string
"Hello, world" at the top left corner of its window.

   package HelloWorldWidget;
   use base 'Tickit::Widget';

   sub lines {  1 }
   sub cols  { 12 }

   sub render_to_rb
   {
      my $self = shift;
      my ( $rb, $rect ) = @_;

      $rb->eraserect( $rect );

      $rb->text_at( 0, 0, "Hello, world" );
   }

   1;

The C<lines> and C<cols> methods tell the container of the widget what its
minimum size requirements are, and the C<render_to_rb> method actually draws
it to the render buffer.

A slight improvement on this would be to obtain the size of the window, and
position the text in the centre rather than the top left corner.

   sub render_to_rb
   {
      my $self = shift;
      my ( $rb, $rect ) = @_;
      my $win = $self->window;

      $rb->eraserect( $rect );

      $rb->text_at( $win->lines - 1 ) / 2, ( $win->cols - 12 ) / 2,
         "Hello, world"
      );
   }

=head2 Reacting To User Input

If a widget subclass provides an C<on_key> method, then this will receive
keypress events if the widget's window has the focus. This example uses it to
change the pen foreground colour.

   package ColourWidget;
   use base 'Tickit::Widget';

   my $text = "Press 0 to 7 to change the colour of this text";

   sub lines { 1 }
   sub cols  { length $text }

   sub render_to_rb
   {
      my $self = shift;
      my ( $rb, $rect ) = @_;
      my $win = $self->window;

      $rb->eraserect( $rect );

      $rb->text_at( $win->lines - 1 ) / 2, ( $win->cols - 12 ) / 2,
         "Hello, world"
      );

      $win->focus( 0, 0 );
   }

   sub on_key
   {
      my $self = shift;
      my ( $args ) = @_;

      if( $args->type eq "text" and $args->str =~ m/[0-7]/ ) {
         $self->set_style( fg => $args->str );
         return 1;
      }

      return 0;
   }

   1;

The C<render_to_rb> method sets the focus at the window's top left corner to
ensure that the window always has focus, so the widget will receive keypress
events. (A real widget implementation would likely pick a more sensible place
to put the cursor).

The C<on_key> method then gets invoked for keypresses. It returns a true value
to indicate the keys it handles, returning false for the others, to allow
parent widgets or the main C<Tickit> object to handle them instead.

Similarly, by providing an C<on_mouse> method, the widget subclass will
receive mouse events within the window of the widget. This example saves a
list of the last 10 mouse clicks and renders them with an C<X>.

   package ClickerWidget;
   use base 'Tickit::Widget';

   # In a real Widget this would be stored in an attribute of $self
   my @points;

   sub lines { 1 }
   sub cols  { 1 }

   sub render_to_rb
   {
      my $self = shift;
      my ( $rb, $rect ) = @_;

      $rb->eraserect( $rect );

      foreach my $point ( @points ) {
         $rb->text_at( $point->[0], $point->[1], "X" );
      }
   }

   sub on_mouse
   {
      my $self = shift;
      my ( $args ) = @_;

      return unless $args->type eq "press" and $args->button == 1;

      push @points, [ $args->line, $args->col ];
      shift @points while @points > 10;
      $self->redraw;
   }

   1;

This time there is no need to set the window focus, because mouse events do
not need to follow the window that's in focus; they always affect the window
at the location of the mouse cursor.

The C<on_mouse> method then gets invoked whenever a mouse event happens within
the window occupied by the widget. In this particular case, the method filters
only for pressing button 1. It then stores the position of the mouse click in
the C<@points> array, for the C<render> method to use.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
