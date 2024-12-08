use Test::Most;
use DateTime;
use DateTime::Format::Strptime;
use Valiant::Validator::Date;

ok my %bad_date_args = (month=>2, year=>1969, day=>13);

{
  package Local::Test::Date;

  use Moo;
  use Valiant::Validations;

  has birthday => (is=>'ro');

  validates birthday => (
    date => {
      min => sub { pop->years_ago(120) }, # Oldest person I think...
      max => sub { pop->now },
      cb => \&my_special_method,
    },
  );

  sub my_special_method {
    my ($self, $name, $dt, $type, $opts) = @_;
    my $bad_date = $type->datetime(%bad_date_args);
    $self->errors->add($name, "Never John's Birthday!", $opts) if $dt eq $bad_date;
  }
}

ok my $min = DateTime->now->subtract(years=>120)->strftime($Valiant::Validator::Date::_pattern);
ok my $max = DateTime->now->strftime($Valiant::Validator::Date::_pattern);

{
  ok my $object = Local::Test::Date->new(birthday=>DateTime->now->subtract(years=>5));
  ok $object->validate->valid; 
}

{
  ok my $object = Local::Test::Date->new(birthday=>'bad date');
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'birthday' => [
        "Birthday doesn't look like a date",
      ],
    };
}

{
  ok my $object = Local::Test::Date->new(birthday=>DateTime->now->subtract(years=>500));
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'birthday' => [
        "Birthday chosen date can't be earlier than $min",
      ],
    };
}

{
  ok my $object = Local::Test::Date->new(birthday=>DateTime->now->add(years=>500));
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'birthday' => [
        "Birthday chosen date can't be later than $max",
      ],
    };
}

{
  ok my $object = Local::Test::Date->new(birthday=>DateTime->new(%bad_date_args));
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'birthday' => [
        "Birthday Never John's Birthday!",
      ],
    };
}

## Similar test cases but using max_eq and min_eq

{
  package Local::Test::Date2;

  use Moo;
  use Valiant::Validations;

  has birthday => (is=>'ro');

  validates birthday => (
    date => {
      min_eq => sub { pop->years_ago(120) }, # Oldest person I think...
      max_eq => sub { pop->now },
      cb => \&my_special_method,
    },
  );

  sub my_special_method {
    my ($self, $name, $dt, $type, $opts) = @_;
    my $bad_date = $type->datetime(%bad_date_args);
    $self->errors->add($name, "Never John's Birthday!", $opts) if $dt eq $bad_date;
  }
}

{
  ok my $object = Local::Test::Date2->new(birthday=>DateTime->now->subtract(years=>5));
  ok $object->validate->valid; 
}

{
  ok my $object = Local::Test::Date2->new(birthday=>'bad date');
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'birthday' => [
        "Birthday doesn't look like a date",
      ],
    };
}

{
  ok my $object = Local::Test::Date2->new(birthday=>DateTime->now->subtract(years=>500));
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'birthday' => [
        "Birthday chosen date can't be earlier than or equal to $min",
      ],
    };
}

{
  ok my $object = Local::Test::Date2->new(birthday=>DateTime->now->add(years=>500));
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'birthday' => [
        "Birthday chosen date can't be later than or equal to $max",
      ],
    };
}

{
  ok my $object = Local::Test::Date2->new(birthday=>DateTime->new(%bad_date_args));
  ok $object->validate->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'birthday' => [
        "Birthday Never John's Birthday!",
      ],
    };
}


done_testing;
