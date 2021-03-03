use Test::Most;

{
  package Local::Test::With;

  use Moo;
  use Valiant::Validations;
  use Valiant::I18N;
  use DateTime;

  has date_of_birth => (is => 'ro');

  validates date_of_birth => (
    with => sub {
      my ($self, $attribute_name, $value, $opts) = @_;
      $self->errors->add($attribute_name, "Can't be born tomorrow") 
        if $value > DateTime->today;
    },
  );

  validates date_of_birth => (
    with => {
      method => 'not_future_with_opts',
      message_if_false => _t('not_future'),
      opts => {arg1 => 100},
    },
  );

  validates date_of_birth => (with => 'not_future_with_err');
  validates date_of_birth => (with => \&not_future_with_err);

  validates date_of_birth => (
    with => ['not_future', 'not future!!'],
  );

  sub not_future_with_err {
    my ($self, $attribute_name, $value, $opts) = @_;
    $self->errors->add($attribute_name, "Bad Date") 
      unless $self->not_future($attribute_name, $value, $opts);

  }

  sub not_future {
    my ($self, $attribute_name, $value, $opts) = @_;
    return $value < DateTime->today;
  }

  sub not_future_with_opts {
    my ($self, $attribute_name, $value, $opts) = @_;
    Test::Most::is $opts->{arg1}, 100, 'got right opts';
    return $value < DateTime->today;
  }


}

ok my $dt = DateTime->new(year=>2364, month=>4, day=>30); # ST:TNG Encounter At Farpoint ;)
ok my $object = Local::Test::With->new(date_of_birth=>$dt);
ok $object->validate->invalid;
is_deeply +{ $object->errors->to_hash(full_messages=>1) },
  {
    'date_of_birth' => [
      'Date Of Birth Can\'t be born tomorrow',
      'Date Of Birth Date 2364-04-30T00:00:00 is future',
      'Date Of Birth Bad Date',
      'Date Of Birth Bad Date',
      'Date Of Birth not future!!',
    ]
  };

done_testing;
