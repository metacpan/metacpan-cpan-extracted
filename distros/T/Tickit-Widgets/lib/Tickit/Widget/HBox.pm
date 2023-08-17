#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2021 -- leonerd@leonerd.org.uk

use v5.20;
use Object::Pad 0.57;

package Tickit::Widget::HBox 0.52;
class Tickit::Widget::HBox
   :strict(params)
   :isa(Tickit::Widget::LinearBox);

use Tickit::Style;
use Tickit::RenderBuffer qw( CAP_BOTH );

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

Optionally, if given a non-zero spacing between child widgets and a style to
draw in, a vertical dividing line will be drawn between each child.

=head1 STYLE

The default style pen is used as the widget pen. The following style pen
prefixes are also used:

=over 4

=item line => PEN

I<Since version 0.52.>

The pen used to render a dividing line between child widgets.

=back

Note that while the widget pen is mutable and changes to it will result in
immediate redrawing, any changes made will be lost if the widget style is
changed.

The following style keys are used:

=over 4

=item spacing => INT

The number of columns of spacing between children

=item line_style => INT

I<Since version 0.52.>

If set, the style to draw a dividing line between each child widget. Must be
one of the C<LINE_*> constants from L<Tickit::RenderBuffer>.

=back

=cut

style_definition base =>
   spacing => 0,
   line_style => 0;

style_reshape_keys qw( spacing );

style_redraw_keys qw( line_style );

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

method render_dividing_line
{
   my ( $rb, $prev_win, $next_win, $style, $pen ) = @_;

   my $top        = 0;
   my $gap_left   = $prev_win->right;
   my $gap_right  = $next_win->left - 1;
   my $bottom     = $next_win->bottom;

   my $line_col = int( ( $gap_left + $gap_right ) / 2 );

   $rb->vline_at( $top, $bottom, $line_col, $style, $pen, CAP_BOTH );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
