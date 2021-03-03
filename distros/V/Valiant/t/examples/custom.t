use Test::Most;
use Test::Lib;

{
  package Person;

  use Valiant::Validations;
  use Moo;

  has name => (is => 'ro');
  has age => (is => 'ro');

  validates_with Custom => (
    max_name_length => 20, 
    min_age => 5,
  );
}

ok my $person = Person->new(
  name => 'A waaay too loooong name',
  age => -10,
);

$person->validate;

is_deeply +{ $person->errors->to_hash(full_messages=>1) },{
  age => [
    "Age can't be lower than 5",
  ],
  name => [
    "Name is too long",
  ],
}; 

done_testing;
