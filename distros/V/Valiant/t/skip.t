use Test::Most;

{
  package Local::Test::Numericality;

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
  ok my $object = Local::Test::Numericality->new(age=>1110);
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      age => [
        "Age must be less than 200",
      ],
    };

  $object->clear_validated;
  ok $object->skip_validate->valid;
}

{
  # validated/skip_validation are internal state, not constructor-settable
  ok my $object = Local::Test::Numericality->new(age=>5, validated=>1, skip_validation=>1);
  is $object->validated, 0, 'validated not settable via constructor';
  is $object->skip_validation, 0, 'skip_validation not settable via constructor';
}


done_testing;
