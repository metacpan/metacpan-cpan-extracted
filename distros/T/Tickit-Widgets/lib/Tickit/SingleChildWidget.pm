#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2013 -- leonerd@leonerd.org.uk

package Tickit::SingleChildWidget;

use strict;
use warnings;
use base qw( Tickit::ContainerWidget );

our $VERSION = '0.51';

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

=head2 $widget = Tickit::SingleChildWidget->new( %args )

Constructs a new C<Tickit::SingleChildWidget> object. If passed an argument
called C<child> this will be added as the contained child widget.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->set_child( $args{child} ) if exists $args{child};

   return $self;
}

=head1 METHODS

=cut

=head2 $child = $widget->child

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

=head2 $widget->set_child( $child )

Sets the child widget, or C<undef> to remove.

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
}

sub add
{
   my $self = shift;
   croak "Already have a child; cannot add another" if $self->child;
   $self->set_child( $_[0] );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
