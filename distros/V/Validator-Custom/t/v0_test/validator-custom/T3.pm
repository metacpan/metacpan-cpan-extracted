package T3;
use base 'Validator::Custom';

sub new {
  my $self = shift->SUPER::new(@_);
  
  $self->register_constraint(
    Int => sub{$_[0] =~ /^\d+$/}
  );
  
  return $self;
}

1;
