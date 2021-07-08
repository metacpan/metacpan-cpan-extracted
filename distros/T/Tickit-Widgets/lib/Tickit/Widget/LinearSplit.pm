#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2021 -- leonerd@leonerd.org.uk

use Object::Pad 0.09;

package Tickit::Widget::LinearSplit 0.32;
class Tickit::Widget::LinearSplit
   extends Tickit::ContainerWidget;

use Tickit::Window 0.32; # needs drag_start

use Carp;

has $_split_fraction = 0.5;
has $_A_child :reader;
has $_B_child :reader;

has $_split_at;  method _split_at  { $_split_at }
has $_split_len; method _split_len { $_split_len }

method set_A_child
{
   my ( $child ) = @_;
   $self->remove( $_A_child ) if $_A_child;
   $self->add( $_A_child = $child );
   return $self;
}

method set_B_child
{
   my ( $child ) = @_;
   $self->remove( $_B_child ) if $_B_child;
   $self->add( $_B_child = $child );
   return $self;
}

method children
{
   return grep { defined } $_A_child, $_B_child;
}

method child_resized
{
   # TODO: should handle minimums at least
}

## This should come from ContainerWidget
method children_changed
{
   $self->reshape if $self->window;
   $self->resized;
}
##

method reshape
{
   my $win = $self->window or return;

   my $spacing = $self->get_style_values( "spacing" );

   my $method = $self->VALUE_METHOD;

   my $quota = $win->$method - $spacing;
   my $want_split_at = int( $quota * $_split_fraction + 0.5 ); # round to nearest

   # Enforce child minimum sizes
   if( my $child = $_B_child ) {
      my $max = $quota - $child->$method;
      $want_split_at = $max if $want_split_at > $max;
   }
   if( my $child = $_A_child ) {
      my $min = $child->$method;
      $want_split_at = $min if $want_split_at < $min;
   }

   my $A_value = $want_split_at;
   my $B_value = $quota - $want_split_at;

   my @A_geom = $self->_make_child_geom( 0,                   $A_value );
   my @B_geom = $self->_make_child_geom( $A_value + $spacing, $B_value );

   if( my $child = $_A_child ) {
      if( $A_value > 0 ) {
         if( my $childwin = $child->window ) {
            $childwin->change_geometry( @A_geom );
         }
         else {
            $child->set_window( $win->make_sub( @A_geom ) );
         }
      }
      else {
         $child->set_window( undef );
      }
   }

   if( my $child = $_B_child ) {
      if( $B_value > 0 ) {
         if( my $childwin = $child->window ) {
            $childwin->change_geometry( @B_geom );
         }
         else {
            $child->set_window( $win->make_sub( @B_geom ) );
         }
      }
      else {
         $child->set_window( undef );
      }
   }

   $_split_at  = $A_value;
   $_split_len = $spacing;
}

has $_drag_mouse_offset;

method _on_mouse
{
   my ( $ev, $val ) = @_;

   my $val0 = $val - $_split_at;
   my $in_split = $val0 >= 0 && $val0 < $_split_len;

   if( $ev eq "press" ) {
      $self->set_style_tag( active => 1 ) if $in_split;
   }
   elsif( $ev eq "drag_start" ) {
      return unless $in_split;
      $_drag_mouse_offset = $val0;
      return 1;
   }
   elsif( $ev eq "drag" ) {
      return unless defined $_drag_mouse_offset;

      my $method = $self->VALUE_METHOD;

      my $quota = $self->window->$method - $_split_len;

      my $want_split_at = $val - $_drag_mouse_offset;
      $_split_fraction = $want_split_at / $quota;

      $self->reshape;
      $self->redraw;
   }
   elsif( $ev eq "drag_drop" ) {
      undef $_drag_mouse_offset;
   }
   elsif( $ev eq "release" ) {
      $self->set_style_tag( active => 0 ) if $in_split;
   }
}

0x55AA;
