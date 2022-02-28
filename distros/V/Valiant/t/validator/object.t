use Test::Most;

{
  package Local::Test::TestRole;

  use Moo::Role;

  package Local::Test::Address;

  use Moo;
  use Valiant::Validations;

  with 'Local::Test::TestRole';

  has street => (is=>'ro');
  has city => (is=>'ro');
  has country => (is=>'ro');

  validates ['street', 'city'],
    presence => 1,
    length => [3, 40];

  validates 'country',
    presence => 1,
    inclusion => [qw/usa uk canada japan/];

  package Local::Test::Car;

  use Moo;
  use Valiant::Validations;

  has ['make', 'model', 'year'] => (is=>'ro');

  validates make => ( allow_blank => 1, inclusion => [qw/Toyota Tesla Ford/] );
  validates model => ( allow_blank => 1, length => [2, 20] );
  validates year => ( allow_blank => 1, numericality => { greater_than_or_equal_to => 1960 });

  package Local::Test::Person;

  use Moo;
  use Valiant::Validations;

  has name => (is=>'ro');
  has address => (is=>'ro');
  has car => (is=>'ro');

  validates name => (
    length => [2,30],
    format => qr/[A-Za-z]+/, #yes no unicode names for this test...
  );

  validates address => (
    presence => 1,
    object => {
      nested => 1,
      isa => 'Local::Test::Address',
      role => 'Local::Test::TestRole',
    }
  );

  validates address => (
    presence => 1,
    object => {
      isa => 'ISA',
      role => 'ROLE',
      on => 'check_isa_role',
    }
  );

  validates car => (
    object => 'nested',
    allow_blank => 1,
  );

  validates car => (
    with => sub {
      my ($self, $attribute_name, $value, $opts) = @_;
      $self->errors->add($attribute_name, 'ALWAYS FAIL');
    },
    allow_blank => 1,
  );

}

{
  my $address = Local::Test::Address->new(
    city => 'NYC',
    street => '15604 HL Drive',
    country => 'usa'
  );

  my $person = Local::Test::Person->new(
    name => 'john',
    address => $address,
  );

  ok $person->validate(context=>'check_isa_role')->invalid;

  is_deeply +{ $person->errors->to_hash(full_messages=>1) },
    {
      'address' => [
        "Address does not inherit from \"ISA\"",
        "Address does not provide the role \"ROLE\"",
      ],
    };
}

{
  # This is also testing 'allow_blank' for better or worse...

  my $address = Local::Test::Address->new(
    city => 'NYC',
    street => '15604 HL Drive',
    country => 'usa'
  );

  my $person = Local::Test::Person->new(
    name => 'john',
    address => $address,
  );

  ok $person->validate->valid;
}

{
  my $address = Local::Test::Address->new(
    city => 'NY',
    country => 'Russia'
  );

  my $person = Local::Test::Person->new(
    name => '12234',
    address => $address,
  );

  ok $person->validate->invalid;
  is_deeply +{ $person->errors->to_hash(full_messages=>1) },
    {
      address => [
        "Address Is Invalid",
      ],
      "address.city" => [
        "Address City is too short (minimum is 3 characters)",
      ],
      "address.country" => [
        "Address Country is not in the list",
      ],
      "address.street" => [
        "Address Street can't be blank",
        "Address Street is too short (minimum is 3 characters)",
      ],
      name => [
        "Name does not match the required pattern",
      ],
    };

  is_deeply +{ $person->address->errors->to_hash(full_messages=>1) },
    {
       'country' => [
                      'Country is not in the list'
                    ],
       'street' => [
                     'Street can\'t be blank',
                     'Street is too short (minimum is 3 characters)'
                   ],
       'city' => [
                   'City is too short (minimum is 3 characters)'
                 ]
    };

  ok $person->invalid;
  ok $person->address->invalid;
}

{
  my $address = Local::Test::Address->new(
    city => 'NY',
    country => 'Russia'
  );

  my $car = Local::Test::Car->new(
    make => 'Chevy',
    model => '1',
    year => 1900
  );

  my $person = Local::Test::Person->new(
    name => '12234',
    address => $address,
    car => $car,
  );

  ok $person->validate->invalid;

  ok $person->invalid;
  ok $person->address->invalid;
  ok $person->car->invalid;

  is_deeply +{ $person->errors->to_hash(full_messages=>1) },
    {
      address => [
        "Address Is Invalid",
      ],
      "address.city" => [
        "Address City is too short (minimum is 3 characters)",
      ],
      "address.country" => [
        "Address Country is not in the list",
      ],
      "address.street" => [
        "Address Street can't be blank",
        "Address Street is too short (minimum is 3 characters)",
      ],
      car => [
        "Car Is Invalid",
        "Car ALWAYS FAIL",
      ],
      "car.make" => [
        "Car Make is not in the list",
      ],
      "car.model" => [
        "Car Model is too short (minimum is 2 characters)",
      ],
      "car.year" => [
        "Car Year must be greater than or equal to 1960",
      ],
      name => [
        "Name does not match the required pattern",
      ],
    };

  is_deeply +{ $person->address->errors->to_hash(full_messages=>1) },
    {
       'street' => [
                     'Street can\'t be blank',
                     'Street is too short (minimum is 3 characters)'
                   ],
       'city' => [
                   'City is too short (minimum is 3 characters)'
                 ],
       'country' => [
                      'Country is not in the list'
                    ]
      };


  is_deeply +{ $person->car->errors->to_hash(1) },
    {
       'model' => [
                    'Model is too short (minimum is 2 characters)'
                  ],
       'year' => [
                   'Year must be greater than or equal to 1960'
                 ],
       'make' => [
                   'Make is not in the list'
                 ]
    };
}

done_testing;
