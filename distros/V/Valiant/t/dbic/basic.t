use Test::Most;
use Test::Lib;
use DateTime;
use Test::DBIx::Class
  -schema_class => 'Example::Schema';

ok my $state = Schema
  ->resultset('State')
  ->create({name=>'Texas', abbreviation=>'TX'});
ok $state->valid;
ok $state->id;

{
  # Basic create test.
  ok my $person = Schema
    ->resultset('Person')
    ->create({
      __context => 'registration',
      username => 'jjn',
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'abc123',
    }), 'created fixture';

  ok $person->invalid, 'attempted record invalid';
  ok !$person->in_storage, 'record was not saved';

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    password => [
      "Password is too short (minimum is 8 characters)",
    ],
    password_confirmation => [
      "Password Confirmation doesn't match 'Password'",
    ],
  }, 'Got expected errors';
}

{
  # Basic update test.
  ok my $person = Schema
    ->resultset('Person')
    ->create({
      __context => ['registration'],
      username => 'jjn',
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'abc123aaaaaa',
      password_confirmation => 'abc123aaaaaa',
    }), 'created fixture';

  ok $person->valid, 'attempted record valid';
  ok $person->in_storage, 'record was saved';

  $person->password('aaa');
  $person->update({last_name=>'1', __context => 'registration'});

  ok $person->invalid, 'attempted record invalid with context';

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    last_name => [
      "Last Name is too short (minimum is 2 characters)",
    ],
    password => [
      "Password is too short (minimum is 8 characters)",
    ],
    password_confirmation => [
      "Password Confirmation doesn't match 'Password'",
    ],
  }, 'Got expected errors';

  $person->discard_changes;
  ok $person->password eq 'abc123aaaaaa', 'original not altered';

  # Make sure real updates are not blocked
  $person->password('890xyzgreen59');
  $person->password_confirmation('890xyzgreen59');

  $person->update({ __context => 'registration'});

  ok $person->valid, 'attempted record valid';
  ok $person->in_storage, 'saved';

  # This is maybe a TODO since DBIC won't pass the non field confirmation via
  # update args
  #$person->password('890xyzgreen59123');
  #$person->update({
  #    password_confirmation => '890xyzgreen59123', 
  #    __context => 'registration'
  #});

  #ok $person->valid, 'attempted record valid';
  #ok $person->in_storage, 'saved';
}

{
  # Basic multicreate test. (might have /has one)
  ok my $person = Schema
    ->resultset('Person')
    ->create({
      __context => ['registration','profile'],
      username => 'jjn2',
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'abc123',
      password_confirmation => 'abc123',
      profile => {
        zip => "78621",
        city => 'Elgin',
      },
      credit_cards => [
        {card_number=>'asdasd', expiration=>'ddw'},
      ],
    }), 'created fixture';

  is $person->model_name->param_key, 'person';
  is $person->profile->model_name->param_key, 'profile';

  ok $person->invalid, 'attempted record invalid multi context';
  ok !$person->in_storage, 'record was not saved';

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    credit_cards => [
      "Credit Cards has too few rows (minimum is 2)",
      "Credit Cards Is Invalid",
    ],
    "credit_cards.0.card_number" => [
      "Credit Cards Card Number is too short (minimum is 13 characters)",
      "Credit Cards Card Number does not look like a credit card",
    ],
    "credit_cards.0.expiration" => [
      "Credit Cards Expiration does not look like a datetime value",
    ],
    password => [
      "Password is too short (minimum is 8 characters)",
    ],
    profile => [
      "Profile Is Invalid",
    ],
    "profile.address" => [
      "Profile Address can't be blank",
      "Profile Address is too short (minimum is 2 characters)",
    ],
    "profile.birthday" => [
      "Profile Birthday doesn't look like a date",
    ],
    "profile.phone_number" => [
      "Profile Phone Number can't be blank",
      "Profile Phone Number is too short (minimum is 10 characters)",
    ],
    "profile.state_id" => [
      "Profile State can't be blank",
    ],
  }, 'Got expected errors';

  ok $person->profile->invalid, 'attempted profile was invalid';
  ok !$person->profile->in_storage, 'record was not saved';
  is_deeply +{$person->profile->errors->to_hash(full_messages=>1)}, +{
    address => [
      "Address can't be blank",
      "Address is too short (minimum is 2 characters)",
    ],
    birthday => [
      "Birthday doesn't look like a date",
    ],
    phone_number => [
      "Phone Number can't be blank",
      "Phone Number is too short (minimum is 10 characters)",
    ],
    state_id => [
      "State can't be blank",
    ],
  }, 'Got expected errors';

  ok $person->credit_cards->first->invalid, 'attempted profile was invalid';
  ok !$person->credit_cards->first->in_storage, 'record was not saved';
  is_deeply +{$person->credit_cards->first->errors->to_hash(full_messages=>1)}, +{
    card_number => [
      "Card Number is too short (minimum is 13 characters)",
      "Card Number does not look like a credit card",
    ],
    expiration => [
      "Expiration does not look like a datetime value",
    ],
  }, 'Got expected errors';

  # Ok not do a 'good' one with no errors and lets make sure it all
  # get stuck in the DB correctly.
  ok my $person_correct = Schema
    ->resultset('Person')
    ->create({
      __context => ['registration','profile'],
      username => 'jjn3',
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'abc123rrrrrr',
      password_confirmation => 'abc123rrrrrr',
      profile => {
        zip => "78621",
        city => 'Elgin',
        address => '15604 Harry Lind Road',
        birthday => DateTime->now->subtract(years=>15)->ymd,
        phone_number => '2123879509',
        state_id => $state->id,
      },
      credit_cards => [
        {card_number=>'11111222223333344444', expiration=>'2100-01-01'},
        {card_number=>'11111222223333555555', expiration=>'2101-01-01'},
      ],
    }), 'created fixture';

  ok $person_correct->valid, 'attempted record valid';
  ok $person_correct->in_storage, 'record was saved';
  ok $person_correct->profile->valid, 'attempted profile was valid';
  ok $person_correct->profile->in_storage, 'record was saved';

  ok my @credit_cards = $person_correct->credit_cards->all;
  is scalar(@credit_cards), '2', 'correct number of rows';
  ok $credit_cards[0]->valid, 'attempted profile was valid';
  ok $credit_cards[0]->in_storage, 'record was saved';
  ok $credit_cards[1]->valid, 'attempted profile was valid';
  ok $credit_cards[1]->in_storage, 'record was saved';
}

{
  # Test mulicreate with objects
  # What happens when you try to add a related object that

  ok my $profile = Schema
    ->resultset('Profile')
    ->new_result({
      zip => "78621",
      city => 'Elgin',
      address => '15604 Harry Lind Road',
      birthday => DateTime->now->subtract(years=>15)->ymd,
      phone_number => '2123879509',
      state_id => $state->id,
    }), 'created profile';

  ok $profile->valid, 'attempted profile was valid';
  ok ! $profile->in_storage, 'record has not been saved';

  ok my $cc_1 = Schema
    ->resultset('CreditCard')
    ->new_result({
      card_number => '11111222223333344444',
      expiration => '2100-01-01'
    }), 'created credit card one';

  ok $cc_1->valid, 'attempted cc was valid';
  ok ! $cc_1->in_storage, 'record has not been saved';

  ok my $cc_2 = Schema
    ->resultset('CreditCard')
    ->new_result({
      card_number => '1111122222333334466',
      expiration => '2200-01-01'
    }), 'created credit card two';

  ok my $cc_invalid = Schema
    ->resultset('CreditCard')
    ->new_result({
      card_number => '1111122222333334466',
      expiration => '1200-01-01'
    }), 'created credit card two';


  ok $cc_2->valid, 'attempted cc was valid';
  ok ! $cc_2->in_storage, 'record has not been saved 3';

  ok my $person_correct = Schema
    ->resultset('Person')
    ->create({
      __context => ['registration','profile'],
      username => 'jjn4',
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'abc123rrrrrr',
      password_confirmation => 'abc123rrrrrr',
      profile => $profile,
      credit_cards => [ $cc_1, $cc_2 ],
    }), 'created person';

  ok $person_correct->valid, 'attempted record was valid';
  ok $person_correct->in_storage, 'record has been saved';

  ok my $person_invalid = Schema
    ->resultset('Person')
    ->create({
      __context => ['registration','profile'],
      username => 'jjn4',
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'abc123rrrrrr',
      password_confirmation => 'abc123rrrrrr',
      profile => $profile,
      credit_cards => [ $cc_1, $cc_invalid ],
    }), 'created person';

  ok $person_invalid->invalid, 'attempted record was valid';
  ok ! $person_invalid->in_storage, 'record has not been saved 4';

  is scalar($person_invalid->credit_cards->all), 2;

  is_deeply +{$person_invalid->errors->to_hash(full_messages=>1)}, +{
    credit_cards => [
      "Credit Cards Is Invalid",
    ],
    "credit_cards.1.expiration" => [
      "Credit Cards Expiration must be in the future",
    ],
    username => [
      "Username chosen is not unique",
    ],
  }, 'Got expected errors';

  ok my @credit_cards = $person_invalid->credit_cards->all;
  is_deeply +{$credit_cards[1]->errors->to_hash(full_messages=>1)}, +{
    expiration => [
      "Expiration must be in the future",
    ],
  }, 'Got expected errors';
}

{
  # update deeply
  ok my $person = Schema
    ->resultset('Person')
    ->create({
      __context => ['registration'],
      username => 'jjn5',
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'abc123aaaaaa',
      password_confirmation => 'abc123aaaaaa',
    }), 'created fixture';

  ok $person->valid, 'attempted record valid';
  ok $person->in_storage, 'record was saved';

  $person->update({
    __context => ['registration','profile'],
    last_name => 'a',
    profile => {
      birthday => '2991-01-23',
      zip => '78621',
    },
  });

  my $yesterday = DateTime->now->subtract(days=>2);

  ok $person->invalid, 'attempted record was invalid';
  ok $person->is_changed, 'record has unsaved changes';
  is $person->last_name, 'a', 'got correct last_name';
  
  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    last_name => [
      "Last Name is too short (minimum is 2 characters)",
    ],
    profile => [
      "Profile Is Invalid",
    ],
    "profile.address" => [
      "Profile Address can't be blank",
      "Profile Address is too short (minimum is 2 characters)",
    ],
    "profile.birthday" => [
      "Profile Birthday chosen date can't be later than @{[ $yesterday->ymd ]}",
    ],
    "profile.city" => [
      "Profile City can't be blank",
      "Profile City is too short (minimum is 2 characters)",
    ],
    "profile.phone_number" => [
      "Profile Phone Number can't be blank",
      "Profile Phone Number is too short (minimum is 10 characters)",
    ],
    "profile.state_id" => [
      "Profile State can't be blank",
    ],
  };

  ok $person->profile->invalid, 'attempted record was invalid';
  ok ! $person->profile->in_storage, 'record not yet stored';

  is_deeply +{$person->profile->errors->to_hash(full_messages=>1)}, +{
    address => [
      "Address can't be blank",
      "Address is too short (minimum is 2 characters)",
    ],
    birthday => [
      "Birthday chosen date can't be later than @{[ DateTime->now->subtract(days=>2)->ymd ]}",
    ],
    city => [
      "City can't be blank",
      "City is too short (minimum is 2 characters)",
    ],
    phone_number => [
      "Phone Number can't be blank",
      "Phone Number is too short (minimum is 10 characters)",
    ],
    state_id => [
      "State can't be blank",
    ],
  }, 'Got expected errors';

  $person->update({
    __context => ['registration','profile'],
    last_name => 'abcdefghi',
    profile => {
      zip => "78621",
      city => 'Elgin',
      address => '15604 Harry Lind Road',
      birthday => DateTime->now->subtract(years=>15)->ymd,
      phone_number => '2123879509',
      state_id => $state->id,
    },
  });

  ok $person->valid, 'attempted record was valid';
  ok ! $person->is_changed, 'record has no unsaved changes';
  ok $person->in_storage, 'record stored';

  ok $person->profile->valid;
  is $person->profile->city, 'Elgin';
  ok $person->profile->in_storage, 'Profile stored';

  {
    my $person_profile = Schema->resultset('Person')
      ->find({username=>'jjn5'}, {prefetch=>'profile'});

    ok $person_profile->profile->zip;
    ok $person_profile->first_name;

    $person_profile->first_name('f');
    $person_profile->update({
        __context => ['profile']
    });

    ok $person_profile->invalid;

    is_deeply +{$person_profile->errors->to_hash(full_messages=>1)}, +{
      first_name => [
        "First Name is too short (minimum is 2 characters)",
      ],
    };

    #$person_profile->discard_changes;

    $person_profile->last_name('f');
    $person_profile->profile->zip('dd');
    $person_profile->update({
        __context => ['profile']
    });

    ok $person_profile->invalid;
    ok $person_profile->is_changed;
    is $person_profile->last_name, 'f';

    is_deeply +{$person_profile->errors->to_hash(full_messages=>1)}, +{
      first_name => [
        "First Name is too short (minimum is 2 characters)",
      ],
      last_name => [
        "Last Name is too short (minimum is 2 characters)",
      ],
      profile => [
        "Profile Is Invalid",
      ],
      "profile.zip" => [
        "Profile Zip is not a zip code",
      ],
    };

    ok $person_profile->profile->invalid;
    ok $person_profile->profile->is_changed;
    is $person_profile->profile->zip, 'dd';

    is_deeply +{$person_profile->profile->errors->to_hash(full_messages=>1)}, +{
      zip => [
        "Zip is not a zip code",
      ],
    };

    is $person_profile->profile->city, 'Elgin';

    $person_profile->update({
        __context => ['profile'],
        first_name => 'joe',
        last_name => 'nobody',
        profile => {
          zip => '88888',
          city => 'New York',
        },
    });

    is_deeply +{ $person_profile->get_columns }, {
      first_name => "joe",
      id => $person_profile->id,
      last_name => "nobody",
      password => "abc123aaaaaa",
      username => "jjn5",
    };

    is_deeply +{ $person_profile->profile->get_columns }, {
      address => "15604 Harry Lind Road",
      birthday => DateTime->now->subtract(years=>15)->ymd,    # This will probably heisenfail at midnight Dec 31...
      city => "New York",
      id => $person_profile->profile->id,
      person_id => $person_profile->id,
      phone_number => "2123879509",
      state_id => $state->id,
      zip => 88888,
    };

    ok $person_profile->valid;
    ok $person_profile->in_storage;
    ok $person_profile->profile->valid;
    ok $person_profile->profile->in_storage;
  }
}

{
  ok my $person = Schema
    ->resultset('Person')
    ->create({
      __context => ['registration'],
      username => 'jjn6',
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'abc123aaaaaa',
      password_confirmation => 'abc123aaaaaa',
    }), 'created fixture';

  ok $person->valid, 'attempted record valid';
  ok $person->in_storage, 'record was saved';

  $person->update({
    first_name => 'a',
    credit_cards => [
      {card_number=>'asdasd', expiration=>'ddw'},
      {card_number=>'0000111122223333', expiration=>'2122-01-01'},
    ],
  });

  ok $person->invalid, 'attempted record invalid 3';
  ok $person->is_changed, 'record has unsaved changes';
  is scalar($person->credit_cards->all), 2;

  is_deeply +{ $person->errors->to_hash }, +{
    credit_cards => [
      "Is Invalid",
    ],
    "credit_cards.0.card_number" => [
      "is too short (minimum is 13 characters)",
      "does not look like a credit card",
    ],
    "credit_cards.0.expiration" => [
      "does not look like a datetime value",
    ],
    first_name => [
      "is too short (minimum is 2 characters)",
    ],
  };

  ok my @ccs = $person->credit_cards->all;
  is scalar(@ccs), 2;
  is_deeply +{ $ccs[0]->errors->to_hash }, +{
    card_number => [
      "is too short (minimum is 13 characters)",
      "does not look like a credit card",
    ],
    expiration => [
      "does not look like a datetime value",
    ],    
  };

  ok $ccs[1]->valid;

  is_deeply +{ $person->get_columns }, +{
    username => 'jjn6',
    first_name => 'a',
    last_name => 'napiorkowski',
    password => 'abc123aaaaaa',
    id => $person->id,
  };
  is_deeply +{ $ccs[0]->get_columns }, +{
    card_number => 'asdasd',
    expiration => 'ddw',
    person_id => $person->id,
  };
  is_deeply +{ $ccs[1]->get_columns }, +{
    card_number => '0000111122223333',
    expiration => '2122-01-01',   
    person_id => $person->id,
  };

  {
    $person->update({
      first_name => 'aaaaaaaaa',
      credit_cards => [
        {card_number=>'0000111122224444', expiration=>'2222-01-01'},
        {card_number=>'0000111122223333', expiration=>'2122-01-01'},
      ],
    });

    ok $person->valid;
    ok !$person->is_changed, 'no unsaved changes';
    ok my @ccs = $person->credit_cards->all;
    ok $ccs[0]->valid;
    ok $ccs[1]->valid;
    ok !$ccs[0]->is_changed, 'no unsaved changes';;
    ok !$ccs[1]->is_changed, 'no unsaved changes';;

    is_deeply +{ $person->get_columns }, +{
      first_name => "aaaaaaaaa",
      id => $person->id,
      last_name => "napiorkowski",
      password => "abc123aaaaaa",
      username => "jjn6",
    };
    is_deeply +{ $ccs[0]->get_columns }, +{
      card_number => "0000111122224444",
      expiration => "2222-01-01",
      id => $ccs[0]->id,
      person_id => $person->id,
    };
    is_deeply +{ $ccs[1]->get_columns }, +{
      card_number => "0000111122223333",
      expiration => "2122-01-01",
      id => $ccs[1]->id,
      person_id => $person->id,
    };
  }
}

{
  # just a test to inflate empties (you needs these for forms
  # when the form has not bee processed yet.

  ok my $p = Schema->resultset('Person')
    ->find_or_new({});

  $p->validate;
  is_deeply +{ $p->errors->to_hash }, +{
    first_name => [
      "can't be blank",
      "is too short (minimum is 2 characters)",
    ],
    last_name => [
      "can't be blank",
      "is too short (minimum is 2 characters)",
    ],
    password => [
      "can't be blank",
      "is too short (minimum is 8 characters)",
    ],
    username => [
      "can't be blank",
      "is too short (minimum is 3 characters)",
      "must contain only alphabetic and number characters",
    ],   
  };

  $p->errors->clear;
  is_deeply +{ $p->errors->to_hash }, +{};

  $p->profile(Schema->resultset('Profile')->find_or_new({}));
  $p->validate(context=>'profile');

  is_deeply +{ $p->errors->to_hash }, +{
    first_name => [
      "can't be blank",
      "is too short (minimum is 2 characters)",
    ],
    last_name => [
      "can't be blank",
      "is too short (minimum is 2 characters)",
    ],
    password => [
      "can't be blank",
      "is too short (minimum is 8 characters)",
    ],
    profile => [
      "Is Invalid",
    ],
    "profile.address" => [
      "can't be blank",
      "is too short (minimum is 2 characters)",
    ],
    "profile.birthday" => [
      "doesn't look like a date",
    ],
    "profile.city" => [
      "can't be blank",
      "is too short (minimum is 2 characters)",
    ],
    "profile.phone_number" => [
      "can't be blank",
      "is too short (minimum is 10 characters)",
    ],
    "profile.state_id" => [
      "can't be blank",
    ],
    "profile.zip" => [
      "can't be blank",
      "is not a zip code",
    ],
    username => [
      "can't be blank",
      "is too short (minimum is 3 characters)",
      "must contain only alphabetic and number characters",
    ],
  };

  is_deeply +{ $p->profile->errors->to_hash }, +{
    address => [
      "can't be blank",
      "is too short (minimum is 2 characters)",
    ],
    birthday => [
      "doesn't look like a date",
    ],
    city => [
      "can't be blank",
      "is too short (minimum is 2 characters)",
    ],
    phone_number => [
      "can't be blank",
      "is too short (minimum is 10 characters)",
    ],
    state_id => [
      "can't be blank",
    ],
    zip => [
      "can't be blank",
      "is not a zip code",
    ],
  };
}

{
   eval {
    Schema
    ->resultset('Person')
    ->create({
      __context => ['registration','profile'],
      username => 'jjn3',
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'abc123rrrrrr',
      password_confirmation => 'abc123rrrrrr',
      profile => {
        zip => "78621",
        city => 'Elgin',
        address => '15604 Harry Lind Road',
        birthday => '1991-01-23',
        phone_number => '2123879509',
        state_id => $state->id,
      },
      credit_cards => [
        {card_number=>'11111222223333344444', expiration=>'2100-01-01'},
        {card_number=>'11111222223333555555', expiration=>'2101-01-01'},
        {card_number=>'11111222223333555555', expiration=>'2101-01-01'},

      ],
    });
    ok $@->isa('DBIx::Class::Valiant::Util::Exception::TooManyRows');
    ok $@=~/Relationship credit_cards on person can't create more that 2 rows; attempted 3/, 'expected error';
  };
}

#skip validation 
{
  # Basic update test.
  ok my $person = Schema
    ->resultset('Person')
    ->create({
      __context => ['registration'],
      username => 'jjn45',
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'abc123aaaaaa',
      password_confirmation => 'abc123aaaaaa',
    }), 'created fixture';

  ok $person->valid, 'attempted record valid';
  ok $person->in_storage, 'record was saved';

  $person->password('aaa');
  $person->skip_validate->update({last_name=>'1', __context => 'registration'});

  ok $person->valid;
}

{
  # Basic create test.
  ok my $person = Schema
    ->resultset('Person')
    ->skip_validate
    ->create({
      __context => 'registration',
      username => 'jjn11',
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'abc123',
    }), 'created fixture';

  ok $person->valid, 'attempted record valid';
  ok $person->in_storage, 'record was  saved';
}

# filters
{
  ok my $role = Schema->resultset('Role')->new_result({label=>"  Test "});
  is $role->label, 'test';
}

# auto_validation test

{
  # Basic create test.
  ok my $person = Schema
    ->resultset('Test')
    ->create({
      name => 'a',
    }), 'created fixture';

  ok $person->in_storage, 'record was  saved';
  ok $person->invalid, 'attempted record invalid';
  is_deeply +{ $person->errors->to_hash }, +{
    name => [
      "is too short (minimum is 2 characters)",
    ],
  };
}

{
  # This test makes sure we don't get a regression on the bug whree we accidentally
  # matched a related row via non unique parameters
  ok my $person = Schema
    ->resultset('Person')
    ->create({
      __context => ['registration','profile'],
      username => 'jsjn212',
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'abc123xxx',
      password_confirmation => 'abc123xxx',
      profile => {
        zip => "78621",
        city => 'Elgin',
        address => "12345 Main Street",
        birthday => '2000-01-01',
        state_id => 1,
        phone_number => '21238979509',
      },
      credit_cards => [
        {card_number=>'11111222223333344444', expiration=>'2100-01-01'},
        {card_number=>'11111222223333555555', expiration=>'2101-01-01'},
      ],
    }), 'created fixture';

  ok $person->valid;
}

{
  my $person = Schema
    ->resultset('Person')
    ->new_result(+{});

  ok !$person->errors->size;

  $person->set_columns_recursively({
      username => 'jsjn212',
      first_name => 'john',
      last_name => 'napiorkowski',
      profile => {
        zip => "78621",
        city => 'Elgin',
      },
    });

  ok !$person->errors->size;

  $person->insert;

  is_deeply +{ $person->errors->to_hash }, +{
    password => [
      "can't be blank",
      "is too short (minimum is 8 characters)",
    ],
    profile => [
      "Is Invalid",
    ],
    "profile.address" => [
      "can't be blank",
      "is too short (minimum is 2 characters)",
    ],
    "profile.birthday" => [
      "doesn't look like a date",
    ],
    "profile.phone_number" => [
      "can't be blank",
      "is too short (minimum is 10 characters)",
    ],
    "profile.state_id" => [
      "can't be blank",
    ],
    username => [
      "chosen is not unique",
    ],
  };
}

done_testing;
