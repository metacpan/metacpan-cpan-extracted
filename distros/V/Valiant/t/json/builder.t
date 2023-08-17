use Test::Most;
use Valiant::JSON::JSONBuilder;

{
  package Local::Test::User;

  use Moo;
  use Valiant::Validations;

  has username => (is=>'ro');
  has active => (is=>'ro');
  has exclude1 => (is=>'ro');
  has exclude2 => (is=>'ro');
  has exclude3 => (is=>'ro', predicate=>1);
  has profile => (is=>'ro', default=>sub { Local::Test::Profile->new });
  has times => (is=>'ro');

  package Local::Test::Profile;

  use Moo;
  use Valiant::Validations;

  has age => (is=>'ro');
  has name => (is=>'ro');
  has email => (is=>'ro'); 

  package Local::Test::Profile::Email;

  use Moo;
  use Valiant::Validations;

  has address => (is=>'ro');
}

my $user = Local::Test::User->new(
  username=>'bob',
  active=>1,
  exclude1=>undef,
  exclude2=>undef,
  times => 10,
  profile=>Local::Test::Profile->new(
    age=>40,
    name=>'John',
    email=>[
      Local::Test::Profile::Email->new(address=>'test@test.com'),
      Local::Test::Profile::Email->new(address=>'test2@test.com'),
    ],
  ),
);  

my $jb = Valiant::JSON::JSONBuilder->new(model=>$user);

is_deeply $jb->render_perl, +{ local_test_user=>+{} };

is_deeply $jb->string('username', {name=>'user-name'})
  ->string('exclude1')
  ->string('exclude2', {omit_undef=>1})
  ->string('exclude3', {omit_empty=>1}) # omits when no value is present; requires predicate
  ->boolean('active')
  ->object('profile', sub {
    my ($jb, $profile) = @_;
    $jb->number('age')
      ->string('name')
      ->string('custom', 'custom_value')
      ->array('email', sub {
        my ($jb, $email) = @_;
        $jb->string('address')
      }),
  })->render_perl, +{
    local_test_user => {
      'user-name' => "bob",
      exclude1 => undef,
      active => 1,
      profile => {
        age => 40,
        name => 'John',
        custom => 'custom_value',
        email => [
            {
               "address" => 'test@test.com'
            },
            {
               "address" => 'test2@test.com'
            },
        ],
      },
    },
  };

# simple scalar

is_deeply $jb->reset
  ->string('username')
  ->render_perl, +{
    local_test_user => {
      username => "bob",
    },
  };

is_deeply $jb->reset
  ->string('username', {name=>'user-name'})
  ->render_perl, +{
    local_test_user => {
      'user-name' => "bob",
    },
  };

is_deeply $jb->reset
  ->string('username', sub {
    my ($jb, $username) = @_;
    return "username: $username";
  })
  ->render_perl, +{
    local_test_user => {
      username => "username: bob",
    },
  };

is_deeply $jb->reset
  ->string('username', {name=>'user-name'}, sub {
    my ($jb, $username) = @_;
    return "username: $username";
  })
  ->render_perl, +{
    local_test_user => {
      'user-name' => "username: bob",
    },
  };

is_deeply $jb->reset
  ->string('username', {name=>'user-name', omit_undef=>1}, sub {
    my ($jb, $username) = @_;
    return undef;
  })
  ->render_perl, +{
    local_test_user => {},
  };  

is_deeply $jb->reset
  ->string('username', { value=>undef, omit_undef=>1 })
  ->render_perl, +{local_test_user => {}};

is_deeply $jb->reset
  ->string('username', { value=>undef })
  ->render_perl, +{local_test_user => { username => undef }};

# custom value
is_deeply $jb->reset
  ->string('custom', 'custom_value')
  ->render_perl, +{
    local_test_user => {
      custom => "custom_value",
    },
  };

is_deeply $jb->reset
  ->string('custom', { value=>undef, omit_undef=>1 })
  ->render_perl, +{local_test_user => {}};
  
is_deeply $jb->reset
  ->string('custom', { value=>'custom2', name=>'custom-2', omit_undef=>1 })
  ->render_perl, +{local_test_user => { 'custom-2' => 'custom2' }};

is_deeply $jb->reset
  ->string('custom', { value=>'aaa', omit_undef=>1 }, sub { return 'bb'})
  ->render_perl, +{local_test_user => { 'custom' => 'bb' }};

is_deeply $jb->reset->number('times')->render_perl, +{local_test_user => { times => 10 }};
is_deeply $jb->reset->number('times', 0)->render_perl, +{local_test_user => { times => 0 }};
is_deeply $jb->reset
  ->number('times', {value=>undef, omit_undef=>1})
  ->render_perl, +{
    local_test_user => {}
  };

is_deeply $jb->reset->number('times', {value=>undef, omit_undef=>1}, sub { return 1 })->render_perl, +{local_test_user => { times => 1 }};
is_deeply $jb->reset->number('times', {value=>undef, omit_undef=>1}, sub { return undef })->render_perl, +{local_test_user => {}};
is_deeply $jb->reset->number('times', {value=>11, omit_undef=>1}, sub { return pop()+1 })->render_perl, +{local_test_user => { times => 12 }};

is_deeply $jb->reset->boolean('active')->render_perl, +{local_test_user => { active=>1 }};
is_deeply $jb->reset->boolean('active', {value=>0})->render_perl, +{local_test_user => { active=>0 }};

# boolean considers undef to be JSON null unless you say to coerce it to false
is_deeply $jb->reset->boolean('active', {value=>undef, omit_undef=>1})->render_perl, +{local_test_user => {}};
is_deeply $jb->reset->boolean('active', {value=>undef})->render_perl, +{local_test_user => {active=>undef}};
is_deeply $jb->reset->boolean('active', {value=>undef, coerce_undef=>1})->render_perl, +{local_test_user => {active=>0}};

is_deeply $jb->reset->object('profile', sub {
    my ($jb, $profile) = @_;
    return $jb->number('age')
      ->string('name');
  })->render_perl, +{
    local_test_user => {
      profile => {
        age => 40,
        name => 'John',
      },
    },
  };

is_deeply $jb->reset->object('profile', {namespace=>'pro-file'}, sub {
    my ($jb, $profile) = @_;
    return $jb->number('age')
      ->string('name');
  })->render_perl, +{
    local_test_user => {
      'pro-file' => {
        age => 40,
        name => 'John',
      },
    },
  };

is_deeply $jb->reset->object('profile', {namespace=>'pro-file'}, sub {
    my ($jb, $profile) = @_;
    return $jb->number('age',  {value=>undef, omit_undef=>1})
      ->string('name',  {value=>undef, omit_undef=>1});
  })->render_perl, +{
    local_test_user => {
      'pro-file' => {},
    },
  };

is_deeply $jb->reset->object('profile', {namespace=>'pro-file', omit_empty=>1}, sub {
    my ($jb, $profile) = @_;
    return $jb->number('age',  {value=>undef, omit_undef=>1})
      ->string('name',  {value=>undef, omit_undef=>1});
  })->render_perl, +{
    local_test_user => { },
  };

my $profile2 = Local::Test::Profile->new(age=>42, name=>'Joe'); 
is_deeply $jb->reset->object($profile2, sub {
    my ($jb, $profile) = @_;
    return $jb->number('age')
      ->string('name');
  })->render_perl, +{
  local_test_user => {
    local_test_profile => {
      age => 42,
      name => "Joe",
    },
  },
};

is_deeply $jb->reset->object($profile2, +{namespace=>'profile'}, sub {
    my ($jb, $profile) = @_;
    return $jb->number('age')
      ->string('name');
  })->render_perl, +{
  local_test_user => {
    profile => {
      age => 42,
      name => "Joe",
    },
  },
};

is_deeply $jb->reset
  ->object('profile', sub {
    my ($jb, $profile) = @_;
    return $jb->array('email', sub {
      my ($jb, $email) = @_;
      return $jb->string('address');
    });
  })->render_perl, +{
    local_test_user => {
      profile => {
      email => [
        {
          address => "test\@test.com",
        },
        {
          address => "test2\@test.com",
        },
      ],
    },
  },
};

is_deeply $jb->reset
  ->object('profile', sub {
    my ($jb, $profile) = @_;
    return $jb->array('email', {namespace=>'email-addresses'}, sub {
      my ($jb, $email) = @_;
      return $jb->string('address');
    });
  })->render_perl, +{
    local_test_user => {
      profile => {
      'email-addresses' => [
        {
          address => "test\@test.com",
        },
        {
          address => "test2\@test.com",
        },
      ],
    },
  },
};

is_deeply $jb->reset
  ->object('profile', sub {
    my ($jb, $profile) = @_;
    return $jb->array('email', {namespace=>'email-addresses'}, sub {
      my ($jb, $email) = @_;
      return $jb->string('address', {value=>undef, omit_undef=>1});
    });
  })->render_perl, +{
    local_test_user => {
      profile => {
      'email-addresses' => [],
    },
  },
};

is_deeply $jb->reset
  ->object('profile', sub {
    my ($jb, $profile) = @_;
    return $jb->array('email', {namespace=>'email-addresses', omit_empty=>1}, sub {
      my ($jb, $email) = @_;
      return $jb->string('address', {value=>undef, omit_undef=>1});
    });
  })->render_perl, +{
    local_test_user => {
      profile => {
    },
  },
};

is_deeply $jb->reset
  ->object('profile', {omit_empty=>1}, sub {
    my ($jb, $profile) = @_;
    return $jb->array('email', {namespace=>'email-addresses', omit_empty=>1}, sub {
      my ($jb, $email) = @_;
      return $jb->string('address', {value=>undef, omit_undef=>1});
    });
  })->render_perl, +{
    local_test_user => {},
  };

is_deeply $jb->reset->array([1,2,3], {namespace=>'items'}, sub {
    my ($jb, $item) = @_;
    return $jb->number(num=>$item)
  })->render_perl, +{
    local_test_user => {
      items => [
        {num=>1},
        {num=>2},
        {num=>3},
      ],
    },
  };

is_deeply $jb->reset->array([1,2,3], {namespace=>'items'}, sub {
    my ($jb, $item) = @_;
    return $jb->value($item);
  })->render_perl, +{
    local_test_user => {
      items => [1,2,3],
    },
  };

is_deeply $jb->reset->array([1,2,3], {namespace=>'items'}, sub {
    my ($jb, $item) = @_;
  })->render_perl, +{
    local_test_user => {
      items => [],
    },
  };

is_deeply $jb->reset->array([1,2,3], {namespace=>'items', omit_empty=>1}, sub {
    my ($jb, $item) = @_;
  })->render_perl, +{
    local_test_user => {},
  };

is_deeply $jb->reset->array([1,2,3], {namespace=>'items'}, sub {
    my ($jb, $item) = @_;
    return $item == 2 ? $jb->skip : $jb->value($item);
  })->render_perl, +{
    local_test_user => {
      items => [1,3],
    },
  };

is_deeply $jb->reset->if(1, sub {
    my ($jb) = @_;
    return $jb->number('num', {value=>1});
  })->render_perl, +{
    local_test_user => {
      num => 1,
    },
  };

is_deeply $jb->reset
  ->string('username')
  ->with_model($profile2, sub {
    my ($jb, $profile) = @_;
    return $jb->number('age')
      ->string('name');
  })->render_perl, +{
    local_test_user => {
      username => "bob",
      age => 42,
      name => "Joe",
    },
  };

done_testing;