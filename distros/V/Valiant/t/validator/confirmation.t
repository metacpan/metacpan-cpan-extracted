use Test::Most;

{
  package Local::Test::Confirmation;

  use Moo;
  use Valiant::Validations;

  has 'email' => (is=>'ro');

  validates email => ( confirmation => 1 );
}

{
  ok my $object = Local::Test::Confirmation->new(
    email => 'AAA@example.com',
    email_confirmation => 'AAA@example.com'
  );

  ok $object->validate->valid;
  is $object->errors->size, 0;
}

{
  ok my $object = Local::Test::Confirmation->new(
    email => 'AAA@example.com',
    email_confirmation => 'ZZZ@example.com'
  );

  ok $object->validate->invalid;
  is $object->errors->size, 1;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'email_confirmation' => [
        "Email Confirmation doesn't match 'Email'",
      ]
    };
}

done_testing;
