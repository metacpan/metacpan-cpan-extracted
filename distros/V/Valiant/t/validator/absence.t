use Test::Most;

{
  package Local::Test::Absence;

  use Moo;
  use Valiant::Validations;

  has name => (is=>'ro');

  validates name => ( absence => 1 );

}

ok my $object = Local::Test::Absence->new(name=>'present');
ok $object->validate->invalid; 
is_deeply +{ $object->errors->to_hash(full_messages=>1) },
  {
    'name' => [
      'Name must be blank',
    ]
  };

done_testing;

