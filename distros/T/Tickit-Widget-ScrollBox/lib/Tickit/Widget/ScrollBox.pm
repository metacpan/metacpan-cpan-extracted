#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2016 -- leonerd@leonerd.org.uk

package Tickit::Widget::ScrollBox;

use strict;
use warnings;
use base qw( Tickit::SingleChildWidget );
Tickit::Window->VERSION( '0.39' ); # ->scroll_with_children, default expose_after_scroll
use Tickit::Style;

our $VERSION = '0.07';

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

 my $scrollbox = Tickit::Widget::ScrollBox->new(
    child => Tickit::Widget::Static->new(
       text => join( "\n", map { "The content for line $_" } 1 .. 100 ),
    ),
 );

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

sub new
{
   my $class = shift;
   my %args = @_;

   my $vertical   = delete $args{vertical} // 1;
   my $horizontal = delete $args{horizontal};

   my $child = delete $args{child};

   my $self = $class->SUPER::new( %args );

   $self->{vextent} = Tickit::Widget::ScrollBox::Extent->new( $self, "v" ) if $vertical;
   $self->{hextent} = Tickit::Widget::ScrollBox::Extent->new( $self, "h" ) if $horizontal;

   $self->{v_on_demand} = $vertical  ||'' eq "on_demand";
   $self->{h_on_demand} = $horizontal||'' eq "on_demand";

   $self->add( $child ) if $child;

   return $self;
}

=head1 ACCESSORS

=cut

sub lines
{
   my $self = shift;
   return $self->child->lines + ( $self->hextent ? 1 : 0 );
}

sub cols
{
   my $self = shift;
   return $self->child->cols + ( $self->vextent ? 1 : 0 );
}

=head2 vextent

   $vextent = $scrollbox->vextent

Returns the L<Tickit::Widget::ScrollBox::Extent> object representing the box's
vertical scrolling extent.

=cut

sub vextent
{
   my $self = shift;
   return $self->{vextent};
}

sub _v_visible
{
   my $self = shift;
   return 0 unless my $vextent = $self->{vextent};
   return 1 unless $self->{v_on_demand};
   return $vextent->limit > 0;
}

=head2 hextent

   $hextent = $scrollbox->hextent

Returns the L<Tickit::Widget::ScrollBox::Extent> object representing the box's
horizontal scrolling extent.

=cut

sub hextent
{
   my $self = shift;
   return $self->{hextent};
}

sub _h_visible
{
   my $self = shift;
   return 0 unless my $hextent = $self->{hextent};
   return 1 unless $self->{h_on_demand};
   return $hextent->limit > 0;
}

=head1 METHODS

=cut

sub children_changed
{
   my $self = shift;
   if( my $child = $self->child ) {
      my $scrollable = $self->{child_is_scrollable} = $child->can( "CAN_SCROLL" ) && $child->CAN_SCROLL;

      if( $scrollable ) {
         foreach my $method (qw( set_scrolling_extents scrolled )) {
            $child->can( $method ) or croak "ScrollBox child cannot ->$method - do you implement it?";
         }

         my $vextent = $self->vextent;
         my $hextent = $self->hextent;

         $child->set_scrolling_extents( $vextent, $hextent );
         defined $vextent->real_total or croak "ScrollBox child did not set vextent->total" if $vextent;
         defined $hextent->real_total or croak "ScrollBox child did not set hextent->total" if $hextent;
      }
   }
   $self->SUPER::children_changed;
}

sub reshape
{
   my $self = shift;

   my $window = $self->window or return;
   my $child  = $self->child or return;

   my $vextent = $self->vextent;
   my $hextent = $self->hextent;

   if( !$self->{child_is_scrollable} ) {
      $vextent->set_total( $child->lines ) if $vextent;
      $hextent->set_total( $child->cols  ) if $hextent;
   }

   my $v_spare = ( $vextent ? $vextent->real_total : $window->lines-1 ) - $window->lines;
   my $h_spare = ( $hextent ? $hextent->real_total : $window->cols-1  ) - $window->cols;

   # visibility of each bar might depend on the visibility of the other, if it
   # it was exactly at limit
   $v_spare++ if $v_spare == 0 and $h_spare > 0;
   $h_spare++ if $h_spare == 0 and $v_spare > 0;

   my $v_visible = $vextent && ( !$self->{v_on_demand} || $v_spare > 0 );
   my $h_visible = $hextent && ( !$self->{h_on_demand} || $h_spare > 0 );

   my @viewportgeom = ( 0, 0,
      $window->lines - ( $h_visible ? 1 : 0 ),
      $window->cols  - ( $v_visible ? 1 : 0 ) );

   my $viewport;
   if( $viewport = $self->{viewport} ) {
      $viewport->change_geometry( @viewportgeom );
   }
   else {
      $viewport = $window->make_sub( @viewportgeom );
      $self->{viewport} = $viewport;
   }

   $vextent->set_viewport( $viewport->lines ) if $vextent;
   $hextent->set_viewport( $viewport->cols  ) if $hextent;

   if( $self->{child_is_scrollable} ) {
      $child->set_window( $viewport ) unless $child->window;
   }
   else {
      my ( $childtop, $childlines ) =
         $vextent ? ( -$vextent->start, $vextent->total )
                  : ( 0, max( $child->lines, $viewport->lines ) );

      my ( $childleft, $childcols ) =
         $hextent ? ( -$hextent->start, $hextent->total )
                  : ( 0, max( $child->cols, $viewport->cols ) );

      my @childgeom = ( $childtop, $childleft, $childlines, $childcols );

      if( my $childwin = $child->window ) {
         $childwin->change_geometry( @childgeom );
      }
      else {
         $childwin = $viewport->make_sub( @childgeom );
         $child->set_window( $childwin );
      }
   }
}

sub window_lost
{
   my $self = shift;
   $self->SUPER::window_lost( @_ );

   $self->{viewport}->close if $self->{viewport};

   undef $self->{viewport};
}

=head2 scroll

   $scrollbox->scroll( $downward, $rightward )

Requests the content be scrolled downward a number of lines and rightward a
number of columns (either of which which may be negative).

=cut

sub scroll
{
   my $self = shift;
   my ( $downward, $rightward ) = @_;
   $self->vextent->scroll( $downward )  if $self->vextent and defined $downward;
   $self->hextent->scroll( $rightward ) if $self->hextent and defined $rightward;
}

=head2 scroll_to

   $scrollbox->scroll_to( $top, $left )

Requests the content be scrolled such that the given line and column number of
the child's content is the topmost visible in the container.

=cut

sub scroll_to
{
   my $self = shift;
   my ( $top, $left ) = @_;
   $self->vextent->scroll_to( $top )  if $self->vextent and defined $top;
   $self->hextent->scroll_to( $left ) if $self->hextent and defined $left;
}

sub _extent_scrolled
{
   my $self = shift;
   my ( $id, $delta, $value ) = @_;

   my $vextent = $self->vextent;
   my $hextent = $self->hextent;

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

   if( $self->{child_is_scrollable} ) {
      $child->scrolled( $downward, $rightward, $id );
   }
   else {
      my $childwin = $child->window or return;

      $childwin->reposition( $vextent ? -$vextent->start : 0,
                             $hextent ? -$hextent->start : 0 );

      my $viewport = $self->{viewport};
      $viewport->scroll_with_children( $downward, $rightward );
   }
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;
   my $win = $self->window or return;

   my $lines = $win->lines;
   my $cols  = $win->cols;

   my $scrollbar_pen  = $self->get_style_pen( "scrollbar" );
   my $scrollmark_pen = $self->get_style_pen( "scrollmark" );
   my $arrow_pen      = $self->get_style_pen( "arrow" );

   my $v_visible = $self->_v_visible;
   my $h_visible = $self->_h_visible;

   if( $v_visible and $rect->right == $cols ) {
      my $vextent = $self->vextent;
      my ( $bar_top, $mark_top, $mark_bottom, $bar_bottom ) =
         $vextent->scrollbar_geom( 1, $lines - 2 - ( $h_visible ? 1 : 0 ) );
      my $start = $vextent->start;

      $rb->text_at (        0, $cols-1,
         $start > 0 ? $self->get_style_values( "arrow_up" ) : " ", $arrow_pen );
      $rb->vline_at( $bar_top, $mark_top-1, $cols-1, LINE_DOUBLE, $scrollbar_pen, CAP_BOTH ) if $mark_top > $bar_top;
      $rb->erase_at(       $_, $cols-1, 1, $scrollmark_pen ) for $mark_top .. $mark_bottom-1;
      $rb->vline_at( $mark_bottom, $bar_bottom-1, $cols-1, LINE_DOUBLE, $scrollbar_pen, CAP_BOTH ) if $bar_bottom > $mark_bottom;
      $rb->text_at ( $bar_bottom, $cols-1,
         $start < $vextent->limit ? $self->get_style_values( "arrow_down" ) : " ", $arrow_pen );
   }

   if( $h_visible and $rect->bottom == $lines ) {
      my $hextent = $self->hextent;

      my ( $bar_left, $mark_left, $mark_right, $bar_right ) =
         $hextent->scrollbar_geom( 1, $cols - 2 - ( $v_visible ? 1 : 0 ) );
      my $start = $hextent->start;

      $rb->goto( $lines-1, 0 );

      $rb->text_at(  $lines-1, 0,
         $start > 0 ? $self->get_style_values( "arrow_left" ) : " ", $arrow_pen );
      $rb->hline_at( $lines-1, $bar_left, $mark_left-1, LINE_DOUBLE, $scrollbar_pen, CAP_BOTH ) if $mark_left > $bar_left;
      $rb->erase_at( $lines-1, $mark_left, $mark_right - $mark_left, $scrollmark_pen );
      $rb->hline_at( $lines-1, $mark_right, $bar_right-1, LINE_DOUBLE, $scrollbar_pen, CAP_BOTH ) if $bar_right > $mark_right;
      $rb->text_at(  $lines-1, $bar_right,
         $start < $hextent->limit ? $self->get_style_values( "arrow_right" ) : " ", $arrow_pen );

      $rb->erase_at( $lines-1, $cols-1, 1 ) if $v_visible;
   }
}

sub key_up_1    { my $vextent = shift->vextent or return; $vextent->scroll( -1 ); 1 }
sub key_down_1  { my $vextent = shift->vextent or return; $vextent->scroll( +1 ); 1 }
sub key_left_1  { my $hextent = shift->hextent or return; $hextent->scroll( -1 ); 1 }
sub key_right_1 { my $hextent = shift->hextent or return; $hextent->scroll( +1 ); 1 }

sub key_up_half    { my $vextent = shift->vextent or return; $vextent->scroll( -int( $vextent->viewport / 2 ) ); 1 }
sub key_down_half  { my $vextent = shift->vextent or return; $vextent->scroll( +int( $vextent->viewport / 2 ) ); 1 }
sub key_left_half  { my $hextent = shift->hextent or return; $hextent->scroll( -int( $hextent->viewport / 2 ) ); 1 }
sub key_right_half { my $hextent = shift->hextent or return; $hextent->scroll( +int( $hextent->viewport / 2 ) ); 1 }

sub key_to_top       { my $vextent = shift->vextent or return; $vextent->scroll_to( 0 ); 1 }
sub key_to_bottom    { my $vextent = shift->vextent or return; $vextent->scroll_to( $vextent->limit ); 1 }
sub key_to_leftmost  { my $hextent = shift->hextent or return; $hextent->scroll_to( 0 ); 1 }
sub key_to_rightmost { my $hextent = shift->hextent or return; $hextent->scroll_to( $hextent->limit ); 1 }

sub on_mouse
{
   my $self = shift;
   my ( $args ) = @_;

   my $type   = $args->type;
   my $button = $args->button;

   my $lines = $self->window->lines;
   my $cols  = $self->window->cols;

   my $vextent = $self->vextent;
   my $hextent = $self->hextent;

   my $vlen = $lines - 2 - ( $self->_h_visible ? 1 : 0 );
   my $hlen = $cols  - 2 - ( $self->_v_visible ? 1 : 0 );

   if( $type eq "press" and $button == 1 ) {
      if( $vextent and $args->col == $cols-1 ) {
         # Click in vertical scrollbar
         my ( undef, $mark_top, $mark_bottom, $bar_bottom ) = $vextent->scrollbar_geom( 1, $vlen );
         my $line = $args->line;

         if( $line == 0 ) { # up arrow
            $vextent->scroll( -1 );
         }
         elsif( $line < $mark_top ) { # above area
            $vextent->scroll( -int( $vextent->viewport / 2 ) );
         }
         elsif( $line < $mark_bottom ) {
            # press in mark - ignore for now - TODO: prelight?
         }
         elsif( $line < $bar_bottom ) { # below area
            $vextent->scroll( +int( $vextent->viewport / 2 ) );
         }
         elsif( $line == $bar_bottom ) { # down arrow
            $vextent->scroll( +1 );
         }
         return 1;
      }
      if( $hextent and $args->line == $lines-1 ) {
         # Click in horizontal scrollbar
         my ( undef, $mark_left, $mark_right, $bar_right ) = $hextent->scrollbar_geom( 1, $hlen );
         my $col = $args->col;

         if( $col == 0 ) { # left arrow
            $hextent->scroll( -1 );
         }
         elsif( $col < $mark_left ) { # above area
            $hextent->scroll( -int( $hextent->viewport / 2 ) );
         }
         elsif( $col < $mark_right ) {
            # press in mark - ignore for now - TODO: prelight
         }
         elsif( $col < $bar_right ) { # below area
            $hextent->scroll( +int( $hextent->viewport / 2 ) );
         }
         elsif( $col == $bar_right ) { # right arrow
            $hextent->scroll( +1 );
         }
         return 1;
      }
   }
   elsif( $type eq "drag_start" and $button == 1 ) {
      if( $vextent and $args->col == $cols-1 ) {
         # Drag in vertical scrollbar
         my ( undef, $mark_top, $mark_bottom ) = $vextent->scrollbar_geom( 1, $vlen );
         my $line = $args->line;

         if( $line >= $mark_top and $line < $mark_bottom ) {
            $self->{drag_offset} = $line - $mark_top;
            $self->{drag_bar}    = "v";
            return 1;
         }
      }
      if( $hextent and $args->line == $lines-1 ) {
         # Drag in horizontal scrollbar
         my ( undef, $mark_left, $mark_right ) = $hextent->scrollbar_geom( 1, $hlen );
         my $col = $args->col;

         if( $col >= $mark_left and $col < $mark_right ) {
            $self->{drag_offset} = $col - $mark_left;
            $self->{drag_bar}    = "h";
            return 1;
         }
      }
   }
   elsif( $type eq "drag" and $button == 1 and defined( $self->{drag_offset} ) ) {
      if( $self->{drag_bar} eq "v" ) {
         my $want_bar_top = $args->line - $self->{drag_offset} - 1;
         my $want_top = int( $want_bar_top * $vextent->total / $vlen + 0.5 );
         $vextent->scroll_to( $want_top );
      }
      if( $self->{drag_bar} eq "h" ) {
         my $want_bar_left = $args->col - $self->{drag_offset} - 1;
         my $want_left = int( $want_bar_left * $hextent->total / $hlen + 0.5 );
         $hextent->scroll_to( $want_left );
      }
   }
   elsif( $type eq "drag_stop" ) {
      undef $self->{drag_offset};
   }
   elsif( $type eq "wheel" ) {
      # Alt-wheel for horizontal
      my $extent = $args->mod & 2 ? $self->hextent : $self->vextent;
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
