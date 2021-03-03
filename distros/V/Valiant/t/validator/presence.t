use Test::Most;

{
  package Local::Test::Presence;

  use Moo;
  use Valiant::Validations;

  has name => (is=>'ro');

  validates name => ( presence => 1 );

}

ok my $object = Local::Test::Presence->new();
ok $object->validate->invalid; 
is_deeply +{ $object->errors->to_hash(full_messages=>1) },
  {
    'name' => [
      'Name can\'t be blank',
    ]
  };

done_testing;

__END__



