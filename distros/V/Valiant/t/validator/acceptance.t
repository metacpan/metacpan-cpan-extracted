use Test::Most;

{
  package Local::Test::Acceptance;

  use Moo;
  use Valiant::Validations;

  has agree_to_terms => (is=>'ro');
  has newsletter => (is=>'ro');

  validates agree_to_terms => ( acceptance => 1 );
  validates newsletter => ( acceptance => { accept => ['on'] } );
}

# default accept list: '1' / 'on' pass
{
  ok my $object = Local::Test::Acceptance->new(agree_to_terms => '1', newsletter => 'on');
  ok $object->validate->valid, 'accepted values pass';
}

# '0' fails the default acceptance
{
  ok my $object = Local::Test::Acceptance->new(agree_to_terms => '0', newsletter => 'on');
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      agree_to_terms => [ 'Agree To Terms must be accepted' ],
    };
}

# undef fails (acceptance requires a defined, accepted value)
{
  ok my $object = Local::Test::Acceptance->new(newsletter => 'on');
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      agree_to_terms => [ 'Agree To Terms must be accepted' ],
    };
}

# custom accept list: 'on' is the only accepted value, so '1' now fails
{
  ok my $object = Local::Test::Acceptance->new(agree_to_terms => 1, newsletter => '1');
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      newsletter => [ 'Newsletter must be accepted' ],
    };
}

done_testing;
