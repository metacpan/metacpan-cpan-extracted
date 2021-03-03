package TestRole;

use Moo::Role;
use Valiant::Validations;
use Valiant::I18N;

validates_with sub {
  my ($self) = @_;
  $self->errors->add(undef, 'Failed TestRole');
  $self->errors->add('name');
  $self->errors->add(name => _t 'bad', +{ all=>1 } );
};

1;
