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


done_testing;
