package Retiree;

use Moo;
use Valiant::Validations;

extends 'Person';
with 'TestRole';

has 'retirement_date' => (is=>'ro');

validates 'retirement_date' => (
  with => sub {
    my ($self, $attr, $value, $opts) = @_;
    $self->errors->add($attr => 'Failed Retiree');
  },
);

validates_with 'Custom', notes=>'123';

validates ['age', 'name'], sub {
  my ($self, $attr_name, $value) = @_;
  $self->errors->add($attr_name => _t('log'), +{value=>$value});
};

validates 'name' => (
  length => { in => [3, 25] }, 
  with => {
    cb => sub {
      my ($self, $attr, $value, $opts) = @_;
      $self->errors->add($attr, 'just weird name', $opts);
    },
  },
  if => sub { 1 },
);

1;
