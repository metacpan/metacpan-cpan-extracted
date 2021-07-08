#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2021 -- leonerd@leonerd.org.uk

use Object::Pad 0.27;

package Tickit::Widget::VSplit 0.32;
class Tickit::Widget::VSplit
   extends Tickit::Widget::LinearSplit;

use Tickit::Style;
use Tickit::RenderBuffer qw( LINE_SINGLE CAP_BOTH );

use Carp;

use List::Util qw( sum max );

=head1 NAME

C<Tickit::Widget::VSplit> - an adjustable vertical split between two widgets

=head1 SYNOPSIS

   use Tickit;
   use Tickit::Widget::VSplit;
   use Tickit::Widget::Static;

   my $vsplit = Tickit::Widget::VSplit->new
      ->set_left_child ( Tickit::Widget::Static->new( text => "Text above" ) ),
      ->set_right_child( Tickit::Widget::Static->new( text => "Text below" ) );

   Tickit->new( root => $vsplit )->run;

=head1 DESCRIPTION

This container widget holds two child widgets, displayed side by side. The two
widgets are displayed with a vertical split bar between them, which reacts to
mouse click-drag events, allowing the user to adjust the proportion of space
given to the two widgets.

=head1 STYLE

The default style pen is used as the widget pen. The following style pen
prefixes are also used:

=over 4

=item split => PEN

The pen used to render the vertical split area

=back

The following style keys are used:

=over 4

=item spacing => INT

The number of columns of spacing between the left and right child widgets

=back

The following style tags are used:

=over 4

=item :active

Set when a mouse drag resize operation is occurring

=back

=cut

style_definition base =>
   split_fg => "white",
   split_bg => "blue",
   spacing => 1;

style_definition ':active' =>
   split_fg => "hi-white",
   split_b => 1;

style_reshape_keys qw( spacing );

use constant WIDGET_PEN_FROM_STYLE => 1;

use constant VALUE_METHOD => "cols";

=head1 CONSTRUCTOR

=head2 new

   $vsplit = Tickit::Widget::VSplit->new( %args )

Constructs a new C<Tickit::Widget::VSplit> object.

=cut

BUILD
{
   my %args = @_;

   croak "The 'left_child' constructor argument to ${\ref $self} is no longer recognised; use ->set_left_child instead"
      if $args{left_child};

   croak "The 'right_child' constructor argument to ${\ref $self} is no longer recognised; use ->set_right_child instead"
      if $args{right_child};
}

method lines
{
   return max(
      $self->left_child  ? $self->left_child->requested_lines  : 1,
      $self->right_child ? $self->right_child->requested_lines : 1,
   );
}

method cols
{
   my $spacing = $self->get_style_values( "spacing" );
   return sum(
      $self->left_child  ? $self->left_child->requested_cols  : 1,
      $spacing,
      $self->right_child ? $self->right_child->requested_cols : 1,
   );
}

=head1 ACCESSORS

=cut

=head2 left_child

=head2 set_left_child

   $child = $hsplit->left_child

   $vsplit->set_left_child( $child )

Accessor for the child widget used in the left half of the display.

=cut

*left_child     = __PACKAGE__->can( "A_child" );
*set_left_child = __PACKAGE__->can( "set_A_child" );

=head2 right_child

=head2 set_right_child

   $child = $hsplit->right_child

   $vsplit->set_right_child( $child )

Accessor for the child widget used in the right half of the display.

These mutators returning the container widget itself making them suitable to
use as chaining mutators; e.g.

   my $container = Tickit::Widget::VSplit->new( ... )
      ->set_left_child ( Tickit::Widget::Box->new ... )
      ->set_right_child( Tickit::Widget::Box->new ... );

=cut

*right_child     = __PACKAGE__->can( "B_child" );
*set_right_child = __PACKAGE__->can( "set_B_child" );

method _make_child_geom
{
   my ( $start, $len ) = @_;
   return ( 0, $start, $self->window->lines, $len );
}

method render_to_rb
{
   my ( $rb, $rect ) = @_;

   my $split_len = $self->_split_len;
   my $split_at  = $self->_split_at;

   my $lines = $self->window->lines;

   $rb->setpen( $self->get_style_pen( "split" ) );

   $rb->vline_at( 0, $lines-1, $split_at, LINE_SINGLE, undef, CAP_BOTH );

   if( $split_len > 2 ) {
      foreach my $line ( $rect->linerange ) {
         $rb->erase_at( $line, $split_at + 1, $split_len - 2 );
      }
   }
   if( $split_len > 1 ) {
      $rb->vline_at( 0, $lines-1, $split_at + $split_len - 1, LINE_SINGLE, undef, CAP_BOTH );
   }
}

method on_mouse
{
   my ( $args ) = @_;

   if( $args->type ne "wheel" and $args->button == 1 ) {
      return $self->_on_mouse( $args->type, $args->col );
   }
   return;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
