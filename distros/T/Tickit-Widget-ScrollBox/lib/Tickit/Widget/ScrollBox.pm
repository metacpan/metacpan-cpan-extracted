#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2021 -- leonerd@leonerd.org.uk

use v5.26; # signatures
use Object::Pad 0.57;

package Tickit::Widget::ScrollBox 0.11;
class Tickit::Widget::ScrollBox
   :isa(Tickit::SingleChildWidget 0.53);

Tickit::Window->VERSION( '0.39' ); # ->scroll_with_children, default expose_after_scroll
use Tickit::Style;

use Carp;

use List::Util qw( max );

use Tickit::Widget::ScrollBox::Extent;
use Tickit::RenderBuffer qw( LINE_DOUBLE CAP_BOTH );

=head1 NAME

C<Tickit::Widget::ScrollBox> - allow a single child widget to be scrolled

=head1 SYNOPSIS

   use Tickit;
   use Tickit::Widget::ScrollBox;
   use Tickit::Widget::Static;

   my $scrollbox = Tickit::Widget::ScrollBox->new
      ->set_child( Tickit::Widget::Static->new(
         text => join( "\n", map { "The content for line $_" } 1 .. 100 ),
      ) );

   Tickit->new( root => $scrollbox )->run;

=head1 DESCRIPTION

This container widget draws a scrollbar beside a single child widget and
allows a portion of it to be displayed by scrolling.

=head1 STYLE

Th following style pen prefixes are used:

=over 4

=item scrollbar => PEN

The pen used to render the background of the scroll bar

=item scrollmark => PEN

The pen used to render the active scroll position in the scroll bar

=item arrow => PEN

The pen used to render the scrolling arrow buttons

=back

The following style keys are used:

=over 4

=item arrow_up => STRING

=item arrow_down => STRING

=item arrow_left => STRING

=item arrow_right => STRING

Each should be a single character to use for the scroll arrow buttons.

=back

The following style actions are used:

=over 4

=item up_1 (<Up>)

=item down_1 (<Down>)

=item left_1 (<Left>)

=item right_1 (<Right>)

Scroll by 1 line

=item up_half (<PageUp>)

=item down_half (<PageDown>)

=item left_half (<C-Left>)

=item right_half (<C-Right>)

Scroll by half of the viewport

=item to_top (<C-Home>)

=item to_bottom (<C-End>)

=item to_leftmost (<Home>)

=item to_rightmost (<End>)

Scroll to the edge of the area

=back

=cut

style_definition base =>
   scrollbar_fg  => "blue",
   scrollmark_bg => "blue",
   arrow_rv      => 1,
   arrow_up      => chr 0x25B4, # U+25B4 == Black up-pointing small triangle
   arrow_down    => chr 0x25BE, # U+25BE == Black down-pointing small triangle
   arrow_left    => chr 0x25C2, # U+25C2 == Black left-pointing small triangle
   arrow_right   => chr 0x25B8, # U+25B8 == Black right-pointing small triangle
   '<Up>'        => "up_1",
   '<Down>'      => "down_1",
   '<Left>'      => "left_1",
   '<Right>'     => "right_1",
   '<PageUp>'    => "up_half",
   '<PageDown>'  => "down_half",
   '<C-Left>'    => "left_half",
   '<C-Right>'   => "right_half",
   '<C-Home>'    => "to_top",
   '<C-End>'     => "to_bottom",
   '<Home>'      => "to_leftmost",
   '<End>'       => "to_rightmost",
   ;

use constant WIDGET_PEN_FROM_STYLE => 1;
use constant KEYPRESSES_FROM_STYLE => 1;

=head1 CONSTRUCTOR

=cut

=head2 new

   $scrollbox = Tickit::Widget::ScrollBox->new( %args )

Constructs a new C<Tickit::Widget::ScrollBox> object.

Takes the following named arguments in addition to those taken by the base
L<Tickit::SingleChildWidget> constructor:

=over 8

=item vertical => BOOL or "on_demand"

=item horizontal => BOOL or "on_demand"

Whether to apply a scrollbar in the vertical or horizontal directions. If not
given, these default to vertical only.

If given as the string C<on_demand> then the scrollbar will be optionally be
displayed only if needed; if the space given to the widget is smaller than the
child content necessary to display.

=back

=cut

has $_vextent;
has $_hextent;

has $_v_on_demand;
has $_h_on_demand;

has $_child_is_scrollable;

has $_viewport;

ADJUSTPARAMS ( $params )
{
   my $vertical   = ( delete $params->{vertical} ) // 1;
   my $horizontal = ( delete $params->{horizontal} );

   $vertical and
      $_vextent = Tickit::Widget::ScrollBox::Extent->new(
         scrollbox => $self,
         id        => "v",
      );

   $horizontal and
      $_hextent = Tickit::Widget::ScrollBox::Extent->new(
         scrollbox => $self,
         id        => "h",
      );

   $_v_on_demand = $vertical  ||'' eq "on_demand";
   $_h_on_demand = $horizontal||'' eq "on_demand";
}

=head1 ACCESSORS

=cut

method lines ()
{
   return $self->child->lines + ( $_hextent ? 1 : 0 );
}

method cols ()
{
   return $self->child->cols + ( $_vextent ? 1 : 0 );
}

=head2 vextent

   $vextent = $scrollbox->vextent

Returns the L<Tickit::Widget::ScrollBox::Extent> object representing the box's
vertical scrolling extent.

=cut

method vextent ()
{
   return $_vextent;
}

method _v_visible ()
{
   return 0 unless $_vextent;
   return 1 unless $_v_on_demand;
   return $_vextent->limit > 0;
}

=head2 hextent

   $hextent = $scrollbox->hextent

Returns the L<Tickit::Widget::ScrollBox::Extent> object representing the box's
horizontal scrolling extent.

=cut

method hextent ()
{
   return $_hextent;
}

method _h_visible ()
{
   return 0 unless $_hextent;
   return 1 unless $_h_on_demand;
   return $_hextent->limit > 0;
}

=head1 METHODS

=cut

method children_changed ()
{
   if( my $child = $self->child ) {
      my $scrollable = $_child_is_scrollable = $child->can( "CAN_SCROLL" ) && $child->CAN_SCROLL;

      if( $scrollable ) {
         foreach my $method (qw( set_scrolling_extents scrolled )) {
            $child->can( $method ) or croak "ScrollBox child cannot ->$method - do you implement it?";
         }

         $child->set_scrolling_extents( $_vextent, $_hextent );
         defined $_vextent->real_total or croak "ScrollBox child did not set vextent->total" if $_vextent;
         defined $_hextent->real_total or croak "ScrollBox child did not set hextent->total" if $_hextent;
      }
   }
   $self->SUPER::children_changed;
}

method reshape ()
{
   my $window = $self->window or return;
   my $child  = $self->child or return;

   if( !$_child_is_scrollable ) {
      $_vextent->set_total( $child->lines ) if $_vextent;
      $_hextent->set_total( $child->cols  ) if $_hextent;
   }

   my $v_spare = ( $_vextent ? $_vextent->real_total : $window->lines-1 ) - $window->lines;
   my $h_spare = ( $_hextent ? $_hextent->real_total : $window->cols-1  ) - $window->cols;

   # visibility of each bar might depend on the visibility of the other, if it
   # it was exactly at limit
   $v_spare++ if $v_spare == 0 and $h_spare > 0;
   $h_spare++ if $h_spare == 0 and $v_spare > 0;

   my $v_visible = $_vextent && ( !$_v_on_demand || $v_spare > 0 );
   my $h_visible = $_hextent && ( !$_h_on_demand || $h_spare > 0 );

   my @viewportgeom = ( 0, 0,
      $window->lines - ( $h_visible ? 1 : 0 ),
      $window->cols  - ( $v_visible ? 1 : 0 ) );

   if( $_viewport ) {
      $_viewport->change_geometry( @viewportgeom );
   }
   else {
      $_viewport = $window->make_sub( @viewportgeom );
   }

   $_vextent->set_viewport( $_viewport->lines ) if $_vextent;
   $_hextent->set_viewport( $_viewport->cols  ) if $_hextent;

   if( $_child_is_scrollable ) {
      $child->set_window( $_viewport ) unless $child->window;
   }
   else {
      my ( $childtop, $childlines ) =
         $_vextent ? ( -$_vextent->start, $_vextent->total )
                   : ( 0, max( $child->lines, $_viewport->lines ) );

      my ( $childleft, $childcols ) =
         $_hextent ? ( -$_hextent->start, $_hextent->total )
                   : ( 0, max( $child->cols, $_viewport->cols ) );

      my @childgeom = ( $childtop, $childleft, $childlines, $childcols );

      if( my $childwin = $child->window ) {
         $childwin->change_geometry( @childgeom );
      }
      else {
         $childwin = $_viewport->make_sub( @childgeom );
         $child->set_window( $childwin );
      }
   }
}

method window_lost ( $win )
{
   $self->SUPER::window_lost( $win );

   $_viewport->close if $_viewport;

   undef $_viewport;
}

=head2 scroll

   $scrollbox->scroll( $downward, $rightward )

Requests the content be scrolled downward a number of lines and rightward a
number of columns (either of which which may be negative).

=cut

method scroll ( $downward = 0, $rightward = 0 )
{
   $_vextent->scroll( $downward )  if $_vextent and $downward;
   $_hextent->scroll( $rightward ) if $_hextent and $rightward;
}

=head2 scroll_to

   $scrollbox->scroll_to( $top, $left )

Requests the content be scrolled such that the given line and column number of
the child's content is the topmost visible in the container.

=cut

method scroll_to ( $top = undef, $left = undef )
{
   $_vextent->scroll_to( $top )  if $_vextent and defined $top;
   $_hextent->scroll_to( $left ) if $_hextent and defined $left;
}

method _extent_scrolled ( $id, $delta, $value )
{
   if( my $win = $self->window ) {
      if( $id eq "v" ) {
         $win->expose( Tickit::Rect->new(
            top  => 0,              lines => $win->lines,
            left => $win->cols - 1, cols  => 1,
         ) );
      }
      elsif( $id eq "h" ) {
         $win->expose( Tickit::Rect->new(
            top  => $win->lines - 1, lines => 1,
            left => 0,               cols  => $win->cols,
         ) );
      }
   }

   # Extents use $delta = 0 to just request a redraw e.g. on change of total
   return if $delta == 0;

   my $child = $self->child or return;

   my ( $downward, $rightward ) = ( 0, 0 );
   if( $id eq "v" ) {
      $downward = $delta;
   }
   elsif( $id eq "h" ) {
      $rightward = $delta;
   }

   if( $_child_is_scrollable ) {
      $child->scrolled( $downward, $rightward, $id );
   }
   else {
      my $childwin = $child->window or return;

      $childwin->reposition( $_vextent ? -$_vextent->start : 0,
                             $_hextent ? -$_hextent->start : 0 );

      $_viewport->scroll_with_children( $downward, $rightward );
   }
}

method render_to_rb ( $rb, $rect )
{
   my $win = $self->window or return;

   my $lines = $win->lines;
   my $cols  = $win->cols;

   my $scrollbar_pen  = $self->get_style_pen( "scrollbar" );
   my $scrollmark_pen = $self->get_style_pen( "scrollmark" );
   my $arrow_pen      = $self->get_style_pen( "arrow" );

   my $v_visible = $self->_v_visible;
   my $h_visible = $self->_h_visible;

   if( $v_visible and $rect->right == $cols ) {
      my ( $bar_top, $mark_top, $mark_bottom, $bar_bottom ) =
         $_vextent->scrollbar_geom( 1, $lines - 2 - ( $h_visible ? 1 : 0 ) );
      my $start = $_vextent->start;

      $rb->text_at (        0, $cols-1,
         $start > 0 ? $self->get_style_values( "arrow_up" ) : " ", $arrow_pen );
      $rb->vline_at( $bar_top, $mark_top-1, $cols-1, LINE_DOUBLE, $scrollbar_pen, CAP_BOTH ) if $mark_top > $bar_top;
      $rb->erase_at(       $_, $cols-1, 1, $scrollmark_pen ) for $mark_top .. $mark_bottom-1;
      $rb->vline_at( $mark_bottom, $bar_bottom-1, $cols-1, LINE_DOUBLE, $scrollbar_pen, CAP_BOTH ) if $bar_bottom > $mark_bottom;
      $rb->text_at ( $bar_bottom, $cols-1,
         $start < $_vextent->limit ? $self->get_style_values( "arrow_down" ) : " ", $arrow_pen );
   }

   if( $h_visible and $rect->bottom == $lines ) {
      my ( $bar_left, $mark_left, $mark_right, $bar_right ) =
         $_hextent->scrollbar_geom( 1, $cols - 2 - ( $v_visible ? 1 : 0 ) );
      my $start = $_hextent->start;

      $rb->goto( $lines-1, 0 );

      $rb->text_at(  $lines-1, 0,
         $start > 0 ? $self->get_style_values( "arrow_left" ) : " ", $arrow_pen );
      $rb->hline_at( $lines-1, $bar_left, $mark_left-1, LINE_DOUBLE, $scrollbar_pen, CAP_BOTH ) if $mark_left > $bar_left;
      $rb->erase_at( $lines-1, $mark_left, $mark_right - $mark_left, $scrollmark_pen );
      $rb->hline_at( $lines-1, $mark_right, $bar_right-1, LINE_DOUBLE, $scrollbar_pen, CAP_BOTH ) if $bar_right > $mark_right;
      $rb->text_at(  $lines-1, $bar_right,
         $start < $_hextent->limit ? $self->get_style_values( "arrow_right" ) : " ", $arrow_pen );

      $rb->erase_at( $lines-1, $cols-1, 1 ) if $v_visible;
   }
}

method key_up_1    { $_vextent or return; $_vextent->scroll( -1 ); 1 }
method key_down_1  { $_vextent or return; $_vextent->scroll( +1 ); 1 }
method key_left_1  { $_hextent or return; $_hextent->scroll( -1 ); 1 }
method key_right_1 { $_hextent or return; $_hextent->scroll( +1 ); 1 }

method key_up_half    { $_vextent or return; $_vextent->scroll( -int( $_vextent->viewport / 2 ) ); 1 }
method key_down_half  { $_vextent or return; $_vextent->scroll( +int( $_vextent->viewport / 2 ) ); 1 }
method key_left_half  { $_hextent or return; $_hextent->scroll( -int( $_hextent->viewport / 2 ) ); 1 }
method key_right_half { $_hextent or return; $_hextent->scroll( +int( $_hextent->viewport / 2 ) ); 1 }

method key_to_top       { $_vextent or return; $_vextent->scroll_to( 0 ); 1 }
method key_to_bottom    { $_vextent or return; $_vextent->scroll_to( $_vextent->limit ); 1 }
method key_to_leftmost  { $_hextent or return; $_hextent->scroll_to( 0 ); 1 }
method key_to_rightmost { $_hextent or return; $_hextent->scroll_to( $_hextent->limit ); 1 }

has $_drag_offset;
has $_drag_bar;

method on_mouse ( $args )
{
   my $type   = $args->type;
   my $button = $args->button;

   my $lines = $self->window->lines;
   my $cols  = $self->window->cols;

   my $vlen = $lines - 2 - ( $self->_h_visible ? 1 : 0 );
   my $hlen = $cols  - 2 - ( $self->_v_visible ? 1 : 0 );

   if( $type eq "press" and $button == 1 ) {
      if( $_vextent and $args->col == $cols-1 ) {
         # Click in vertical scrollbar
         my ( undef, $mark_top, $mark_bottom, $bar_bottom ) = $_vextent->scrollbar_geom( 1, $vlen );
         my $line = $args->line;

         if( $line == 0 ) { # up arrow
            $_vextent->scroll( -1 );
         }
         elsif( $line < $mark_top ) { # above area
            $_vextent->scroll( -int( $_vextent->viewport / 2 ) );
         }
         elsif( $line < $mark_bottom ) {
            # press in mark - ignore for now - TODO: prelight?
         }
         elsif( $line < $bar_bottom ) { # below area
            $_vextent->scroll( +int( $_vextent->viewport / 2 ) );
         }
         elsif( $line == $bar_bottom ) { # down arrow
            $_vextent->scroll( +1 );
         }
         return 1;
      }
      if( $_hextent and $args->line == $lines-1 ) {
         # Click in horizontal scrollbar
         my ( undef, $mark_left, $mark_right, $bar_right ) = $_hextent->scrollbar_geom( 1, $hlen );
         my $col = $args->col;

         if( $col == 0 ) { # left arrow
            $_hextent->scroll( -1 );
         }
         elsif( $col < $mark_left ) { # above area
            $_hextent->scroll( -int( $_hextent->viewport / 2 ) );
         }
         elsif( $col < $mark_right ) {
            # press in mark - ignore for now - TODO: prelight
         }
         elsif( $col < $bar_right ) { # below area
            $_hextent->scroll( +int( $_hextent->viewport / 2 ) );
         }
         elsif( $col == $bar_right ) { # right arrow
            $_hextent->scroll( +1 );
         }
         return 1;
      }
   }
   elsif( $type eq "drag_start" and $button == 1 ) {
      if( $_vextent and $args->col == $cols-1 ) {
         # Drag in vertical scrollbar
         my ( undef, $mark_top, $mark_bottom ) = $_vextent->scrollbar_geom( 1, $vlen );
         my $line = $args->line;

         if( $line >= $mark_top and $line < $mark_bottom ) {
            $_drag_offset = $line - $mark_top;
            $_drag_bar    = "v";
            return 1;
         }
      }
      if( $_hextent and $args->line == $lines-1 ) {
         # Drag in horizontal scrollbar
         my ( undef, $mark_left, $mark_right ) = $_hextent->scrollbar_geom( 1, $hlen );
         my $col = $args->col;

         if( $col >= $mark_left and $col < $mark_right ) {
            $_drag_offset = $col - $mark_left;
            $_drag_bar    = "h";
            return 1;
         }
      }
   }
   elsif( $type eq "drag" and $button == 1 and defined $_drag_offset ) {
      if( $_drag_bar eq "v" ) {
         my $want_bar_top = $args->line - $_drag_offset - 1;
         my $want_top = int( $want_bar_top * $_vextent->total / $vlen + 0.5 );
         $_vextent->scroll_to( $want_top );
      }
      if( $_drag_bar eq "h" ) {
         my $want_bar_left = $args->col - $_drag_offset - 1;
         my $want_left = int( $want_bar_left * $_hextent->total / $hlen + 0.5 );
         $_hextent->scroll_to( $want_left );
      }
   }
   elsif( $type eq "drag_stop" ) {
      undef $_drag_offset;
   }
   elsif( $type eq "wheel" ) {
      # Alt-wheel for horizontal
      my $extent = $args->mod & 2 ? $_hextent : $_vextent;
      $extent->scroll( -5 ) if $extent and $button eq "up";
      $extent->scroll( +5 ) if $extent and $button eq "down";
      return 1;
   }
}

=head1 SMART SCROLLING

If the child widget declares it supports smart scrolling, then the ScrollBox
will not implement content scrolling on its behalf. Extra methods are used to
co-ordinate the scroll position between the scrolling-aware child widget and
the containing ScrollBox. This is handled by the following methods on the
child widget.

If smart scrolling is enabled for the child, then its window will be set to
the viewport directly, and the child widget must offset its content within the
window as appropriate. The child must indicate the range of its scrolling
ability by using the C<set_total> method on the extent object it is given.

=head2 $smart = $child->CAN_SCROLL

If this method exists and returns a true value, the ScrollBox will use smart
scrolling. This method must return a true value for this to work, allowing the
method to itself be a proxy, for example, to proxy scrolling information
through a single child widget container.

=head2 $child->set_scrolling_extents( $vextent, $hextent )

Gives the child widget the vertical and horizontal scrolling extents. The
child widget should save thes values, and inspect the C<start> value of them
any time it needs these to implement content offset position when
rendering.

=head2 $child->scrolled( $downward, $rightward, $h_or_v )

Informs the child widget that one of the scroll positions has changed. It
passes the delta (which may be negative) of each position, and a string which
will be either C<"h"> or C<"v"> to indicate whether it was an adjustment of
the horizontal or vertical scrollbar. The extent objects will already have
been updated by this point, so the child may also inspect the C<start> value
of them to obtain the new absolute offsets.

=cut

=head1 TODO

=over 4

=item *

Choice of left/right and top/bottom bar positions.

=item *

Click-and-hold on arrow buttons for auto-repeat

=item *

Allow smarter cooperation with a scrolling-aware child widget; likely by
setting extent objects on the child if it declares to be supported, and use
that instead of an offset child window.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
