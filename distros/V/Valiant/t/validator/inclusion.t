use Test::Most;

{
  package Local::Test::Inclusion;

  use Moo;
  use Valiant::Validations;

  has status => (is=>'ro');
  has type => (is=>'ro');

  validates status => (
    inclusion => +{
      in => [qw/active retired/],
    },
  );

  validates type => (
    inclusion => +{
      in => \&available_types,
    },
  );

  sub available_types {
    my $self = shift;
    return (qw(student instructor));
  }
}

ok my $object = Local::Test::Inclusion->new(
  status => 'running',
  type => 'janitor',
);

ok $object->validate->invalid;

is_deeply +{ $object->errors->to_hash(full_messages=>1) },
  {
    'status' => [
                  'Status is not in the list'
                ],
    'type' => [
                'Type is not in the list'
              ]
  };

done_testing;
