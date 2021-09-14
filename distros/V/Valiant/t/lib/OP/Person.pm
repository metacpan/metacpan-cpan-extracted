use v5.26;
use Object::Pad;
class OP::Person isa OP::Base :repr(HASH) {

  use Valiant::Validations;

  has $name :reader :param;
  has $age :reader :param;

  validates_with \&valid_person, test=>100;
  validates_with \&is_nok;

  method valid_person($options) {
    $self->errors->add(name => 'Too Long', $options) if length($name) > 10;
    $self->errors->add(name => "Too Short $options->{test}", $options) if length($name) < 2; 
    $self->errors->add(age => 'Too Young', $options) if $age < 10; 
  }

  method is_nok {
    $self->errors->add(undef, 'Just Bad', +{ details=>'This always fails'});
  }

}
