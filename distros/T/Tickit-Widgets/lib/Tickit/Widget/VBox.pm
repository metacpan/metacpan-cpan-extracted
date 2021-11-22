#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2020 -- leonerd@leonerd.org.uk

use Object::Pad 0.57;

package Tickit::Widget::VBox 0.50;
class Tickit::Widget::VBox
   :isa(Tickit::Widget::LinearBox);

use Tickit::Style;

use List::Util qw( sum max );

=head1 NAME

C<Tickit::Widget::VBox> - distribute child widgets in a vertical column

=head1 SYNOPSIS

   use Tickit;
   use Tickit::Widget::VBox;
   use Tickit::Widget::Static;

   my $vbox = Tickit::Widget::VBox->new;

   foreach my $position (qw( top middle bottom )) {
      $vbox->add(
         Tickit::Widget::Static->new(
            text   => $position,
            align  => "centre",
            valign => $position,
         ),
         expand => 1
      );
   }

   Tickit->new( root => $vbox )->run;

=head1 DESCRIPTION

This subclass of L<Tickit::Widget::LinearBox> distributes its children in a
vertical column. Its width will be the width of the widest child, and its
height will be the sum of the heights of all the children, plus the
inter-child spacing.

=head1 STYLE

The default style pen is used as the widget pen.

Note that while the widget pen is mutable and changes to it will result in
immediate redrawing, any changes made will be lost if the widget style is
changed.

The following style keys are used:

=over 4

=item spacing => INT

The number of lines of spacing between children

=back

=cut

style_definition base =>
   spacing => 0;

style_reshape_keys qw( spacing );

use constant WIDGET_PEN_FROM_STYLE => 1;

method lines
{
   my $spacing = $self->get_style_values( "spacing" );
   return ( sum( map { $_->requested_lines } $self->children ) || 1 ) +
          $spacing * ( $self->children - 1 );
}

method cols
{
   return max( 1, map { $_->requested_cols } $self->children );
}

method get_total_quota
{
   my ( $window ) = @_;
   return $window->lines;
}

method get_child_base
{
   my ( $child ) = @_;
   return $child->requested_lines;
}

method set_child_window
{
   my ( $child, $top, $lines, $window ) = @_;

   if( $window and $lines ) {
      if( my $childwin = $child->window ) {
         $childwin->change_geometry( $top, 0, $lines, $window->cols );
      }
      else {
         my $childwin = $window->make_sub( $top, 0, $lines, $window->cols );
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
