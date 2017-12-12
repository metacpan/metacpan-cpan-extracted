#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::VSplit;

use strict;
use warnings;
use base qw( Tickit::Widget::LinearSplit );
use Tickit::Style;
use Tickit::RenderBuffer qw( LINE_SINGLE CAP_BOTH );

our $VERSION = '0.28';

use Carp;

use List::Util qw( sum max );

=head1 NAME

C<Tickit::Widget::VSplit> - an adjustable vertical split between two widgets

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::VSplit;
 use Tickit::Widget::Static;

 my $vsplit = Tickit::Widget::VSplit->new(
    left_child  => Tickit::Widget::Static->new( text => "Text above" ),
    right_child => Tickit::Widget::Static->new( text => "Text below" ),
 );

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

=head2 $vsplit = Tickit::Widget::VSplit->new( %args )

Constructs a new C<Tickit::Widget::VSplit> object.

Takes the following named arguments

=over 8

=item left_child => WIDGET

=item right_child => WIDGET

Child widgets to use

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->set_left_child ( $args{left_child}  ) if $args{left_child};
   $self->set_right_child( $args{right_child} ) if $args{right_child};

   return $self;
}

sub lines
{
   my $self = shift;
   return max(
      $self->{A_child} ? $self->{A_child}->requested_lines : 1,
      $self->{B_child} ? $self->{B_child}->requested_lines : 1,
   );
}

sub cols
{
   my $self = shift;
   my $spacing = $self->get_style_values( "spacing" );
   return sum(
      $self->{A_child} ? $self->{A_child}->requested_cols : 1,
      $spacing,
      $self->{B_child} ? $self->{B_child}->requested_cols : 1,
   );
}

=head1 ACCESSORS

=cut

=head2 $child = $hsplit->left_child

=head2 $vsplit->set_left_child( $child )

Accessor for the child widget used in the left half of the display.

=cut

*left_child     = __PACKAGE__->can( "A_child" );
*set_left_child = __PACKAGE__->can( "set_A_child" );

=head2 $child = $hsplit->right_child

=head2 $vsplit->set_right_child( $child )

Accessor for the child widget used in the right half of the display.

=cut

*right_child     = __PACKAGE__->can( "B_child" );
*set_right_child = __PACKAGE__->can( "set_B_child" );

sub _make_child_geom
{
   my $self = shift;
   my ( $start, $len ) = @_;
   return ( 0, $start, $self->window->lines, $len );
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   my $split_len = $self->{split_len};

   my $lines = $self->window->lines;

   $rb->setpen( $self->get_style_pen( "split" ) );

   $rb->vline_at( 0, $lines-1, $self->{split_at}, LINE_SINGLE, undef, CAP_BOTH );

   if( $split_len > 2 ) {
      foreach my $line ( $rect->linerange ) {
         $rb->erase_at( $line, $self->{split_at} + 1, $split_len - 2 );
      }
   }
   if( $split_len > 1 ) {
      $rb->vline_at( 0, $lines-1, $self->{split_at} + $split_len - 1, LINE_SINGLE, undef, CAP_BOTH );
   }
}

sub on_mouse
{
   my $self = shift;
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
