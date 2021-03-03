use Test::Most;

{
  package Local::Test::Exclusion;

  use Moo;
  use Valiant::Validations;

  has domain => (is=>'ro');
  has country => (is=>'ro');

  validates domain => (
    exclusion => +{
      in => [qw/org co/],
    },
  );

  validates country => (
    exclusion => +{
      in => \&restricted,
    },
  );

  sub restricted {
    my $self = shift;
    return (qw(usa uk));
  }
}

ok my $object = Local::Test::Exclusion->new(
  domain => 'org',
  country => 'usa',
);

ok $object->validate->invalid;

is_deeply +{ $object->errors->to_hash(full_messages=>1) },
  {
    'country' => [
               'Country is reserved'
             ],
    'domain' => [
              'Domain is reserved'
            ] 
  };

done_testing;
