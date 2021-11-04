use Test::Most;

{
  package Local::Test::Scalar;

  use Moo;
  use Valiant::Validations;

  has name => (is=>'ro');

  validates name => ( scalar => 1 );

}

{
  ok my $object = Local::Test::Scalar->new(name=>'John');
  ok $object->validate->valid;
}

{
  ok my $object = Local::Test::Scalar->new(name=>[111,'John']);
  ok $object->validate->invalid;

  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
  {
    'name' => [
      'Name must be a string or number',
    ]
  };
}

done_testing;
