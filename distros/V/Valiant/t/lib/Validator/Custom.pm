package Validator::Custom;

use Moo;
with 'Valiant::Validator';

has 'notes' => (is=>'ro', required=>1);

sub validate {
  my ($self, $object) = @_;
  $object->errors->add(name => 'Too Custom: '. $self->notes);
}

1;
