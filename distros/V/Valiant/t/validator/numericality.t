use Test::Most;

{
  package Local::Test::Numericality;

  use Moo;
  use Valiant::Validations;
  use Valiant::I18N;

  has age => (is=>'ro');
  has equals => (is=>'ro', default=>33);

  validates age => (
    numericality => {
      only_integer => 1,
      less_than => 200,
      less_than_or_equal_to => 199,
      greater_than => 10,
      greater_than_or_equal_to => 9,
      equal_to => \&equals,
    },
  );

  validates equals => (numericality => [5,100]);

}

{
  ok my $object = Local::Test::Numericality->new(age=>1110);
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      age => [
        "Age must be equal to 33",
        "Age must be less than 200",
        "Age must be less than or equal to 199",
      ],
    };
}

{
  ok my $object = Local::Test::Numericality->new(age=>8);
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      age => [
        "Age must be equal to 33",
        "Age must be greater than 10",
        "Age must be greater than or equal to 9",
      ],
    };
}

{
  ok my $object = Local::Test::Numericality->new(age=>33.3);
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      age => [
        "Age must be an integer",
      ],
    };
}

{
  ok my $object = Local::Test::Numericality->new(age=>"woow");
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      age => [
        "Age must be an integer",
      ],
    };
}

{
  ok my $object = Local::Test::Numericality->new(age=>15, equals=>101 );
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      age => [
        "Age must be equal to 101",
      ],
      equals => [
        "Equals must be less than or equal to 100",
      ],
    };
}

done_testing;
