{
  package Local::A;

  use Moo;

  with 'Valiant::Translation';

  sub validate {
    my $self = shift;
    $self->errors->add('test01', $self->i18n->make_tag('invalid'), +{ message => 'another test error1' });
  }

  sub read_attribute_for_validation {
    my ($self, $attribute) = @_;
    return unless defined $attribute;
    return my $value = $self->$attribute
      if $self->can($attribute);
  }

  package Local::B;

  use Moo::Role;
  
  with 'Valiant::Translation';

  after 'validate', sub {
    my $self = shift;
    $self->errors->add(undef, 'test model error');
  };

  package Local::C;

  use Valiant::Errors;
  use Valiant::I18N;
  use Moo;

  extends 'Local::A';
  with 'Local::B';

  has 'errors' => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    default => sub { Valiant::Errors->new(object=>shift) },
  );

  after 'validate', sub {
    my $self = shift;
    $self->errors->add('test01', _t('invalid') );
    $self->errors->add('test02', 'test error');
  };
}

use Test::Most;

ok my $c = Local::C->new;
$c->validate;

is_deeply +{ $c->errors->to_hash }, +{
    "*" => [
      "test model error",
    ],
    test01 => [
      "another test error1",
      "Is Invalid",
    ],
    test02 => [
      "test error",
    ],
  };

done_testing;
