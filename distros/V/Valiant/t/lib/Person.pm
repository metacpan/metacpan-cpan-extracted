package Person;

use Moo;
use Valiant::Validations;
use Valiant::I18N;

has 'name' => (is=>'ro',);
has 'age' => (is=>'ro');

validates_with \&valid_person, test=>100, if => sub { my ($self, $options) = @_;  return 1  };
validates_with \&is_nok;

sub valid_person {
  my ($self, $options) = @_;
  $self->errors->add(name => 'Too Long', $options) if length($self->name) > 10;
  $self->errors->add(name => "Too Short $options->{test}", $options) if length($self->name) < 2; 
  $self->errors->add(age => 'Too Young', $options) if $self->age < 10; 
}

sub is_nok {
  my ($self) = @_;
  $self->errors->add(undef, _t('bad'), +{ details=>'This always fails'});
}

1;
