#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2020 -- leonerd@leonerd.org.uk

use Object::Pad 0.27;

package Tickit::SingleChildWidget 0.53;
class Tickit::SingleChildWidget
   extends Tickit::ContainerWidget;

use Carp;

=head1 NAME

C<Tickit::SingleChildWidget> - abstract base class for widgets that contain a
single other widget

=head1 SYNOPSIS

 TODO

=head1 DESCRIPTION

This subclass of L<Tickit::ContainerWidget> acts as an abstract base class for
widgets that contain exactly one other widget. It enforces that only one child
widget may be contained at any one time, and provides a convenient accessor to
obtain it.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $widget = Tickit::SingleChildWidget->new( %args )

Constructs a new C<Tickit::SingleChildWidget> object.

As a back-compatibility option if passed an argument called C<child> this will
be added as the contained child widget. This is now discouraged as it
complicates the creation of subclasses; see instead the L</set_child> method
used as a chaining mutator.

=cut

has $_child;

BUILD
{
   my %args = @_;

   if( exists $args{child} ) {
      Carp::carp( "The 'child' constructor argument to ${\ref $self} is discouraged; use ->set_child instead" );
      $self->set_child( $args{child} );
   }
}

=head1 METHODS

=cut

=head2 child

   $child = $widget->child

Returns the contained child widget.

=cut

method child { $_child }

method children
{
   return $_child ? ( $_child ) : () if wantarray;
   return $_child ? 1 : 0;
}

=head2 set_child

   $widget->set_child( $child )

Sets the child widget, or C<undef> to remove.

This method returns the container widget instance itself making it suitable to
use as a chaining mutator; e.g.

   my $container = Tickit::SingleChildWidget->new( ... )
      ->set_child( Tickit::Widget::Static->new( ... ) );

This should be preferred over using the C<child> constructor argument, which
is now discouraged.

=cut

method set_child
{
   my ( $child ) = @_;

   if( my $old_child = $_child ) {
      undef $_child;
      $self->SUPER::remove( $old_child );
   }

   $_child = $child;

   if( $child ) {
      $self->SUPER::add( $child );
   }

   return $self;
}

method add
{
   croak "Already have a child; cannot add another" if $_child;
   $self->set_child( $_[0] );
}

method remove
{
   my ( $child ) = @_;
   croak "Cannot remove this child" if !$_child or $_child != $child;
   $self->set_child( undef );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
