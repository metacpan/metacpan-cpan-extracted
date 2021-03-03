use Test::Most;

{
  package Local::Test::Boolean;

  use Moo;
  use Valiant::Validations;

  has active => (is=>'ro');
  has flag => (is=>'ro');

  validates active => (
    boolean => {
      state => 1,
    }
  );

  validates flag => (
    boolean => {
      state => 0,
    }
  );
}

{
  ok my $object = Local::Test::Boolean->new(active=>1, flag=>0);
  ok $object->validate->valid; 
}

{
  ok my $object = Local::Test::Boolean->new(active=>0, flag=>1);
  ok $object->validate->invalid; 
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'active' => [
        'Active must be a true value',
      ],
      'flag' => [
        'Flag must be a false value',
      ]

    };
}

done_testing;

