#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2020 -- leonerd@leonerd.org.uk

use Object::Pad 0.09;

package Tickit::Widget::HBox 0.49;
class Tickit::Widget::HBox
   extends Tickit::Widget::LinearBox;

use Tickit::Style;

use List::Util qw( sum max );

=head1 NAME

C<Tickit::Widget::HBox> - distribute child widgets in a horizontal row

=head1 SYNOPSIS

   use Tickit;
   use Tickit::Widget::HBox;
   use Tickit::Widget::Static;

   my $hbox = Tickit::Widget::HBox->new;

   foreach my $position (qw( left centre right )) {
      $hbox->add(
         Tickit::Widget::Static->new(
            text   => $position,
            align  => $position,
            valign => "middle",
         ),
         expand => 1
      );
   }

   Tickit->new( root => $hbox )->run;

=head1 DESCRIPTION

This subclass of L<Tickit::Widget::LinearBox> distributes its children in a
horizontal row. Its height will be the height of the tallest child, and its
width will be the sum of the widths of all the children, plus the inter-child
spacing.

=head1 STYLE

The default style pen is used as the widget pen.

Note that while the widget pen is mutable and changes to it will result in
immediate redrawing, any changes made will be lost if the widget style is
changed.

The following style keys are used:

=over 4

=item spacing => INT

The number of columns of spacing between children

=back

=cut

style_definition base =>
   spacing => 0;

style_reshape_keys qw( spacing );

use constant WIDGET_PEN_FROM_STYLE => 1;

method lines
{
   return max( 1, map { $_->requested_lines } $self->children );
}

method cols
{
   my $spacing = $self->get_style_values( "spacing" );
   return ( sum( map { $_->requested_cols } $self->children ) || 1 ) +
          $spacing * ( $self->children - 1 );
}

method get_total_quota
{
   my ( $window ) = @_;
   return $window->cols;
}

method get_child_base
{
   my ( $child ) = @_;
   return $child->requested_cols;
}

method set_child_window
{
   my ( $child, $left, $cols, $window ) = @_;

   if( $window and $cols ) {
      if( my $childwin = $child->window ) {
         $childwin->change_geometry( 0, $left, $window->lines, $cols );
      }
      else {
         my $childwin = $window->make_sub( 0, $left, $window->lines, $cols );
         $child->set_window( $childwin );
      }
   }
   else {
      if( my $childwin = $child->window ) {
         $child->set_window( undef );
         $childwin->close;
      }
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
