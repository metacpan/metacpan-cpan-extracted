#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2016 -- leonerd@leonerd.org.uk

package Tickit::Widget::Scroller;

use strict;
use warnings;
use base qw( Tickit::Widget );
use Tickit::Style;
Tickit::Widget->VERSION( '0.35' );
Tickit::Window->VERSION( '0.57' );  # ->bind_event

use Tickit::Window;
use Tickit::Utils qw( textwidth );
use Tickit::RenderBuffer;

our $VERSION = '0.22';

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
   indicator_rv => 1;

use constant WIDGET_PEN_FROM_STYLE => 1;

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

sub new
{
   my $class = shift;
   my %args = @_;

   my $gravity = delete $args{gravity} || "top";

   my $self = $class->SUPER::new( %args );

   # We're going to cache window height because we need pre-resize height
   # during resize event
   $self->{window_lines} = undef;

   $self->{items} = [];

   $self->{start_item} = 0;
   $self->{start_partial} = 0;

   $self->{gravity_bottom} = $gravity eq "bottom";

   $self->set_on_scrolled( $args{on_scrolled} ) if $args{on_scrolled};

   $self->set_gen_top_indicator( $args{gen_top_indicator} );
   $self->set_gen_bottom_indicator( $args{gen_bottom_indicator} );

   return $self;
}

=head1 METHODS

=cut

sub cols  { 1 }
sub lines { 1 }

sub _item
{
   my $self = shift;
   my ( $idx ) = @_;
   return $self->{items}[$idx];
}

sub _itemheight
{
   my $self = shift;
   my ( $idx ) = @_;
   return $self->{itemheights}[$idx] if defined $self->{itemheights}[$idx];
   return $self->{itemheights}[$idx] = $self->_item( $idx )->height_for_width( $self->window->cols );
}

sub reshape
{
   my $self = shift;

   my ( $itemidx, $itemline ) = $self->line2item( $self->{gravity_bottom} ? -1 : 0 );
   $itemline -= $self->_itemheight( $itemidx ) if $self->{gravity_bottom} and defined $itemidx;

   $self->SUPER::reshape;

   $self->{window_lines} = $self->window->lines;

   if( !defined $self->{window_cols} or $self->{window_cols} != $self->window->cols ) {
      $self->{window_cols} = $self->window->cols;

      undef $self->{itemheights};
      $self->resized;
   }

   if( defined $itemidx ) {
      $self->scroll_to( $self->{gravity_bottom} ? -1 : 0, $itemidx, $itemline );
   }
   elsif( $self->{gravity_bottom} ) {
      $self->scroll_to_bottom;
   }
   else {
      $self->scroll_to_top;
   }

   $self->update_indicators;
}

sub window_lost
{
   my $self = shift;
   $self->SUPER::window_lost( @_ );

   my ( $line, $offscreen ) = $self->item2line( -1, -1 );

   $self->{pending_scroll_to_bottom} = 1 if defined $line;

   undef $self->{window_lines};
}

sub window_gained
{
   my $self = shift;
   my ( $win ) = @_;

   $self->{window_lines} = $win->lines;

   $self->SUPER::window_gained( $win );

   if( delete $self->{pending_scroll_to_bottom} ) {
      $self->scroll_to_bottom;
   }
}

=head2 on_scrolled

=head2 set_on_scrolled

   $on_scrolled = $scroller->on_scrolled

   $scroller->set_on_scrolled( $on_scrolled )

Return or set the CODE reference to be called when the scroll position is
adjusted.

   $on_scrolled->( $scroller, $delta )

This is invoked by the C<scroll> method, including the C<scroll_to>,
C<scroll_to_top> and C<scroll_to_bottom>. In normal cases it will be given the
delta offset that C<scroll> itself was invoked with, though this may be
clipped if this would scroll past the beginning or end of the display.

=cut

sub on_scrolled
{
   my $self = shift;
   return $self->{on_scrolled};
}

sub set_on_scrolled
{
   my $self = shift;
   ( $self->{on_scrolled} ) = @_;
}

=head2 push

   $scroller->push( @items )

Append the given items to the end of the list.

If the Scroller is already at the tail (that is, the last line of the last
item is on display) and the gravity mode is C<bottom>, the newly added items
will be displayed, possibly by scrolling downward if required. While the
scroller isn't adjusted by using any of the C<scroll> methods, it will remain
following the tail of the items, scrolling itself downwards as more are added.

=cut

sub push
{
   my $self = shift;

   my $items = $self->{items};

   my $oldsize = @$items;

   push @$items, @_;

   if( my $win = $self->window and $self->window->is_visible ) {
      my $added = 0;
      $added += $self->_itemheight( $_ ) for $oldsize .. $#$items;

      my $lines = $self->{window_lines};

      my $oldlast = $oldsize ? $self->item2line( $oldsize-1, -1 ) : -1;

      # Previous tail is on screen if $oldlast is defined and less than $lines
      # If not, don't bother drawing or scrolling
      return unless defined $oldlast and $oldlast < $lines;

      my $new_start = $oldlast + 1;
      my $new_stop  = $new_start + $added;

      if( $self->{gravity_bottom} ) {
         # If there were enough spare lines, render them, otherwise scroll
         if( $new_stop <= $lines ) {
            $self->render_lines( $new_start, $new_stop );
         }
         else {
            $self->render_lines( $new_start, $lines ) if $new_start < $lines;
            $self->scroll( $new_stop - $lines );
         }
      }
      else {
         # If any new lines of content are now on display, render them
         $new_stop = $lines if $new_stop > $lines;
         if( $new_stop > $new_start ) {
            $self->render_lines( $new_start, $new_stop );
         }
      }
   }

   $self->update_indicators;
}

=head2 unshift

   $scroller->unshift( @items )

Prepend the given items to the beginning of the list.

If the Scroller is already at the head (that is, the first line of the first
item is on display) and the gravity mode is C<top>, the newly added items will
be displayed, possibly by scrolling upward if required. While the scroller
isn't adjusted by using any of the C<scroll> methods, it will remain following
the head of the items, scrolling itself upwards as more are added.

=cut

sub unshift :method
{
   my $self = shift;

   my $items = $self->{items};

   my $oldsize = @$items;

   my $oldfirst = $oldsize ? $self->item2line( 0, 0 ) : 0;
   my $oldlast  = $oldsize ? $self->item2line( -1, -1 ) : -1;

   unshift @$items, @_;
   unshift @{ $self->{itemheights} }, ( undef ) x @_;
   $self->{start_item} += @_;

   if( my $win = $self->window and $self->window->is_visible ) {
      my $added = 0;
      $added += $self->_itemheight( $_ ) for 0 .. $#_;

      # Previous head is on screen if $oldfirst is defined and non-negative
      # If not, don't bother drawing or scrolling
      return unless defined $oldfirst and $oldfirst >= 0;

      my $lines = $self->{window_lines};

      if( $self->{gravity_bottom} ) {
         # If the display wasn't yet full, scroll it down to display any new
         # lines that are visible
         my $first_blank = $oldlast + 1;
         my $scroll_delta = $lines - $first_blank;
         $scroll_delta = $added if $scroll_delta > $added;
         if( $oldsize ) {
            $self->scroll( -$scroll_delta );
         }
         else {
            $self->{start_item} = 0;
            # TODO: if $added > $lines, need special handling
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
            $new_stop = $lines if $new_stop > $lines;
            $self->{start_item} = 0;
            $self->render_lines( 0, $new_stop );
         }
      }
   }

   $self->update_indicators;
}

=head2 shift

   @items = $scroller->shift( $count )

Remove the given number of items from the start of the list and returns them.

If any of the items are on display, the Scroller will be scrolled upwards an
amount sufficient to close the gap, ensuring the first remaining item is now
at the top of the display.

The returned items may be re-used by adding them back into the scroller again
either by C<push> or C<unshift>, or may be discarded.

=cut

sub shift :method
{
   my $self = shift;
   my ( $count ) = @_;

   defined $count or $count = 1;

   my $items = $self->{items};

   croak '$count out of bounds' if $count <= 0;
   croak '$count out of bounds' if $count > @$items;

   my ( $lastline, $offscreen ) = $self->item2line( $count - 1, -1 );

   if( defined $lastline ) {
      $self->scroll( $lastline + 1, allow_gap => 1 );
      # ->scroll implies $win->restore
   }

   my @ret = splice @$items, 0, $count;
   splice @{ $self->{itemheights} }, 0, $count;
   $self->{start_item} -= $count;

   if( !defined $lastline and defined $offscreen and $offscreen eq "below" ) {
      $self->scroll_to_top;
      # ->scroll implies $win->restore
   }

   $self->update_indicators;

   return @ret;
}

=head2 pop

   @items = $scroller->pop( $count )

Remove the given number of items from the end of the list and returns them.

If any of the items are on display, the Scroller will be scrolled downwards an
amount sufficient to close the gap, ensuring the last remaining item is now at
the bottom of the display.

The returned items may be re-used by adding them back into the scroller again
either by C<push> or C<unshift>, or may be discarded.

=cut

sub pop :method
{
   my $self = shift;
   my ( $count ) = @_;

   defined $count or $count = 1;

   my $items = $self->{items};

   croak '$count out of bounds' if $count <= 0;
   croak '$count out of bounds' if $count > @$items;

   my ( $firstline, $offscreen ) = $self->item2line( -$count, 0 );

   if( defined $firstline ) {
      $self->scroll( $firstline - $self->window->lines );
   }

   my @ret = splice @$items, -$count, $count;
   splice @{ $self->{itemheights} }, -$count, $count;

   if( !defined $firstline and defined $offscreen and $offscreen eq "above" ) {
      $self->scroll_to_bottom;
   }

   $self->update_indicators;

   return @ret;
}

=head2 scroll

   $scroller->scroll( $delta )

Move the display up or down by the given C<$delta> amount; with positive
moving down. This will be a physical count of displayed lines; if some items
occupy multiple lines, then fewer items may be scrolled than lines.

=cut

sub scroll
{
   my $self = shift;
   my ( $delta, %opts ) = @_;

   return unless $delta;

   my $window = $self->window;
   my $items = $self->{items};
   @$items or return;

   my $itemidx = $self->{start_item};
   my $partial = $self->{start_partial};
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
         $partial = $itemheight - 1, last if $itemidx == $#$items;

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

   return if $itemidx == $self->{start_item} and
             $partial == $self->{start_partial};

   my $lines = $self->{window_lines};

   if( $scroll_amount > 0 and !$opts{allow_gap} ) {
      # We scrolled down. See if we've gone too far
      my $line = -$partial;
      my $idx = $itemidx;

      while( $line < $lines && $idx < @$items ) {
         $line += $self->_itemheight( $idx );
         $idx++;
      }

      if( $line < $lines ) {
         my $spare = $lines - $line;

         $delta = -$spare;
         goto REDO;
      }
   }

   $self->{start_item}    = $itemidx;
   $self->{start_partial} = $partial;

   if( abs( $scroll_amount ) < $lines ) {
      $window->scroll( $scroll_amount, 0 );
   }
   else {
      $self->redraw;
   }

   if( my $on_scrolled = $self->{on_scrolled} ) {
      $self->$on_scrolled( $scroll_amount );
   }

   $self->update_indicators;
}

=head2 scroll_to

   $scroller->scroll_to( $line, $itemidx, $itemline )

Moves the display up or down so that display line C<$line> contains line
C<$itemline> of item C<$itemidx>. Any of these counts may be negative to count
backwards from the display lines, items, or lines within the item.

=cut

sub scroll_to
{
   my $self = shift;
   my ( $line, $itemidx, $itemline ) = @_;

   my $window = $self->window or return;
   my $lines = $self->{window_lines};

   my $items = $self->{items};
   @$items or return;

   if( $line < 0 ) {
      $line += $lines;

      croak '$line out of bounds' if $line < 0;
   }
   else {
      croak '$line out of bounds' if $line >= $lines;
   }

   if( $itemidx < 0 ) {
      $itemidx += @$items;

      croak '$itemidx out of bounds' if $itemidx < 0;
   }
   else {
      croak '$itemidx out of bounds' if $itemidx >= @$items;
   }

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
   my $i = $self->{start_item};

   $delta -= $self->{start_partial};
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

   $scroller->scroll_to_top( $itemidx, $itemline )

Shortcut for C<scroll_to> to set the top line of display; where C<$line> is 0.
If C<$itemline> is undefined, it will be passed as 0. If C<$itemidx> is also
undefined, it will be passed as 0. Calling this method with no arguments,
therefore scrolls to the very top of the display.

=cut

sub scroll_to_top
{
   my $self = shift;
   my ( $itemidx, $itemline ) = @_;

   defined $itemidx  or $itemidx = 0;
   defined $itemline or $itemline = 0;

   $self->scroll_to( 0, $itemidx, $itemline );
}

=head2 scroll_to_bottom

   $scroller->scroll_to_bottom( $itemidx, $itemline )

Shortcut for C<scroll_to> to set the bottom line of display; where C<$line> is
-1. If C<$itemline> is undefined, it will be passed as -1. If C<$itemidx> is
also undefined, it will be passed as -1. Calling this method with no
arguments, therefore scrolls to the very bottom of the display.

=cut

sub scroll_to_bottom
{
   my $self = shift;
   my ( $itemidx, $itemline ) = @_;

   defined $itemidx  or $itemidx = -1;
   defined $itemline or $itemline = -1;

   $self->scroll_to( -1, $itemidx, $itemline );
}

=head2 line2item

   $itemidx = $scroller->line2item( $line )

   ( $itemidx, $itemline ) = $scroller->line2item( $line )

Returns the item index currently on display at the given line of the window.
In list context, also returns the line number within item. If no window has
been set, or there is no item on display at that line, C<undef> or an empty
list are returned. C<$line> may be negative to count backward from the last
line on display; the last line taking C<-1>.

=cut

sub line2item
{
   my $self = shift;
   my ( $line ) = @_;

   my $window = $self->window or return;
   my $lines = $self->{window_lines};

   my $items = $self->{items};

   if( $line < 0 ) {
      $line += $lines;

      croak '$line out of bounds' if $line < 0;
   }
   else {
      croak '$line out of bounds' if $line >= $lines;
   }

   my $itemidx = $self->{start_item};
   $line += $self->{start_partial};

   while( $itemidx < @$items ) {
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

   $line = $scroller->item2line( $itemidx, $itemline )

   ( $line, $offscreen ) = $scroller->item2line( $itemidx, $itemline, $count_offscreen )

Returns the display line in the window of the given line of the item at the
given index. C<$itemidx> may be given negative, to count backwards from the
last item. C<$itemline> may be negative to count backward from the last line
of the item.

In list context, also returns a value describing the offscreen nature of the
item. For items fully on display, this value is C<undef>. If the given line of
the given item is not on display because it is scrolled off either the top or
bottom of the window, this value will be either C<"above"> or C<"below">
respectively. If C<$count_offscreen> is true, then the returned C<$line> value
will always be defined, even if the item line is offscreen. This will be
negative for items C<"above">, and a value equal or greater than the number of
lines in the scroller's window for items C<"below">.

=cut

sub item2line
{
   my $self = shift;
   my ( $want_itemidx, $want_itemline, $count_offscreen ) = @_;

   my $window = $self->window or return;
   my $lines = $self->{window_lines};

   my $items = $self->{items};
   @$items or return;

   if( $want_itemidx < 0 ) {
      $want_itemidx += @$items;

      croak '$itemidx out of bounds' if $want_itemidx < 0;
   }
   else {
      croak '$itemidx out of bounds' if $want_itemidx >= @$items;
   }

   my $itemheight = $self->_itemheight( $want_itemidx );

   defined $want_itemline or $want_itemline = 0;
   if( $want_itemline < 0 ) {
      $want_itemline += $itemheight;

      croak '$itemline out of bounds' if $want_itemline < 0;
   }
   else {
      croak '$itemline out of bounds' if $want_itemline >= $itemheight;
   }

   my $itemidx = $self->{start_item};

   my $line = -$self->{start_partial};

   if( $want_itemidx < $itemidx or
       $want_itemidx == $itemidx and $want_itemline < $self->{start_partial} ) {
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

   while( $itemidx < @$items and ( $line < $lines or $count_offscreen ) ) {
      if( $want_itemidx == $itemidx ) {
         $line += $want_itemline;

         last if $line >= $lines;
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

   $count = $scroller->lines_above

Returns the number of lines of content above the scrolled display.

=cut

sub lines_above
{
   my $self = shift;
   my ( $line, $offscreen ) = $self->item2line( 0, 0, 1 );
   return 0 unless $offscreen;
   return -$line;
}

=head2 lines_below

   $count = $scroller->lines_below

Returns the number of lines of content below the scrolled display.

=cut

sub lines_below
{
   my $self = shift;
   my ( $line, $offscreen ) = $self->item2line( -1, -1, 1 );
   return 0 unless $offscreen;
   return $line - $self->window->lines + 1;
}

sub render_lines
{
   my $self = shift;
   my ( $startline, $endline ) = @_;

   my $win = $self->window or return;
   $win->expose( Tickit::Rect->new(
      top    => $startline,
      bottom => $endline,
      left   => 0,
      right  => $win->cols,
   ) );
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   my $win = $self->window;
   my $cols = $win->cols;

   my $items = $self->{items};

   my $line = 0;
   my $itemidx = $self->{start_item};

   if( my $partial = $self->{start_partial} ) {
      $line -= $partial;
   }

   my $startline = $rect->top;
   my $endline   = $rect->bottom;

   while( $line < $endline and $itemidx < @$items ) {
      my $item       = $self->_item( $itemidx );
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

my %bindings = (
   Down => sub { $_[0]->scroll( +1 ) },
   Up   => sub { $_[0]->scroll( -1 ) },

   PageDown => sub { $_[0]->scroll( +int( $_[0]->window->lines / 2 ) ) },
   PageUp   => sub { $_[0]->scroll( -int( $_[0]->window->lines / 2 ) ) },

   'C-Home' => sub { $_[0]->scroll_to_top },
   'C-End'  => sub { $_[0]->scroll_to_bottom },
);

sub on_key
{
   my $self = shift;
   my ( $ev ) = @_;

   if( $ev->type eq "key" and my $code = $bindings{$ev->str} ) {
      $code->( $self );
      return 1;
   }

   return 0;
}

sub on_mouse
{
   my $self = shift;
   my ( $ev ) = @_;

   return unless $ev->type eq "wheel";

   $self->scroll(  5 ) if $ev->button eq "down";
   $self->scroll( -5 ) if $ev->button eq "up";
}

=head2 set_gen_top_indicator

=head2 set_gen_bottom_indicator

   $scroller->set_gen_top_indicator( $method )

   $scroller->set_gen_bottom_indicator( $method )

Accessors for the generators for the top and bottom indicator text. If set,
each should be a CODE reference or method name on the scroller which will be
invoked after any operation that changes the contents of the window, such as
scrolling or adding or removing items. It should return a text string which,
if defined and non-empty, will be displayed in an indicator window. This will
be a small one-line window displayed at the top right or bottom right corner
of the Scroller's window.

   $text = $scroller->$method()

The ability to pass method names allows subclasses to easily implement custom
logic as methods without having to capture a closure.

=cut

sub set_gen_top_indicator
{
   my $self = shift;
   ( $self->{gen_top_indicator} ) = @_;

   $self->update_indicators;
}

sub set_gen_bottom_indicator
{
   my $self = shift;
   ( $self->{gen_bottom_indicator} ) = @_;

   $self->update_indicators;
}

=head2 update_indicators

   $scroller->update_indicators

Calls any defined generators for indicator text, and updates the indicator
windows with the returned text. This may be useful if the functions would
return different text now.

=cut

sub update_indicators
{
   my $self = shift;

   my $win = $self->window or return;

   for my $edge (qw( top bottom )) {
      my $text_field = "${edge}_indicator_text";

      my $text = $self->{"gen_${edge}_indicator"} ? $self->${ \$self->{"gen_${edge}_indicator"} }
                                                  : undef;
      $text //= "";
      next if $text eq ( $self->{$text_field} // "" );

      $self->{$text_field} = $text;

      if( !length $text ) {
         $self->{"${edge}_indicator_win"}->hide if $self->{"${edge}_indicator_win"};
         undef $self->{"${edge}_indicator_win"};
         next;
      }

      my $textwidth = textwidth $text;
      my $line = $edge eq "top" ? 0
                                : $win->lines - 1;

      my $floatwin;
      if( $floatwin = $self->{"${edge}_indicator_win"} ) {
         $floatwin->change_geometry( $line, $win->cols - $textwidth, 1, $textwidth );
      }
      elsif( $self->window ) {
         $floatwin = $win->make_float( $line, $win->cols - $textwidth, 1, $textwidth );
         $floatwin->bind_event( expose => sub {
            my ( $win, undef, $info ) = @_;
            $info->rb->text_at( 0, 0,
               $self->{$text_field},
               $self->get_style_pen( "indicator" )
            );
         } );
         $self->{"${edge}_indicator_win"} = $floatwin;
      }

      $floatwin->expose;
   }
}

=head1 TODO

=over 4

=item *

Abstract away the "item storage model" out of the actual widget. Implement
more storage models, such as database-driven ones.. more dynamic.

=item *

Keybindings

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
