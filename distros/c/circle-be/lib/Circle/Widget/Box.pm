#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2010 -- leonerd@leonerd.org.uk

package Circle::Widget::Box;

use strict;
use warnings;

use base qw( Circle::Widget );

use Carp;

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( @_ );

   $self->set_prop_orientation( $args{orientation} );

   return $self;
}

sub add
{
   my $self = shift;
   my ( $child, %opts ) = @_;

   $opts{child} = $child;
   $self->push_prop_children( \%opts );
}

sub add_spacer
{
   my $self = shift;
   my ( %opts ) = @_;

   # TODO: For now, only allow one spacer, and it must be in expand mode
   croak "Already have one spacer, can't add another" if grep { !$_->{child} } @{ $self->get_prop_children };
   croak "Spacer must be in expand mode" if !$opts{expand};

   $self->push_prop_children( \%opts );
}

0x55AA;
