package Person::Validator::Custom;

use Moo;
with 'Valiant::Validator';

has 'max_name_length' => (is=>'ro', required=>1);
has 'min_age' => (is=>'ro', required=>1);

sub validate {
  my ($self, $object, $opts) = @_;
  $object->errors->add(name => "is too long") if length($object->name) > $self->max_name_length;
  $object->errors->add(age => "can't be lower than @{[ $self->min_age ]}") if $object->age < $self->min_age;
}

1;
