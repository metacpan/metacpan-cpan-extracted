use Test::Most;

{
  package Local::Test::Length;

  use Moo;
  use Valiant::Validations;

  has name => (is=>'ro');
  has equals => (is=>'ro', required=>1, default=>5);

  validates name => (
    length => {
      maximum => 10,
      minimum => 3,
      is => sub { shift->equals }, 
    }
  );

  validates name => (length => [4,9]);
}

{
  ok my $object = Local::Test::Length->new(name=>'Li');
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'name' => [
        'Name is too short (minimum is 3 characters)',
        'Name is the wrong length (should be 5 characters)',
        'Name is too short (minimum is 4 characters)'
      ]
    };
}

{
  # per-call options passed to ->validate must be threaded into Length errors
  ok my $object = Local::Test::Length->new(name=>'Li');
  $object->validate(foo => 'BAR');
  ok scalar(grep { ($_->options->{foo}||'') eq 'BAR' } $object->errors->errors->all),
    'per-call validate options reach Length errors';
}

done_testing;
