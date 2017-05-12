#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::Border;

use strict;
use warnings;
use base qw( Tickit::SingleChildWidget );
use Tickit::Style;

our $VERSION = '0.27';

use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 NAME

C<Tickit::Widget::Border> - draw a fixed-size border around a widget

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::Border;
 use Tickit::Widget::Static;

 my $hello = Tickit::Widget::Static->new(
    text   => "Hello, world",
    align  => "centre",
    valign => "middle",
 );

 my $border = Tickit::Widget::Border->new;

 $border->set_child( $hello );

 Tickit->new( root => $border )->run;

=head1 DESCRIPTION

This container widget holds a single child widget and implements a border by
using L<Tickit::WidgetRole::Borderable>.

=head1 STYLE

The default style pen is used as the widget pen.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $border = Tickit::Widget::Border->new( %args )

Constructs a new C<Tickit::Widget::Border> object.

Takes arguments having the names of any of the C<set_*> methods listed below,
without the C<set_> prefix.

=cut

sub new
{
   my $class = shift;
   my %args = @_;
   my $self = $class->SUPER::new( %args );

   $self->{"${_}_border"} = 0 for qw( top bottom left right );

   defined $args{$_} and $self->${\"set_$_"}( delete $args{$_} ) for qw(
      border
      h_border v_border
      top_border bottom_border left_border right_border
   );

   return $self;
}

sub lines
{
   my $self = shift;
   my $child = $self->child;
   return $self->top_border +
          ( $child ? $child->requested_lines : 0 ) +
          $self->bottom_border;
}

sub cols
{
   my $self = shift;
   my $child = $self->child;
   return $self->left_border +
          ( $child ? $child->requested_cols : 0 ) +
          $self->right_border;
}

=head1 ACCESSSORS

=cut

=head2 $lines = $border->top_border

=head2 $border->set_top_border( $lines )

Return or set the number of lines of border at the top of the widget

=cut

sub top_border
{
   my $self = shift;
   return $self->{top_border};
}

sub set_top_border
{
   my $self = shift;
   $self->{top_border} = $_[0];
   $self->resized;
}

=head2 $lines = $border->bottom_border

=head2 $border->set_bottom_border( $lines )

Return or set the number of lines of border at the bottom of the widget

=cut

sub bottom_border
{
   my $self = shift;
   return $self->{bottom_border};
}

sub set_bottom_border
{
   my $self = shift;
   $self->{bottom_border} = $_[0];
   $self->resized;
}

=head2 $cols = $border->left_border

=head2 $border->set_left_border( $cols )

Return or set the number of cols of border at the left of the widget

=cut

sub left_border
{
   my $self = shift;
   return $self->{left_border};
}

sub set_left_border
{
   my $self = shift;
   $self->{left_border} = $_[0];
   $self->resized;
}

=head2 $cols = $border->right_border

=head2 $border->set_right_border( $cols )

Return or set the number of cols of border at the right of the widget

=cut

sub right_border
{
   my $self = shift;
   return $self->{right_border};
}

sub set_right_border
{
   my $self = shift;
   $self->{right_border} = $_[0];
   $self->resized;
}

=head2 $border->set_h_border( $cols )

Set the number of cols of both horizontal (left and right) borders simultaneously

=cut

sub set_h_border
{
   my $self = shift;
   $self->{left_border} = $self->{right_border} = $_[0];
   $self->resized;
}

=head2 $border->set_v_border( $cols )

Set the number of lines of both vertical (top and bottom) borders simultaneously

=cut

sub set_v_border
{
   my $self = shift;
   $self->{top_border} = $self->{bottom_border} = $_[0];
   $self->resized;
}

=head2 $border->set_border( $count )

Set the number of cols or lines in all four borders simultaneously

=cut

sub set_border
{
   my $self = shift;
   $self->{top_border} = $self->{bottom_border} = $self->{left_border} = $self->{right_border} = $_[0];
   $self->resized;
}

## This should come from Tickit::ContainerWidget
sub children_changed { shift->reshape }

sub reshape
{
   my $self = shift;

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

sub render_to_rb
{
   my $self = shift;
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
