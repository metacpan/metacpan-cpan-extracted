package T2;
use base 'Validator::Custom';

use T3;
use T4;

sub new {
  my $self = shift->SUPER::new(@_);
  
  $self->register_constraint(T3->new->constraints);
  $self->register_constraint(T4->new->constraints);
  
  return $self;
}


1;
