use Test::Most;

{
  package Local::Test::User;

  use Moo;
  use Valiant::Validations;
  use Valiant::I18N;

  has age => (is=>'ro');

  validates age => (
    numericality => {
      is_integer => 1,
      less_than => 200,
    },
  );
}

{
  ok my $object = Local::Test::User->new(age=>1110);
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      age => [
        "Age must be less than 200",
      ],
    };
}

{
  ok my $object = Local::Test::User->new(age=>5);
  ok $object->validate->valid;
}

{
  ok my $object = Local::Test::User->new(age=>5);
  $object->validates(age => (numericality => {greater_than => 10}));

  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      age => [
        "Age must be greater than 10",
      ],
    };
}

{
  ok my $object = Local::Test::User->new(age=>5);
  ok $object->validate->valid;
}

done_testing;
