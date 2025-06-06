#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2023 -- leonerd@leonerd.org.uk

use v5.20;
use warnings;
use Object::Pad 0.800;

package Tickit::WidgetRole::SingleChildContainer 0.42;
role Tickit::WidgetRole::SingleChildContainer;

use Carp;

=head1 NAME

C<Tickit::WidgetRole::SingleChildContainer> - role for widgets that contain a
single other widget

=head1 SYNOPSIS

   class Some::Widget::Class
      :isa(Tickit::Widget)
      :does(Tickit::WidgetRole::SingleChildContainer);

   ...

=head1 DESCRIPTION

Applying this role to a L<Tickit::Widget> subclass adds behaviour for it to
act as a container widget holding a single child widget.

=cut

field $_child :reader;

=head1 METHODS

=cut

=head2 child

   $child = $widget->child;

Returns the contained child widget.

=cut

# generated accessor

method children
{
   return $_child ? ( $_child ) : () if wantarray;
   return $_child ? 1 : 0;
}

=head2 set_child

   $widget->set_child( $child );

Sets the child widget, or C<undef> to remove.

This method returns the container widget instance itself making it suitable to
use as a chaining mutator; e.g.

   my $container = Tickit::SingleChildWidget->new( ... )
      ->set_child( Tickit::Widget::Static->new( ... ) );

=cut

method set_child
{
   my ( $child ) = @_;

   if( my $old_child = $_child ) {
      $self->remove( $old_child );
   }

   if( $child ) {
      $self->add( $child );
   }

   return $self;
}

method add
{
   croak "Already have a child; cannot add another" if $_child;
   ( $_child ) = @_;
   $self->next::method( @_ );
}

method remove
{
   my ( $child ) = @_;
   croak "Cannot remove this child" if !$_child or $_child != $child;
   undef $_child;
   $self->next::method( $child );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
