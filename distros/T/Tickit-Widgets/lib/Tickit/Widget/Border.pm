#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2023 -- leonerd@leonerd.org.uk

use v5.20;
use warnings;
use Object::Pad 0.807;

package Tickit::Widget::Border 0.42;
class Tickit::Widget::Border :strict(params);

inherit Tickit::ContainerWidget;

apply Tickit::WidgetRole::SingleChildContainer;

use Tickit::Style;

use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 NAME

C<Tickit::Widget::Border> - draw a fixed-size border around a widget

=head1 SYNOPSIS

   use Tickit;
   use Tickit::Widget::Border;
   use Tickit::Widget::Static;

   my $border = Tickit::Widget::Border->new
      ->set_child(
         Tickit::Widget::Static->new(
            text   => "Hello, world",
            align  => "centre",
            valign => "middle",
         )
      );

   Tickit->new( root => $border )->run;

=head1 DESCRIPTION

This container widget holds a single child widget and implements a border by
using L<Tickit::WidgetRole::Borderable>.

=head1 STYLE

The default style pen is used as the widget pen.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $border = Tickit::Widget::Border->new( %args );

Constructs a new C<Tickit::Widget::Border> object.

Takes arguments having the names of any of the C<set_*> methods listed below,
without the C<set_> prefix.

=cut

field $_top_border    :reader = 0;
field $_bottom_border :reader = 0;
field $_left_border   :reader = 0;
field $_right_border  :reader = 0;

ADJUST :params ( %params )
{
   defined $params{$_} and $self->${\"set_$_"}( delete $params{$_} ) for qw(
      border
      h_border v_border
      top_border bottom_border left_border right_border
   );
}

method lines
{
   my $child = $self->child;
   return $self->top_border +
          ( $child ? $child->requested_lines : 0 ) +
          $self->bottom_border;
}

method cols
{
   my $child = $self->child;
   return $self->left_border +
          ( $child ? $child->requested_cols : 0 ) +
          $self->right_border;
}

=head1 ACCESSSORS

=cut

=head2 top_border

=head2 set_top_border

   $lines = $border->top_border;

   $border->set_top_border( $lines );

Return or set the number of lines of border at the top of the widget

=cut

# generated accessor

method set_top_border
{
   ( $_top_border ) = @_;
   $self->resized;
}

=head2 bottom_border

=head2 set_bottom_border

   $lines = $border->bottom_border;

   $border->set_bottom_border( $lines );

Return or set the number of lines of border at the bottom of the widget

=cut

# generated accessor

method set_bottom_border
{
   ( $_bottom_border ) = @_;
   $self->resized;
}

=head2 left_border

=head2 set_left_border

   $cols = $border->left_border;

   $border->set_left_border( $cols );

Return or set the number of cols of border at the left of the widget

=cut

# generated accessor

method set_left_border
{
   ( $_left_border ) = @_;
   $self->resized;
}

=head2 right_border

=head2 set_right_border

   $cols = $border->right_border;

   $border->set_right_border( $cols );

Return or set the number of cols of border at the right of the widget

=cut

# generated accessor

method set_right_border
{
   ( $_right_border ) = @_;
   $self->resized;
}

=head2 set_h_border

   $border->set_h_border( $cols );

Set the number of cols of both horizontal (left and right) borders simultaneously

=cut

method set_h_border
{
   my ( $border ) = @_;
   $_left_border = $_right_border = $border;
   $self->resized;
}

=head2 set_v_border

   $border->set_v_border( $cols );

Set the number of lines of both vertical (top and bottom) borders simultaneously

=cut

method set_v_border
{
   my ( $border ) = @_;
   $_top_border = $_bottom_border = $border;
   $self->resized;
}

=head2 set_border

   $border->set_border( $count );

Set the number of cols or lines in all four borders simultaneously

=cut

method set_border
{
   my ( $border ) = @_;
   $_top_border = $_bottom_border = $_left_border = $_right_border = $border;
   $self->resized;
}

## This should come from Tickit::ContainerWidget
method children_changed { $self->resized }

method reshape
{
   my $window = $self->window or return;
   my $child  = $self->child  or return;

   my $top  = $self->top_border;
   my $left = $self->left_border;

   my $lines = $window->lines - $top  - $self->bottom_border;
   my $cols  = $window->cols  - $left - $self->right_border;

   if( $lines > 0 and $cols > 0 ) {
      if( my $childwin = $child->window ) {
         $childwin->change_geometry( $top, $left, $lines, $cols );
      }
      else {
         my $childwin = $window->make_sub( $top, $left, $lines, $cols );
         $child->set_window( $childwin );
      }
   }
   else {
      if( $child->window ) {
         $child->set_window( undef );
      }
   }
}

method render_to_rb
{
   my ( $rb, $rect ) = @_;

   my $win = $self->window or return;
   my $lines = $win->lines;
   my $cols  = $win->cols;

   foreach my $line ( $rect->top .. $self->top_border - 1 ) {
      $rb->erase_at( $line, 0, $cols );
   }

   my $left_border  = $self->left_border;
   my $right_border = $self->right_border;
   my $right_border_at = $cols - $right_border;
   my $bottom_border_at = $lines - $self->bottom_border;

   if( $self->child and $left_border + $right_border < $cols ) {
      foreach my $line ( $self->top_border .. $bottom_border_at ) {
         if( $left_border > 0 ) {
            $rb->erase_at( $line, 0, $left_border );
         }

         if( $right_border > 0 ) {
            $rb->erase_at( $line, $right_border_at, $right_border );
         }
      }
   }
   else {
      foreach my $line ( $self->top_border .. $lines - $self->bottom_border - 1 ) {
         $rb->erase_at( $line, 0, $cols );
      }
   }

   foreach my $line ( $lines - $self->bottom_border .. $rect->bottom - 1 ) {
      $rb->erase_at( $line, 0, $cols );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
