package MyObj;

use strict;
use warnings;

sub new {
  my $class = shift;
  return bless {}, $class;
}

sub get_name {
  my $self = shift;
  return pop @{ $self->{ name } };
}

sub set_names {
  my( $self, @names ) = @_;
  $self->{ names } = [ @names ];
  return;
}
