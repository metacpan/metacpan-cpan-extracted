#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2024 -- leonerd@leonerd.org.uk

use v5.26; # signatures
use warnings;
use Object::Pad 0.800 ':experimental(adjust_params)';

package Tickit::Widget::Scroller 0.33;
class Tickit::Widget::Scroller
   :strict(params)
   :isa(Tickit::Widget);

use Tickit::Style;
Tickit::Widget->VERSION( '0.35' );
Tickit::Window->VERSION( '0.57' );  # ->bind_event

use Tickit::Window;
use Tickit::Utils qw( textwidth );

use Carp;

=head1 NAME

C<Tickit::Widget::Scroller> - a widget displaying a scrollable collection of
items

=head1 SYNOPSIS

   use Tickit;
   use Tickit::Widget::Scroller;
   use Tickit::Widget::Scroller::Item::Text;

   my $tickit = Tickit->new;

   my $scroller = Tickit::Widget::Scroller->new;

   $scroller->push(
      Tickit::Widget::Scroller::Item::Text->new( "Hello world" ),
      Tickit::Widget::Scroller::Item::Text->new( "Here are some lines" ),
      map { Tickit::Widget::Scroller::Item::Text->new( "<Line $_>" ) } 1 .. 50,
   );

   $tickit->set_root_widget( $scroller );

   $tickit->run

=head1 DESCRIPTION

This class provides a widget which displays a scrollable list of items. The
view of the items is scrollable, able to display only a part of the list.

A Scroller widget stores a list of instances implementing the
C<Tickit::Widget::Scroller::Item> interface.

=head1 STYLE

The default style pen is used as the widget pen.

The following style pen prefixes are used:

=over 4

=item indicator => PEN

The pen used for the scroll position indicators at the top or bottom of the
display

=back

=cut

style_definition base =>
   indicator_rv => 1,
   "<Down>"     => "scroll_down_line",
   "<Up>"       => "scroll_up_line",
   "<PageDown>" => "scroll_down_halfpage",
   "<PageUp>"   => "scroll_up_halfpage",
   "<C-Home>"   => "scroll_to_top",
   "<C-End>"    => "scroll_to_bottom",
   ;

use constant WIDGET_PEN_FROM_STYLE => 1;
use constant KEYPRESSES_FROM_STYLE => 1;

=head1 KEYBINDINGS

The following keys are bound

=over 2

=item * Down

Scroll one line down

=item * Up

Scroll one line up

=item * PageDown

Scroll half a window down

=item * PageUp

Scroll half a window up

=item * Ctrl-Home

Scroll to the top

=item * Ctrl-End

Scroll to the bottom

=back

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $scroller = Tickit::Widget::Scroller->new( %args )

Constructs a new C<Tickit::Widget::Scroller> object. The new object will start
with an empty list of items.

Takes the following named arguments:

=over 8

=item gravity => STRING

Optional. If given the value C<bottom>, resize events and the C<push> method
will attempt to preserve the item at the bottom of the screen. Otherwise, will
preserve the top.

=item gen_top_indicator => CODE

=item gen_bottom_indicator => CODE

Optional. Generator functions for the top and bottom indicators. See also
C<set_gen_top_indicator> and C<set_gen_bottom_indicator>.

=back

=cut

field @_items;
field @_itemheights;

field $_start_item = 0;
field $_start_partial = 0;

# We're going to cache window height because we need pre-resize height
# during resize event
field $_window_lines;
field $_window_cols;

field $_gravity_bottom;

field $_pending_scroll_to_bottom;

field $_on_scrolled :param :reader :writer = undef;

field $_gen_top_indicator    :param = undef;
field $_gen_bottom_indicator :param = undef;

ADJUST :params (
   :$gravity = "top",
) {
   $_gravity_bottom = ( $gravity eq "bottom" );
}

=head1 METHODS

=cut

method cols  () { 1 }
method lines () { 1 }

method _itemidx_for ( $item_or_idx )
{
   if( ref $item_or_idx ) {
      my $idx;
      $_items[$_] == $item_or_idx and ( $idx = $_ ), last for 0 .. $#_items;
      croak '$item_or_idx is not an item in the Scroller' if !defined $idx;
      return $idx;
   }

   if( $item_or_idx < 0 ) {
      $item_or_idx += @_items;

      croak '$item_or_idx out of bounds' if $item_or_idx < 0;
   }
   else {
      croak '$item_or_idx out of bounds' if $item_or_idx >= @_items;
   }

   return $item_or_idx;
}

method _itemheight ( $idx )
{
   return $_itemheights[$idx] if defined $_itemheights[$idx];
   return $_itemheights[$idx] = $_items[$idx]->height_for_width( $self->window->cols );
}

method reshape ()
{
   my ( $itemidx, $itemline ) = $self->line2item( $_gravity_bottom ? -1 : 0 );
   $itemline -= $self->_itemheight( $itemidx ) if $_gravity_bottom and defined $itemidx;

   $self->SUPER::reshape;

   $_window_lines = $self->window->lines;

   if( !defined $_window_cols or $_window_cols != $self->window->cols ) {
      $_window_cols = $self->window->cols;

      undef @_itemheights;
      $self->resized;
   }

   if( defined $itemidx ) {
      $self->scroll_to( $_gravity_bottom ? -1 : 0, $itemidx, $itemline );
   }
   elsif( $_gravity_bottom ) {
      $self->scroll_to_bottom;
   }
   else {
      $self->scroll_to_top;
   }

   $self->update_indicators( 1 );
}

method window_lost
{
   $self->SUPER::window_lost( @_ );

   my ( $line, $offscreen ) = $self->item2line( -1, -1 );

   $_pending_scroll_to_bottom = 1 if defined $line;

   undef $_window_lines;
}

method window_gained ( $win )
{
   $_window_lines = $win->lines;

   $self->SUPER::window_gained( $win );

   if( $_pending_scroll_to_bottom ) {
      $self->scroll_to_bottom;
      undef $_pending_scroll_to_bottom;
   }
}

=head2 on_scrolled

=head2 set_on_scrolled

   $on_scrolled = $scroller->on_scrolled;

   $scroller->set_on_scrolled( $on_scrolled );

Return or set the CODE reference to be called when the scroll position is
adjusted.

   $on_scrolled->( $scroller, $delta );

This is invoked by the C<scroll> method, including the C<scroll_to>,
C<scroll_to_top> and C<scroll_to_bottom>. In normal cases it will be given the
delta offset that C<scroll> itself was invoked with, though this may be
clipped if this would scroll past the beginning or end of the display.

=cut

# generated accessors

=head2 items

   $count = $scroller->items;

I<Since version 0.31.>

In scalar context, returns the number of items currently stored in the
Scroller. The behaviour of this method in non-scalar context is currently
unspecified.

=cut

method items { return scalar @_items; }

=head2 push

   $scroller->push( @items );

Append the given items to the end of the list.

If the Scroller is already at the tail (that is, the last line of the last
item is on display) and the gravity mode is C<bottom>, the newly added items
will be displayed, possibly by scrolling downward if required. While the
scroller isn't adjusted by using any of the C<scroll> methods, it will remain
following the tail of the items, scrolling itself downwards as more are added.

=cut

method push ( @more )
{
   my $oldsize = @_items;

   push @_items, @more;

   if( my $win = $self->window and $self->window->is_visible ) {
      my $added = 0;
      $added += $self->_itemheight( $_ ) for $oldsize .. $#_items;

      my $oldlast = $oldsize ? $self->item2line( $oldsize-1, -1 ) : -1;

      # Previous tail is on screen if $oldlast is defined and less than $_window_lines
      # If not, don't bother drawing or scrolling
      return unless defined $oldlast and $oldlast < $_window_lines;

      my $new_start = $oldlast + 1;
      my $new_stop  = $new_start + $added;

      if( $_gravity_bottom ) {
         # If there were enough spare lines, render them, otherwise scroll
         if( $new_stop <= $_window_lines ) {
            $self->render_lines( $new_start, $new_stop );
         }
         else {
            $self->render_lines( $new_start, $_window_lines ) if $new_start < $_window_lines;
            $self->scroll( $new_stop - $_window_lines );
         }
      }
      else {
         # If any new lines of content are now on display, render them
         $new_stop = $_window_lines if $new_stop > $_window_lines;
         if( $new_stop > $new_start ) {
            $self->render_lines( $new_start, $new_stop );
         }
      }
   }

   $self->update_indicators;
}

=head2 unshift

   $scroller->unshift( @items );

Prepend the given items to the beginning of the list.

If the Scroller is already at the head (that is, the first line of the first
item is on display) and the gravity mode is C<top>, the newly added items will
be displayed, possibly by scrolling upward if required. While the scroller
isn't adjusted by using any of the C<scroll> methods, it will remain following
the head of the items, scrolling itself upwards as more are added.

=cut

method unshift ( @more )
{
   my $oldsize = @_items;

   my $oldfirst = $oldsize ? $self->item2line( 0, 0 ) : 0;
   my $oldlast  = $oldsize ? $self->item2line( -1, -1 ) : -1;

   unshift @_items, @more;
   unshift @_itemheights, ( undef ) x @more;
   $_start_item += @more;

   if( my $win = $self->window and $self->window->is_visible ) {
      my $added = 0;
      $added += $self->_itemheight( $_ ) for 0 .. $#more;

      # Previous head is on screen if $oldfirst is defined and non-negative
      # If not, don't bother drawing or scrolling
      return unless defined $oldfirst and $oldfirst >= 0;

      if( $_gravity_bottom ) {
         # If the display wasn't yet full, scroll it down to display any new
         # lines that are visible
         my $first_blank = $oldlast + 1;
         my $scroll_delta = $_window_lines - $first_blank;
         $scroll_delta = $added if $scroll_delta > $added;
         if( $oldsize ) {
            $self->scroll( -$scroll_delta );
         }
         else {
            $_start_item = 0;
            # TODO: if $added > $_window_lines, need special handling
            $self->render_lines( 0, $added );
         }
      }
      else {
         # Scroll down by the amount added
         if( $oldsize ) {
            $self->scroll( -$added );
         }
         else {
            my $new_stop = $added;
            $new_stop = $_window_lines if $new_stop > $_window_lines;
            $_start_item = 0;
            $self->render_lines( 0, $new_stop );
         }
      }
   }

   $self->update_indicators;
}

=head2 shift

   @items = $scroller->shift( $count );

Remove the given number of items from the start of the list and returns them.

If any of the items are on display, the Scroller will be scrolled upwards an
amount sufficient to close the gap, ensuring the first remaining item is now
at the top of the display.

The returned items may be re-used by adding them back into the scroller again
either by C<push> or C<unshift>, or may be discarded.

=cut

method shift ( $count = 1 )
{
   croak '$count out of bounds' if $count <= 0;
   croak '$count out of bounds' if $count > @_items;

   my ( $lastline, $offscreen ) = $self->item2line( $count - 1, -1 );

   if( defined $lastline ) {
      $self->scroll( $lastline + 1, allow_gap => 1 );
      # ->scroll implies $win->restore
   }

   my @ret = splice @_items, 0, $count;
   splice @_itemheights, 0, $count;
   $_start_item -= $count;

   if( !defined $lastline and defined $offscreen and $offscreen eq "below" ) {
      $self->scroll_to_top;
      # ->scroll implies $win->restore
   }

   $self->update_indicators;

   return @ret;
}

=head2 pop

   @items = $scroller->pop( $count );

Remove the given number of items from the end of the list and returns them.

If any of the items are on display, the Scroller will be scrolled downwards an
amount sufficient to close the gap, ensuring the last remaining item is now at
the bottom of the display.

The returned items may be re-used by adding them back into the scroller again
either by C<push> or C<unshift>, or may be discarded.

=cut

method pop ( $count = 1 )
{
   croak '$count out of bounds' if $count <= 0;
   croak '$count out of bounds' if $count > @_items;

   my ( $firstline, $offscreen ) = $self->item2line( -$count, 0 );

   if( defined $firstline ) {
      $self->scroll( $firstline - $self->window->lines );
   }

   my @ret = splice @_items, -$count, $count;
   splice @_itemheights, -$count, $count;

   if( !defined $firstline and defined $offscreen and $offscreen eq "above" ) {
      $self->scroll_to_bottom;
   }

   $self->update_indicators;

   return @ret;
}

=head2 scroll

   $scroller->scroll( $delta );

Move the display up or down by the given C<$delta> amount; with positive
moving down. This will be a physical count of displayed lines; if some items
occupy multiple lines, then fewer items may be scrolled than lines.

=cut

method scroll ( $delta, %opts )
{
   return unless $delta;

   my $window = $self->window;
   @_items or return;

   my $itemidx = $_start_item;
   my $partial = $_start_partial;
   my $scroll_amount = 0;

REDO:
   if( $partial > 0 ) {
      $delta += $partial;
      $scroll_amount -= $partial;
      $partial = 0;
   }

   while( $delta ) {
      my $itemheight = $self->_itemheight( $itemidx );

      if( $delta >= $itemheight ) {
         $partial = $itemheight - 1, last if $itemidx == $#_items;

         $delta -= $itemheight;
         $scroll_amount += $itemheight;

         $itemidx++;
      }
      elsif( $delta < 0 ) {
         $partial = 0, last if $itemidx == 0;
         $itemidx--;

         $itemheight = $self->_itemheight( $itemidx );

         $delta += $itemheight;
         $scroll_amount -= $itemheight;
      }
      else {
         $partial = $delta;
         $scroll_amount += $delta;

         $delta = 0;
      }
   }

   return if $itemidx == $_start_item and
             $partial == $_start_partial;

   if( $scroll_amount > 0 and !$opts{allow_gap} ) {
      # We scrolled down. See if we've gone too far
      my $line = -$partial;
      my $idx = $itemidx;

      while( $line < $_window_lines && $idx < @_items ) {
         $line += $self->_itemheight( $idx );
         $idx++;
      }

      if( $line < $_window_lines ) {
         my $spare = $_window_lines - $line;

         $delta = -$spare;
         goto REDO;
      }
   }

   $_start_item    = $itemidx;
   $_start_partial = $partial;

   if( abs( $scroll_amount ) < $_window_lines ) {
      $window->scroll( $scroll_amount, 0 );
   }
   else {
      $self->redraw;
   }

   if( $_on_scrolled ) {
      $self->$_on_scrolled( $scroll_amount );
   }

   $self->update_indicators;
}

=head2 scroll_to

   $scroller->scroll_to( $line, $item_or_idx, $itemline );

Moves the display up or down so that display line C<$line> contains line
C<$itemline> of the item; which may be given by object reference or index
number. Any of these counts may be negative to count backwards from the
display lines, items, or lines within the item.

=cut

method scroll_to ( $line, $item_or_idx, $itemline )
{
   my $window = $self->window or return;

   @_items or return;

   if( $line < 0 ) {
      $line += $_window_lines;

      croak '$line out of bounds' if $line < 0;
   }
   else {
      croak '$line out of bounds' if $line >= $_window_lines;
   }

   my $itemidx = $self->_itemidx_for( $item_or_idx );

   my $itemheight = $self->_itemheight( $itemidx );

   if( $itemline < 0 ) {
      $itemline += $itemheight;

      croak '$itemline out of bounds' if $itemline < 0;
   }
   else {
      croak '$itemline out of bounds' if $itemline >= $itemheight;
   }

   $line -= $itemline; # now ignore itemline

   while( $line > 0 ) {
      if( $itemidx == 0 ) {
         $line = 0;
         last;
      }

      $itemheight = $self->_itemheight( --$itemidx );

      $line -= $itemheight;
   }
   $itemline = -$line; # $line = 0;

   # Now we want $itemidx line $itemline to be on physical line 0

   # Work out how far away that is
   my $delta = 0;
   my $i = $_start_item;

   $delta -= $_start_partial;
   while( $itemidx > $i ) {
      $delta += $self->_itemheight( $i );
      $i++;
   }
   while( $itemidx < $i ) {
      $i--;
      $delta -= $self->_itemheight( $i );
   }
   $delta += $itemline;

   return if !$delta;

   $self->scroll( $delta );
}

=head2 scroll_to_top

   $scroller->scroll_to_top( $item_or_idx, $itemline );

Shortcut for C<scroll_to> to set the top line of display; where C<$line> is 0.
If C<$itemline> is undefined, it will be passed as 0. If C<$item_or_idx> is
also undefined, it will be passed as 0. Calling this method with no arguments,
therefore scrolls to the very top of the display.

=cut

method scroll_to_top ( $item_or_idx = 0, $itemline = 0 )
{
   $self->scroll_to( 0, $item_or_idx, $itemline );
}

=head2 scroll_to_bottom

   $scroller->scroll_to_bottom( $item_or_idx, $itemline );

Shortcut for C<scroll_to> to set the bottom line of display; where C<$line> is
-1. If C<$itemline> is undefined, it will be passed as -1. If C<$item_or_idx>
is also undefined, it will be passed as -1. Calling this method with no
arguments, therefore scrolls to the very bottom of the display.

=cut

method scroll_to_bottom ( $item_or_idx = -1, $itemline = -1 )
{
   $self->scroll_to( -1, $item_or_idx, $itemline );
}

=head2 scroll_to_visible

   $scroller->scroll_to_visible( $item_or_idx, $itemline, %opts );

I<Since version 0.33.>

If the requested line of the requested item is already visible on the display,
this method does nothing. Otherwise, it scrolls up or down by the B<smallest>
amount possible so that it becomes visible. If the line was previously above
then it scrolls just sufficient to bring that line to the top-most of the
display. If it was below, it scrolls to bring it to the bottom-most.

If the optional C<margin> named argument it set to a value larger than zero,
it causes that number of the top-most and bottom-most lines not to count for
purposes of visibility or scrolling.

=cut

method scroll_to_visible ( $item_or_idx, $itemline = 0, %opts )
{
   my $height = $self->window->lines;
   my $max_margin = int( ( $height - 1 ) / 2 );

   my $margin = $opts{margin} // 0;
   $margin = $max_margin if $margin > $max_margin;

   my ( $visline, $offscreen ) = $self->item2line( $item_or_idx, $itemline );
   $offscreen //= ""; # quiet warnings from eq

   if( $offscreen eq "above" or $offscreen eq "" and $visline < $margin ) {
      # Scroll so requested line is at the top
      $self->scroll_to( $margin, $item_or_idx, $itemline );
   }
   elsif( $offscreen eq "below" or $offscreen eq "" and $visline >= $height - $margin ) {
      # Scroll so requested line is at the bottom
      $self->scroll_to( -1 - $margin, $item_or_idx, $itemline );
   }
   # else was already visible, so nothing to do
}

=head2 line2item

   $itemidx = $scroller->line2item( $line );

   ( $itemidx, $itemline ) = $scroller->line2item( $line );

Returns the item index currently on display at the given line of the window.
In list context, also returns the line number within item. If no window has
been set, or there is no item on display at that line, C<undef> or an empty
list are returned. C<$line> may be negative to count backward from the last
line on display; the last line taking C<-1>.

=cut

method line2item ( $line )
{
   my $window = $self->window or return;

   if( $line < 0 ) {
      $line += $_window_lines;

      croak '$line out of bounds' if $line < 0;
   }
   else {
      croak '$line out of bounds' if $line >= $_window_lines;
   }

   my $itemidx = $_start_item;
   $line += $_start_partial;

   while( $itemidx < @_items ) {
      my $itemheight = $self->_itemheight( $itemidx );
      if( $line < $itemheight ) {
         return $itemidx, $line if wantarray;
         return $itemidx;
      }

      $line -= $itemheight;
      $itemidx++;
   }

   return;
}

=head2 item2line

   $line = $scroller->item2line( $item_or_idx, $itemline );

   ( $line, $offscreen ) = $scroller->item2line( $item_or_idx, $itemline, $count_offscreen );

Returns the display line in the window of the given line of the item at the
given index. C<$item_or_idx> may be an item directly, a non-negative integer
to give its index, or a negative to count backwards from the last item.
C<$itemline> may be negative to count backward from the last line of the item.

In list context, also returns a value describing the offscreen nature of the
item. For items fully on display, this value is C<undef>. If the given line of
the given item is not on display because it is scrolled off either the top or
bottom of the window, this value will be either C<"above"> or C<"below">
respectively. If C<$count_offscreen> is true, then the returned C<$line> value
will always be defined, even if the item line is offscreen. This will be
negative for items C<"above">, and a value equal or greater than the number of
lines in the scroller's window for items C<"below">.

=cut

method item2line ( $want_item_or_idx, $want_itemline = 0, $count_offscreen = 0 )
{
   my $window = $self->window or return;

   @_items or return;

   my $want_itemidx = $self->_itemidx_for( $want_item_or_idx );

   my $itemheight = $self->_itemheight( $want_itemidx );

   defined $want_itemline or $want_itemline = 0;
   if( $want_itemline < 0 ) {
      $want_itemline += $itemheight;

      croak '$itemline out of bounds' if $want_itemline < 0;
   }
   else {
      croak '$itemline out of bounds' if $want_itemline >= $itemheight;
   }

   my $itemidx = $_start_item;

   my $line = -$_start_partial;

   if( $want_itemidx < $itemidx or
       $want_itemidx == $itemidx and $want_itemline < $_start_partial ) {
      if( wantarray and $count_offscreen ) {
         while( $itemidx >= 0 ) {
            if( $want_itemidx == $itemidx ) {
               $line += $want_itemline;
               last;
            }

            $itemidx--;
            $line -= $self->_itemheight( $itemidx );
         }
         return ( $line, "above" );
      }
      return ( undef, "above" ) if wantarray;
      return;
   }

   while( $itemidx < @_items and ( $line < $_window_lines or $count_offscreen ) ) {
      if( $want_itemidx == $itemidx ) {
         $line += $want_itemline;

         last if $line >= $_window_lines;
         return $line;
      }

      $line += $self->_itemheight( $itemidx );
      $itemidx++;
   }

   return ( undef, "below" ) if wantarray and !$count_offscreen;
   return ( $line, "below" ) if wantarray and $count_offscreen;
   return;
}

=head2 lines_above

   $count = $scroller->lines_above;

Returns the number of lines of content above the scrolled display.

=cut

method lines_above ()
{
   my ( $line, $offscreen ) = $self->item2line( 0, 0, 1 );
   return 0 unless $offscreen;
   return -$line;
}

=head2 lines_below

   $count = $scroller->lines_below;

Returns the number of lines of content below the scrolled display.

=cut

method lines_below ()
{
   my ( $line, $offscreen ) = $self->item2line( -1, -1, 1 );
   return 0 unless $offscreen;
   return $line - $self->window->lines + 1;
}

method render_lines ( $startline, $endline )
{
   my $win = $self->window or return;
   $win->expose( Tickit::Rect->new(
      top    => $startline,
      bottom => $endline,
      left   => 0,
      right  => $win->cols,
   ) );
}

method render_to_rb ( $rb, $rect )
{
   my $win = $self->window;
   my $cols = $win->cols;

   my $line = 0;
   my $itemidx = $_start_item;

   if( my $partial = $_start_partial ) {
      $line -= $partial;
   }

   my $startline = $rect->top;
   my $endline   = $rect->bottom;

   while( $line < $endline and $itemidx < @_items ) {
      my $item       = $_items[$itemidx];
      my $itemheight = $self->_itemheight( $itemidx );

      my $top = $line;
      my $firstline = ( $startline > $line ) ? $startline - $top : 0;

      $itemidx++;
      $line += $itemheight;

      next if $firstline >= $itemheight;

      $rb->save;
      {
         my $lastline = ( $endline < $line ) ? $endline - $top : $itemheight;

         $rb->translate( $top, 0 );
         $rb->clip( Tickit::Rect->new(
            top    => $firstline,
            bottom => $lastline,
            left   => 0,
            cols   => $cols,
         ) );

         $item->render( $rb,
            top       => 0,
            firstline => $firstline,
            lastline  => $lastline - 1,
            width     => $cols,
            height    => $itemheight,
         );

      }
      $rb->restore;
   }

   while( $line < $endline ) {
      $rb->goto( $line, 0 );
      $rb->erase( $cols );
      $line++;
   }
}

method key_scroll_to_top    { $self->scroll_to_top }
method key_scroll_to_bottom { $self->scroll_to_bottom }

method key_scroll_up_line   { $self->scroll( -1 ) }
method key_scroll_down_line { $self->scroll( +1 ) }

method key_scroll_up_halfpage   { $self->scroll( -int( $self->window->lines / 2 ) ) }
method key_scroll_down_halfpage { $self->scroll( +int( $self->window->lines / 2 ) ) }

method key_scroll_up_page   { $self->scroll( $self->window->lines ) }
method key_scroll_down_page { $self->scroll( $self->window->lines ) }

method on_mouse ( $ev )
{
   return unless $ev->type eq "wheel";

   $self->scroll(  5 ) if $ev->button eq "down";
   $self->scroll( -5 ) if $ev->button eq "up";
}

=head2 set_gen_top_indicator

=head2 set_gen_bottom_indicator

   $scroller->set_gen_top_indicator( $method );

   $scroller->set_gen_bottom_indicator( $method );

Accessors for the generators for the top and bottom indicator text. If set,
each should be a CODE reference or method name on the scroller which will be
invoked after any operation that changes the contents of the window, such as
scrolling or adding or removing items. It should return a text string which,
if defined and non-empty, will be displayed in an indicator window. This will
be a small one-line window displayed at the top right or bottom right corner
of the Scroller's window.

   $text = $scroller->$method();

The ability to pass method names allows subclasses to easily implement custom
logic as methods without having to capture a closure.

=cut

method set_gen_top_indicator
{
   ( $_gen_top_indicator ) = @_;

   $self->update_indicators;
}

method set_gen_bottom_indicator
{
   ( $_gen_bottom_indicator ) = @_;

   $self->update_indicators;
}

=head2 update_indicators

   $scroller->update_indicators;

Calls any defined generators for indicator text, and updates the indicator
windows with the returned text. This may be useful if the functions would
return different text now.

=cut

field %_indicator_win;
field %_indicator_text;

method update_indicators ( $force = 0 )
{
   my $win = $self->window or return;

   for my $edge (qw( top bottom )) {
      my $gen_indicator = ( $edge eq "top" ) ? $_gen_top_indicator
                                             : $_gen_bottom_indicator;

      my $text = $gen_indicator ? $self->$gen_indicator
                                : undef;
      $text //= "";
      next if !$force and $text eq ( $_indicator_text{$edge} // "" );

      $_indicator_text{$edge} = $text;

      if( !length $text ) {
         $_indicator_win{$edge}->hide if $_indicator_win{$edge};
         undef $_indicator_win{$edge};
         next;
      }

      my $textwidth = textwidth $text;
      my $line = $edge eq "top" ? 0
                                : $win->lines - 1;

      my $floatwin;
      if( $floatwin = $_indicator_win{$edge} ) {
         $floatwin->change_geometry( $line, $win->cols - $textwidth, 1, $textwidth );
      }
      elsif( $self->window ) {
         $floatwin = $win->make_float( $line, $win->cols - $textwidth, 1, $textwidth );
         $floatwin->bind_event( expose => sub {
            my ( $win, undef, $info ) = @_;
            $info->rb->text_at( 0, 0,
               $_indicator_text{$edge},
               $self->get_style_pen( "indicator" )
            );
         } );
         $_indicator_win{$edge} = $floatwin;
      }

      $floatwin->expose;
   }
}

=head1 TODO

=over 4

=item *

Abstract away the "item storage model" out of the actual widget. Implement
more storage models, such as database-driven ones.. more dynamic.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
