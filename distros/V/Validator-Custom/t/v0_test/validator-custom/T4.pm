package T4;
use base 'Validator::Custom';

sub new {
  my $self = shift;
  
  $self->register_constraint({
    Num => sub{
        require Scalar::Util;
        Scalar::Util::looks_like_number($_[0]);
    }
  });
  
  return $self;
}
1;
