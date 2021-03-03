use Test::Most;

{
  package Local::Test::Unique;

  use Moo;
  use Valiant::Validations;

  has name => (is=>'ro');
  has email => (is=>'ro');
  has id => (is=>'ro');

  validates name => (
    unique => 1,
  );

  validates id => (
    unique => 1,
  );

  validates email => (
    unique => {
      unique_method => 'email_constraint',
      is_not_unique_msg => 'is chosen unwisely'
    }
  );

  sub email_constraint {
    my ($self, $attr, $value, $opts) = @_;
    Test::Most::is $attr, 'email', "$attr called correct method";
    return 0;
  }

  sub is_unique {
    my ($self, $attr, $value, $opts) = @_;
    Test::Most::is $attr, 'name', "$attr called correct method";
    return 0
  }

  sub id_is_unique {
    my ($self, $attr, $value, $opts) = @_;
    Test::Most::is $attr, 'id', "$attr called correct method";
    return 0
  }

}

{
  ok my $object = Local::Test::Unique->new(name=>'John', email=>'jjn1056@yahoo.com', id=>110);
  ok $object->validate->invalid; 
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'name' => [
        'Name chosen is not unique',
      ],
      'email' => [
        'Email is chosen unwisely',
      ],
      'id' => [
        'Id chosen is not unique',
      ]
    };
}

# We need the test count correct here to make sure the test hit inside
# the test class are actually getting hit.
done_testing(6);

