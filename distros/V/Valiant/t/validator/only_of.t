use Test::Most;

{
  package Local::Test::OnlyOf;

  use Moo;
  use Valiant::Validations;

  has opt1 => (is=>'ro');
  has opt2 => (is=>'ro');
  has opt3 => (is=>'ro');

  validates opt1 => ( only_of => ['opt2','opt3'] );

}

{
  ok my $object = Local::Test::OnlyOf->new(opt2=>'present');
  ok $object->validate->valid;
}

{
  ok my $object = Local::Test::OnlyOf->new(opt1=>'aaa', opt2=>'present');
  ok $object->validate->invalid;

  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
  {
    'opt1' => [
          'Opt1 please choose only 1 field'
        ]
  };
}

done_testing;
