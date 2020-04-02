#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2020 -- leonerd@leonerd.org.uk

package Tickit::Widget::LinearSplit;

use strict;
use warnings;
use base qw( Tickit::ContainerWidget );
use Tickit::Window 0.32; # needs drag_start

our $VERSION = '0.30';

use Carp;

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->{split_fraction} = 0.5;

   return $self;
}

sub A_child
{
   my $self = shift;
   $self->{A_child};
}

sub set_A_child
{
   my $self = shift;
   my ( $child ) = @_;
   $self->remove( $self->{A_child} ) if $self->{A_child};
   $self->add( $self->{A_child} = $child );
   return $self;
}

sub B_child
{
   my $self = shift;
   $self->{B_child};
}

sub set_B_child
{
   my $self = shift;
   my ( $child ) = @_;
   $self->remove( $self->{B_child} ) if $self->{B_child};
   $self->add( $self->{B_child} = $child );
   return $self;
}

sub children
{
   my $self = shift;
   return grep { defined } $self->{A_child}, $self->{B_child};
}

sub child_resized
{
   my $self = shift;
   # TODO: should handle minimums at least
}

## This should come from ContainerWidget
sub children_changed
{
   my $self = shift;

   $self->reshape if $self->window;
   $self->resized;
}
##

sub reshape
{
   my $self = shift;
   my $win = $self->window or return;

   my $spacing = $self->get_style_values( "spacing" );

   my $method = $self->VALUE_METHOD;

   my $quota = $win->$method - $spacing;
   my $want_split_at = int( $quota * $self->{split_fraction} + 0.5 ); # round to nearest

   # Enforce child minimum sizes
   if( my $child = $self->{B_child} ) {
      my $max = $quota - $child->$method;
      $want_split_at = $max if $want_split_at > $max;
   }
   if( my $child = $self->{A_child} ) {
      my $min = $child->$method;
      $want_split_at = $min if $want_split_at < $min;
   }

   my $A_value = $want_split_at;
   my $B_value = $quota - $want_split_at;

   my @A_geom = $self->_make_child_geom( 0,                   $A_value );
   my @B_geom = $self->_make_child_geom( $A_value + $spacing, $B_value );

   if( my $child = $self->{A_child} ) {
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

   if( my $child = $self->{B_child} ) {
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

   $self->{split_at}  = $A_value;
   $self->{split_len} = $spacing;
}

sub _on_mouse
{
   my $self = shift;
   my ( $ev, $val ) = @_;

   my $val0 = $val - $self->{split_at};
   my $in_split = $val0 >= 0 && $val0 < $self->{split_len};

   if( $ev eq "press" ) {
      $self->set_style_tag( active => 1 ) if $in_split;
   }
   elsif( $ev eq "drag_start" ) {
      return unless $in_split;
      $self->{drag_mouse_offset} = $val0;
      return 1;
   }
   elsif( $ev eq "drag" ) {
      return unless defined $self->{drag_mouse_offset};

      my $method = $self->VALUE_METHOD;

      my $quota = $self->window->$method - $self->{split_len};

      my $want_split_at = $val - $self->{drag_mouse_offset};
      $self->{split_fraction} = $want_split_at / $quota;

      $self->reshape;
      $self->redraw;
   }
   elsif( $ev eq "drag_drop" ) {
      undef $self->{drag_mouse_offset};
   }
   elsif( $ev eq "release" ) {
      $self->set_style_tag( active => 0 ) if $in_split;
   }
}

0x55AA;
