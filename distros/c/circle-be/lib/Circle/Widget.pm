#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2010 -- leonerd@leonerd.org.uk

package Circle::Widget;

use strict;
use warnings;

use base qw( Tangence::Object );

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( @_ );

   $self->set_prop_classes( $args{classes} ) if $args{classes};
   $self->set_prop_focussed( 1 ) if $args{focussed};

   return $self;
}

0x55AA;
