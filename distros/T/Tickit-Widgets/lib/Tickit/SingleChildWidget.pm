#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2020 -- leonerd@leonerd.org.uk

package Tickit::SingleChildWidget;

use strict;
use warnings;
use base qw( Tickit::ContainerWidget );

our $VERSION = '0.53';

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

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   if( exists $args{child} ) {
      Carp::carp( "The 'child' constructor argument to $class is discouraged; use ->set_child instead" );
      $self->set_child( $args{child} );
   }

   return $self;
}

=head1 METHODS

=cut

=head2 child

   $child = $widget->child

Returns the contained child widget.

=cut

sub child
{
   my $self = shift;
   return $self->{child};
}

sub children
{
   my $self = shift;
   my $child = $self->child;
   return $child ? ( $child ) : () if wantarray;
   return $child ? 1 : 0;
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

sub set_child
{
   my $self = shift;
   my ( $child ) = @_;

   if( my $old_child = $self->child ) {
      undef $self->{child};
      $self->SUPER::remove( $old_child );
   }

   $self->{child} = $child;

   if( $child ) {
      $self->SUPER::add( $child );
   }

   return $self;
}

sub add
{
   my $self = shift;
   croak "Already have a child; cannot add another" if $self->child;
   $self->set_child( $_[0] );
}

sub remove
{
   my $self = shift;
   my ( $child ) = @_;
   croak "Cannot remove this child" if !$self->child or $self->child != $child;
   $self->set_child( undef );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
