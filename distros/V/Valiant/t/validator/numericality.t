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

{
  package Local::Test::Decimals;

  use Moo;
  use Valiant::Validations;

  has amount => (is=>'ro');

  validates amount => ( numericality => { decimals => 2 } );
}

{
  # decimals check must not warn on a value with no decimal point
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  ok my $object = Local::Test::Decimals->new(amount => 5);
  $object->validate;
  is_deeply \@warnings, [], 'decimals check does not warn on integer value';
}

{
  package Local::Test::Numericality::PgSerial;

  use Moo;
  use Valiant::Validations;

  has id => (is=>'ro');

  validates id => (numericality => 'pg_serial');
}

{
  ok my $object = Local::Test::Numericality::PgSerial->new(id=>0);
  ok $object->validate->invalid, 'serial ids start at 1, so 0 is out of range';
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    { id => [ "Id is not in acceptable value range" ] };
}

{
  ok my $object = Local::Test::Numericality::PgSerial->new(id=>5);
  ok $object->validate->valid, 'a real pg_serial value like 5 must validate cleanly';
}

done_testing;
