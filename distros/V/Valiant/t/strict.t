use Test::Most;

{
  package Local::Test::Strict;

  use Moo;
  use Valiant::Validations;
  use Valiant::I18N;

  has age => (is=>'ro');
  has days => (is=>'ro');


  validates age => (
    numericality => {
      is_integer => 1,
      less_than => 200,
      strict => 1,
      allow_blank => 1,
    },
  );

  validates age => (
    Numericality => {
      is_integer => 1,
      greater_than_or_equal_to => 18,
    },
    strict => "Too Young",
    allow_undef => 1,
  );

  validates days => (
    numericality => {
      is_integer => 1,
      less_than => 2000,
      strict => \&oldold
    },
  );


  sub oldold {
    my ($self, $message) = @_;
    Test::Most::is($message, 'Days must be less than 2000');
    die 'oldold';
  }
}

{
  ok my $object = Local::Test::Strict->new(age=>1110);
  ok !eval { $object->validate };
  ok $@ =~m/^Age must be less than 200/;
}

{
  ok my $object = Local::Test::Strict->new(age=>11);
  ok !eval { $object->validate };
  ok $@ =~m/^Too Young/;
}

{
  ok my $object = Local::Test::Strict->new(days=>3000);
  ok !eval { $object->validate };
  ok $@ =~m/^oldold/;
}


done_testing;
