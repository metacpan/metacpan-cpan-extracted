use Test::Most;

{
  package Local::Simple;

  use Valiant::Validations;
  use Moo;

  has name => (is => 'ro');
  has age => (is => 'ro');

  validates_with sub {
    my ($self, $opts) = @_;
    $self->errors->add(name => "Name is too long") if length($self->name) > 20;
    $self->errors->add(age => "Age can't be negative") if $self->age < 1;

    Test::Most::is_deeply $opts, +{
      arg1 => 1,
      arg2 => 2,
    }, 'Options are properly merged';
  }, arg1=>1;
}

my $simple = Local::Simple->new(
  name => 'A waaaaay too looooong name',
  age => -10,
);

$simple->validate(arg2=>2);

ok !$simple->valid;
ok $simple->invalid;
is_deeply +{ $simple->errors->to_hash },{
  age => [
    "Age can't be negative",
  ],
  name => [
    "Name is too long",
  ],
}; 

{
  package Local::Simple2;

  use Valiant::Validations;
  use Moo;

  has name => (is => 'ro');
  has age => (is => 'ro');

  validates_with \&check_length, length_max => 20;
  validates_with \&check_age_lower_limit, min => 5;

  sub check_length {
    my ($self, $opts) = @_;
    $self->errors->add(name => "is too long", $opts) if length($self->name) > $opts->{length_max};
  }

  sub check_age_lower_limit {
    my ($self, $opts) = @_;
    $self->errors->add(age => "can't be lower than $opts->{min}", $opts) if $self->age < $opts->{min};
  }
}

my $simple2 = Local::Simple2->new(
  name => 'A waaay too loooong name',
  age => -10,
);

$simple2->validate;
$simple2->valid;     # FALSE
$simple2->invalid;   # TRUE

my %errors = $simple2->errors->to_hash(full_messages=>1);
is_deeply \%errors, +{
  age => [
    "Age can't be lower than 5",
  ],
  name => [
    "Name is too long",
  ],
};

{
  package Local::Simple3;

  use Valiant::Validations;
  use Moo;

  has name => (is => 'ro');
  has age => (is => 'ro');

  validates name => ( \&check_length => { length_max => 20 } );
  validates age => ( \&check_age_lower_limit => { min => 5 } );

  sub check_length {
    my ($self, $attribute, $value, $opts) = @_;
    $self->errors->add($attribute => "is too long", $opts) if length($value) > $opts->{length_max};
  }

  sub check_age_lower_limit {
    my ($self, $attribute, $value, $opts) = @_;
    $self->errors->add($attribute => "can't be lower than $opts->{min}", $opts) if $value < $opts->{min};
  }
}

my $simple3 = Local::Simple2->new(
  name => 'A waaay too loooong name',
  age => -10,
);

$simple3->validate;
$simple3->valid;     # FALSE
$simple3->invalid;   # TRUE

is_deeply +{ $simple3->errors->to_hash(full_messages=>1) }, +{
  age => [
    "Age can't be lower than 5",
  ],
  name => [
    "Name is too long",
  ],
};

done_testing;
