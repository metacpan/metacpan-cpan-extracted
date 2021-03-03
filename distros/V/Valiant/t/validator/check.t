use Test::Most;
use Test::Needs 'Types::Standard';

{
  package Local::Test::Check;

  use Moo;
  use Valiant::Validations;
  use Types::Standard 'Int';

  has retiree_age => (is=>'ro');
  has voting_age => (is=>'ro');
  has drinking_age => (is=>'ro');

  validates retiree_age => (
    check => {
      constraint => Int->where('$_ >= 65'),
      allow_undef => 1,
    }
  );

  validates voting_age => (
    check => Int->where('$_ >= 18'),
    allow_undef => 1,
  );

  validates drinking_age => (
    Int->where('$_ >= 21'), +{
      allow_undef => 1,
    },
    message => 'is too young to drink!',
  );
}

{
  ok my $object = Local::Test::Check->new(drinking_age=>80);
  ok $object->validate->valid;
}

{
  ok my $object = Local::Test::Check->new(drinking_age=>18);
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'drinking_age' => [
        'Drinking Age is too young to drink!'
      ] 
    };
}

{
  ok my $object = Local::Test::Check->new(retiree_age=>80);
  ok $object->validate->valid;
}

{
  ok my $object = Local::Test::Check->new(retiree_age=>40);
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'retiree_age' => [
                 'Retiree Age is invalid'
               ] 
    };
}

{
  ok my $object = Local::Test::Check->new(voting_age=>80);
  ok $object->validate->valid;
}

{
  ok my $object = Local::Test::Check->new(voting_age=>10);
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'voting_age' => [
                 'Voting Age is invalid'
               ] 
    };
}

done_testing;
