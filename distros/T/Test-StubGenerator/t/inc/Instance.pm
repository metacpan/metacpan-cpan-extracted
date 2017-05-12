package Instance;

use strict;
use warnings;

sub instance {
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

sub set_name {
  my $self = shift;
  $self->{ name } = shift;
}
