use Test::Most;

{
  package Local::Object::User;

  use Valiant::Errors;
  use Valiant::I18N;
  use Moo;

  with 'Valiant::Naming';

  has 'errors' => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    default => sub { Valiant::Errors->new(object=>shift) },
  );

  sub validate {
    my $self = shift;
    $self->errors->add('test01', _t('testerror'), +{message=>'another test error1'});
    $self->errors->add('test01', _t('invalid') );
    $self->errors->add('test02', 'test error');
    $self->errors->add(undef, 'test model error');
  }

  sub read_attribute_for_validation {
    my $self = shift;
    return shift;
  }

  sub human_attribute_name {
    my ($self, $attribute) = @_;
    return $attribute;
  }

}

ok my $user1 = Local::Object::User->new;
ok my $user2 = Local::Object::User->new;

$user1->validate;
$user2->validate;

is_deeply +{ $user1->errors->to_hash }, +{
    "*" => [
      "test model error",
    ],
    test01 => [
      "another test error1",
      "Is Invalid",
    ],
    test02 => [
      "test error",
    ],
  };

is_deeply [ $user1->errors->model_messages ], [
  "test model error",
];

$user1->errors->merge($user2->errors);
is_deeply +{ $user1->errors->to_hash }, +{
    "*" => [
      "test model error",
      "test model error",
    ],
    test01 => [
      "another test error1",
      "Is Invalid",
      "another test error1",
      "Is Invalid",
    ],
    test02 => [
      "test error",
      "test error",
    ],
  };

ok $user1->errors->any(sub {
  ${\$_->type} eq 'invalid';
  });

ok ! $user1->errors->any(sub {
  ${\$_->type} eq 'indvalid';
  });

is_deeply [$user1->errors->full_messages_for('test01')], [
    "test01 another test error1",
    "test01 Is Invalid",
    "test01 another test error1",
    "test01 Is Invalid",
  ];


$user1->errors->delete('test01');
is_deeply +{ $user1->errors->to_hash }, +{
    "*" => [
      "test model error",
      "test model error",
    ],
    test02 => [
      "test error",
      "test error",
    ],
  };

ok $user2->errors->of_kind('test01', "Is Invalid");
ok ! $user2->errors->of_kind('test0x', "Is Invalid");

is_deeply [$user2->errors->full_messages], [
    "test01 another test error1",
    "test01 Is Invalid",
    "test02 test error",
    "test model error",
  ];

{
  package Local::MessageRetrieval;

  use Moo;
  use Valiant::Validations;

  has [qw/name age email password/] => (is=>'ro');
}

my $model = Local::MessageRetrieval->new;

$model->errors->add(undef, "Your Form is invalid");
$model->errors->add(name => "is too short");
$model->errors->add(name => "has disallowed characters");
$model->errors->add(age => "must be above 5");
$model->errors->add(email => "does not look like an email address");
$model->errors->add(password => "is too short");
$model->errors->add(password => "can't look like your name");
$model->errors->add(password => "needs to contain both numbers and letters");

ok $model->invalid;

is_deeply [$model->errors->messages], [
  "Your Form is invalid",
  "is too short",
  "has disallowed characters",
  "must be above 5",
  "does not look like an email address",
  "is too short",
  "can't look like your name",
  "needs to contain both numbers and letters",
];

is_deeply [$model->errors->full_messages], [
  "Your Form is invalid",
  "Name is too short",
  "Name has disallowed characters",
  "Age must be above 5",
  "Email does not look like an email address",
  "Password is too short",
  "Password can't look like your name",
  "Password needs to contain both numbers and letters",
];

is_deeply [$model->errors->model_messages], [
  "Your Form is invalid",
];

is_deeply [$model->errors->attribute_messages], [
  "is too short",
  "has disallowed characters",
  "must be above 5",
  "does not look like an email address",
  "is too short",
  "can't look like your name",
  "needs to contain both numbers and letters",
];

is_deeply [$model->errors->full_attribute_messages], [
  "Name is too short",
  "Name has disallowed characters",
  "Age must be above 5",
  "Email does not look like an email address",
  "Password is too short",
  "Password can't look like your name",
  "Password needs to contain both numbers and letters",
];

is_deeply +{ $model->errors->to_hash }, {
  "*" => [
    "Your Form is invalid",
  ],
  age => [
    "must be above 5",
  ],
  email => [
    "does not look like an email address",
  ],
  name => [
    "is too short",
    "has disallowed characters",
  ],
  password => [
    "is too short",
    "can't look like your name",
    "needs to contain both numbers and letters",
  ],
};

is_deeply +{ $model->errors->to_hash(full_messages=>1) }, {
  "*" => [
    "Your Form is invalid",
  ],
  age => [
    "Age must be above 5",
  ],
  email => [
    "Email does not look like an email address",
  ],
  name => [
    "Name is too short",
    "Name has disallowed characters",
  ],
  password => [
    "Password is too short",
    "Password can't look like your name",
    "Password needs to contain both numbers and letters",
  ],
};

is_deeply [$model->errors->full_messages_for('password')], [
    "Password is too short",
    "Password can't look like your name",
    "Password needs to contain both numbers and letters",
  ];

is_deeply [$model->errors->messages_for('password')], [
    "is too short",
    "can't look like your name",
    "needs to contain both numbers and letters",
  ];

{
    package MyApp::Errors;

    use Moo;
    use Valiant::Validations;

    has name => (is=>'ro');

    validates name => (
      with => {
        cb => sub {
          my ($self, $attr, $value, $opts) = @_;
          $self->errors->add($attr, 'is always in error!', $opts);
        },
        message => 'has wrong value',
      },
      message => 'has some sort of error',
    );
}

my $errors = MyApp::Errors->new;

ok $errors->invalid;

is_deeply [$errors->errors->full_messages ], ["Name has wrong value"];

ok my $clone = $errors->errors->errors->get(0)->clone;

$errors->errors->copy($model->errors);

is_deeply [$errors->errors->full_attribute_messages], [
  "Name is too short",
  "Name has disallowed characters",
  "Age must be above 5",
  "Email does not look like an email address",
  "Password is too short",
  "Password can't look like your name",
  "Password needs to contain both numbers and letters",
];

$errors->errors->import_error($clone);

is_deeply [$errors->errors->full_attribute_messages], [
  "Name is too short",
  "Name has disallowed characters",
  "Age must be above 5",
  "Email does not look like an email address",
  "Password is too short",
  "Password can't look like your name",
  "Password needs to contain both numbers and letters",
  "Name has wrong value",
];

my @results = map { $_->full_message } $errors->errors->where('name');
is_deeply \@results, [
  "Name is too short",
  "Name has disallowed characters",
  "Name has wrong value",
];

done_testing;
