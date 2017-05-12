package T1;
use base 'Validator::Custom';

sub new {
  my $self = shift->SUPER::new(@_);
  
  $self->register_constraint(
    Int => sub{$_[0] =~ /^\d+$/},
    Num => sub{
        require Scalar::Util;
        Scalar::Util::looks_like_number($_[0]);
    },
    C1 => sub {
        my ($value, $args, $options) = @_;
        return [1, $value * 2];
    },
    aaa => sub {$_[0] eq 'aaa'},
    bbb => sub {$_[0] eq 'bbb'}
  );
  
  return $self;
}

1;
