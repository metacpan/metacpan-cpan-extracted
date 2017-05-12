package T6;
use base 'Validator::Custom';

sub new {
  my $self = shift;
  
  $self->register_constraint(
    length => sub {
        my ($value, $args) = @_;
        
        my $min;
        my $max;
        
        ($min, $max) = @$args;
        my $length  = length $value;
        return $min <= $length && $length <= $max ? 1 : 0;
    }
  );
  
  return $self;
}

1;