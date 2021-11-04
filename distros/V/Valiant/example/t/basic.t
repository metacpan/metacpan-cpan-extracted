use Test::Most;
use DateTime;
use Test::DBIx::Class
  -schema_class => 'Example::Schema';

{
  ok my $rs =  Schema
    ->resultset('State')
    ->skip_validate;

  ok $rs->skip_validation;
  ok my $state = $rs->create({name=>'Texas', abbreviation=>'TX'});
  ok $state->skip_validation;
  ok $state->in_storage;
}

{
  ok my $state = Schema
    ->resultset('State')
    ->skip_validate
    ->create({name=>'New York', abbreviation=>'NY'});
  ok $state->in_storage;
}

{
  Schema->resultset('Role')
    ->populate([
        { label=>'user'},
        { label=>'admin'},
        { label=>'superuser'},
        { label=>'guest'},
      ]);

  my @rows = Schema->resultset('Role')->all;
}

# First bit, check 'registration'.

my $pid;

REGISTRATION: {
  FAIL_ALL_MISSING: {
    my %posted = ();
    my $person = Schema->resultset('Person')->new_result(\%posted);
    is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{};
    $person->insert;

    is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
      first_name => [
        "First Name can't be blank",
        "First Name is too short (minimum is 2 characters)",
      ],
      last_name => [
        "Last Name can't be blank",
        "Last Name is too short (minimum is 2 characters)",
      ],
      password => [
        "Password can't be blank",
      ],
      username => [
        "Username can't be blank",
        "Username is too short (minimum is 3 characters)",
        "Username must contain only alphabetic and number characters",
      ],
    }, 'Got expected errors';
  }
  FAIL_SOME_MISSING: {
    my %posted = (
      first_name=>'John',
      password=>'abc123',
    );
    my $person = Schema->resultset('Person')->new_result(\%posted);
    is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{};
    $person->insert;
    is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
      last_name => [
        "Last Name can't be blank",
        "Last Name is too short (minimum is 2 characters)",
      ],
      password_confirmation => [
        "Password Confirmation doesn't match 'Password'",
      ],
      username => [
        "Username can't be blank",
        "Username is too short (minimum is 3 characters)",
        "Username must contain only alphabetic and number characters",
      ],
    }, 'Got expected errors';
  }
  MORE_FAILS: {
    my %posted = (
      first_name=>'John',
      password=>'abc123',
      password_confirmation=>'123abc',
      username=>'jn',
    );
    my $person = Schema->resultset('Person')->new_result(\%posted);
    is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{};
    $person->insert;
    is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
      last_name => [
        "Last Name can't be blank",
        "Last Name is too short (minimum is 2 characters)",
      ],
      password_confirmation => [
        "Password Confirmation doesn't match 'Password'",
      ],
      username => [
        "Username is too short (minimum is 3 characters)",
      ],
    }, 'Got expected errors';
  }
  PASS: {
    my %posted = (
      first_name=>'John',
      last_name=>'Napiorkowski',
      password=>'abc123',
      password_confirmation=>'abc123',
      username=>'jnn',
    );
    ok my $person = Schema->resultset('Person')->create(\%posted);
    ok $person->valid;
    ok $person->in_storage;
    ok defined($pid = $person->id);
  }
}

ok defined($pid);

# Profile testing

ok my $find = sub {
  my $params = shift;

  # Construct a person object with related bits preloaded.
  my $person = Schema->resultset('Person')->find(
    { 'me.id'=>$pid },
    { prefetch => ['profile', 'credit_cards', {person_roles => 'role' }] }
  );
  $person->build_related_if_empty('profile'); # We want to display a profile form object even if its not there.

  if($params) {
    $params->{roles} = [] unless (exists($params->{roles}) || exists($params->{person_roles})); # (this will eventually be handled by a params model)
    my $add = delete $params->{add};
    $person->context('profile')->update($params);
    $person->build_related('credit_cards') if $add->{credit_cards};
  }
  
  return $person;
};

BASIC: {
  my $person = $find->();
  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{};
}

ALL_MISSING: {
  my $person = $find->(+{ });
  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    credit_cards => [
      "Credit Cards has too few rows (minimum is 2)",
    ],
    person_roles => [
      "Person Roles has too few rows (minimum is 1)",
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
    "profile.city" => [
      "Profile City can't be blank",
      "Profile City is too short (minimum is 2 characters)",
    ],
    "profile.phone_number" => [
      "Profile Phone Number can't be blank",
      "Profile Phone Number is too short (minimum is 10 characters)",
    ],
    "profile.state_id" => [
      "Profile State Id can't be blank",
    ],
    "profile.state" => [
      "Profile State Is Invalid",
    ],
    "profile.zip" => [
      "Profile Zip can't be blank",
      "Profile Zip is not a zip code",
    ],
  }, 'Got expected errors';
}

ERRORS_ONE: {
  my $person = $find->(+{
    first_name => "john",
    last_name => "nap",
    username => "j",
    profile => {
      address => "15604 Harry Lind Road",
      birthday => "200-02-13",
      city => "Elgin",
      phone_number => "16467081837",
      state_id => 2,
      zip => 78621,
    },
    roles => [
      { id => 3 },
      { id => 4 },
    ],
  });


  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
  credit_cards => [
      "Credit Cards has too few rows (minimum is 2)",
    ],
    profile => [
      "Profile Is Invalid",
    ],
    "profile.birthday" => [
      "Profile Birthday doesn't look like a date",
    ],
    username => [
      "Username is too short (minimum is 3 characters)",
    ],   
  };
}

ERRORS_TWO: {
  my $person = $find->(+{
    first_name => "john",
    last_name => "nap",
    username => "jnn",
    profile => {
      address => "15604 Harry Lind Road",
      birthday => "200-02-13",
      city => "Elgin",
      phone_number => "16467081837",
      state_id => 2,
    },
    roles => [    ],
    credit_cards => {
      0 => {
        card_number => "3423423423423423",
        expiration => "222-02-02",
      },
    },
  });

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    credit_cards => [
      "Credit Cards has too few rows (minimum is 2)",
      "Credit Cards Is Invalid",
    ],
    "credit_cards.0.expiration" => [
      "Credit Cards Expiration does not look like a datetime value",
      "Credit Cards Expiration must be in the future",
    ],
    person_roles => [
      "Person Roles has too few rows (minimum is 1)",
    ],
    profile => [
      "Profile Is Invalid",
    ],
    "profile.birthday" => [
      "Profile Birthday doesn't look like a date",
    ],
    "profile.zip" => [
      "Profile Zip can't be blank",
      "Profile Zip is not a zip code",
    ], 
  };
}

ERRORS_3: {
  my $person = $find->(+{
    first_name => "john",
    last_name => "nap",
    username => "jnn",
    profile => {
      address => "15604 Harry Lind Road",
      birthday => "200-02-13",
      city => "Elgin",
      phone_number => "16467081837",
      state_id => 2,
    },
    roles => [   
      { id => 1 },
      { id => 2 },
      { id => 3 },
      { id => 4 },
    ],
    credit_cards => {
      0 => {
        card_number => "3423423423423423",
        expiration => "2222-02-02",
      },
    },
  });

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    credit_cards => [
      "Credit Cards has too few rows (minimum is 2)",
    ],
    profile => [
      "Profile Is Invalid",
    ],
    "profile.birthday" => [
      "Profile Birthday doesn't look like a date",
    ],
    "profile.zip" => [
      "Profile Zip can't be blank",
      "Profile Zip is not a zip code",
    ],
  };

  is $person->profile->get_column('birthday'), '200-02-13';
}

ERRORS_4: {
  my $person = $find->(+{
    first_name => "john",
    last_name => "nap",
    username => "jjn1",
    profile => {
      address => "15604 Harry Lind Road",
      birthday => "2000-02-13",
      city => "Elgin",
      phone_number => "16467081837",
      state_id => 2,
      zip => '10000'
    },
    roles => [   
      { id => 1 },
      { id => 2 },
      { id => 4 },
    ],
    credit_cards => {
      0 => {
        card_number => "3423423423423423",
        expiration => "2222-02-02",
      },
    },
  });

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    credit_cards => [
      "Credit Cards has too few rows (minimum is 2)",
    ],
  };

  is $person->first_name, 'john';
  is $person->last_name, 'nap';
  is $person->username, 'jjn1';

  is $person->profile->address, '15604 Harry Lind Road';
  is $person->profile->get_column('birthday'), '2000-02-13';
  is $person->profile->city, 'Elgin';
  is $person->profile->phone_number, '16467081837';
  is $person->profile->zip, '10000';
  is $person->profile->state_id, '2';
  is $person->profile->zip, '10000';
  ok !$person->profile->id;

  ok my $roles_rs = $person->roles;
  ok my $r1 = $roles_rs->next;
    is $r1->id, '1';
  ok my $r2 = $roles_rs->next;
    is $r2->id, '2';
  ok my $r3 = $roles_rs->next;
    is $r3->id, '4';
  ok ! $roles_rs->next;

  ok my $cc_rs = $person->credit_cards;
  ok my $cc1 = $cc_rs->next;
    is $cc1->card_number, '3423423423423423';
    is $cc1->expiration->ymd, '2222-02-02';
    ok !$cc1->id;
  ok !$cc_rs->next;
}

my $profile_id;
my @cc_id;

good: {
  my $person = $find->(+{
    first_name => "john",
    last_name => "nap",
    username => "jjn1",
    profile => {
      address => "15604 Harry Lind Road",
      birthday => "2000-02-13",
      city => "Elgin",
      phone_number => "16467081837",
      state_id => 2,
      zip => '10000'
    },
    roles => [   
      { id => 1 },
      { id => 2 },
      { id => 4 },
    ],
    credit_cards => [
      {
        card_number => "3423423423423423",
        expiration => "2222-02-02",
      },
      {
        card_number => "1111222233334444",
        expiration => "2333-02-02",
      },
    ],
  });

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{};

  ok $person->valid;
  ok $person->in_storage;

  is $person->first_name, 'john';
  is $person->last_name, 'nap';
  is $person->username, 'jjn1';

  is $person->profile->address, '15604 Harry Lind Road';
  is $person->profile->get_column('birthday'), '2000-02-13';
  is $person->profile->city, 'Elgin';
  is $person->profile->phone_number, '16467081837';
  is $person->profile->zip, '10000';
  is $person->profile->state_id, '2';
  is $person->profile->zip, '10000';
  ok $profile_id = $person->profile->id;

  ok my $roles_rs = $person->roles;
  ok my $r1 = $roles_rs->next;
    is $r1->id, '1';
  ok my $r2 = $roles_rs->next;
    is $r2->id, '2';
  ok my $r3 = $roles_rs->next;
    is $r3->id, '4';
  ok ! $roles_rs->next;

  ok my $cc_rs = $person->credit_cards;
  ok my $cc1 = $cc_rs->next;
    is $cc1->card_number, '3423423423423423';
    is $cc1->expiration->ymd, '2222-02-02';
    ok $cc_id[0] = $cc1->id;
  ok my $cc2 = $cc_rs->next;
    is $cc2->card_number, '1111222233334444';
    is $cc2->expiration->ymd, '2333-02-02';
    ok $cc_id[1] = $cc2->id;
  ok !$cc_rs->next;

}

# Just test whatr we just did is fine

IS_SAVED_RIGHT: {
  my $person = $find->(+{
    first_name => "john",
    last_name => "nap",
    username => "jjn1",
    profile => {
      id => $profile_id,
      address => "15604 Harry Lind Road",
      birthday => "2000-02-13",
      city => "Elgin",
      phone_number => "16467081837",
      state_id => 2,
      zip => '10000'
    },
    roles => [   
      { id => 1 },
      { id => 2 },
      { id => 4 },
    ],
    credit_cards => [
      {
        id => $cc_id[0],
        card_number => "3423423423423423",
        expiration => "2222-02-02",
      },
      {
        id => $cc_id[1],
        card_number => "1111222233334444",
        expiration => "2333-02-02",
      },
    ],
  });
  
  ok $person->valid;
  ok $person->in_storage;

  is $person->first_name, 'john';
  is $person->last_name, 'nap';
  is $person->username, 'jjn1';

  is $person->profile->address, '15604 Harry Lind Road';
  is $person->profile->get_column('birthday'), '2000-02-13';
  is $person->profile->city, 'Elgin';
  is $person->profile->phone_number, '16467081837';
  is $person->profile->zip, '10000';
  is $person->profile->state_id, '2';
  is $person->profile->id, $profile_id;

  ok my $roles_rs = $person->roles;
  ok my $r1 = $roles_rs->next;
    is $r1->id, '1';
  ok my $r2 = $roles_rs->next;
    is $r2->id, '2';
  ok my $r3 = $roles_rs->next;
    is $r3->id, '4';
  ok ! $roles_rs->next;

  ok my $cc_rs = $person->credit_cards;
  ok my $cc1 = $cc_rs->next;
    is $cc1->card_number, '3423423423423423';
    is $cc1->expiration->ymd, '2222-02-02';
    is $cc1->id, $cc_id[0];
  ok my $cc2 = $cc_rs->next;
    is $cc2->card_number, '1111222233334444';
    is $cc2->expiration->ymd, '2333-02-02';
    is $cc2->id, $cc_id[1];
  ok !$cc_rs->next;
}

# Change it to something that is also ok. change into 
# nested a bit (flex delete)

OK_CHANGE: {
  my $person = $find->(+{
    first_name => "john",
    last_name => "napiorkowski",
    username => "jjn1",
    profile => {
      id => $profile_id,
      address => "15604 Harry Lind Road",
      birthday => "2000-02-13",
      city => "Elgin",
      phone_number => "16467081837",
      state_id => 1,
      zip => '20000'
    },
    roles => [   
      { id => 1 },
      { id => 4 },
    ],
    credit_cards => [
      {
        id => $cc_id[0],
        card_number => "3423423423423423",
        expiration => "2222-02-02",
      },
      {
        id => $cc_id[1],
        card_number => "1111222233334444",
        expiration => "2333-02-02",
      },
    ],
  });
  
  ok $person->valid;
  ok $person->in_storage;

  is $person->first_name, 'john';
  is $person->last_name, 'napiorkowski';
  is $person->username, 'jjn1';

  is $person->profile->address, '15604 Harry Lind Road';
  is $person->profile->get_column('birthday'), '2000-02-13';
  is $person->profile->city, 'Elgin';
  is $person->profile->phone_number, '16467081837';
  is $person->profile->zip, '20000';
  is $person->profile->state_id, '1';
  is $person->profile->id, $profile_id;

  ok my $roles_rs = $person->roles;
  ok my $r1 = $roles_rs->next;
    is $r1->id, '1';
  ok my $r3 = $roles_rs->next;
    is $r3->id, '4';
  ok ! $roles_rs->next;

  ok my $cc_rs = $person->credit_cards;
  ok my $cc1 = $cc_rs->next;
    is $cc1->card_number, '3423423423423423';
    is $cc1->expiration->ymd, '2222-02-02';
    is $cc1->id, $cc_id[0];
  ok my $cc2 = $cc_rs->next;
    is $cc2->card_number, '1111222233334444';
    is $cc2->expiration->ymd, '2333-02-02';
    is $cc2->id, $cc_id[1];
  ok !$cc_rs->next;
}

# Given a good record make some basic errors

BASIC1: {
  my $person = $find->(+{
    first_name => "john",
    last_name => "n",
    username => "jjn1",
    profile => {
      id => $profile_id,
      address => "15604 Harry Lind Road",
      birthday => "2000-02-13",
      city => "Elgin",
      phone_number => "16467081837",
      state_id => 10,
      zip => 'asd'
    },
    roles => [   
      { id => 1 },
      { id => 4 },
    ],
    credit_cards => [
      {
        id => $cc_id[0],
        card_number => "3423423423423425",
        expiration => "2222-02-02",
      },
      {
        id => $cc_id[1],
        card_number => "1111222233334445",
        expiration => "233-i02-02",
      },
    ],
  });
  
  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    last_name => [
      "Last Name is too short (minimum is 2 characters)",
    ],
    profile => [
      "Profile Is Invalid",
    ],
    "profile.state" => [
      "Profile State Is Invalid",
    ],
    "profile.zip" => [
      "Profile Zip is not a zip code",
    ],
    credit_cards => [
      "Credit Cards Is Invalid",
    ],
    "credit_cards.1.expiration" => [
      "Credit Cards Expiration does not look like a datetime value",
      "Credit Cards Expiration must be in the future",
    ],
  };

  ok $person->invalid;
  ok $person->is_changed;
  ok $person->profile->is_changed;

  is $person->first_name, 'john';
  is $person->last_name, 'n';
  is $person->username, 'jjn1';

  is $person->profile->address, '15604 Harry Lind Road';
  is $person->profile->get_column('birthday'), '2000-02-13';
  is $person->profile->city, 'Elgin';
  is $person->profile->phone_number, '16467081837';
  is $person->profile->zip, 'asd';
  is $person->profile->state_id, '10';
  is $person->profile->zip, 'asd';
  is $person->profile->id, $profile_id;

  ok my $roles_rs = $person->roles;
  ok my $r1 = $roles_rs->next;
    is $r1->id, '1';
  ok my $r3 = $roles_rs->next;
    is $r3->id, '4';
  ok ! $roles_rs->next;

  ok my $cc_rs = $person->credit_cards;
  ok my $cc1 = $cc_rs->next;
    is $cc1->card_number, '3423423423423425';
    is $cc1->expiration->ymd, '2222-02-02';
    is $cc1->id, $cc_id[0];
  ok my $cc2 = $cc_rs->next;
    is $cc2->card_number, '1111222233334445';
    is $cc2->get_column('expiration'), '233-i02-02';
    is $cc2->id, $cc_id[1];
  ok !$cc_rs->next;
}

# Add/remove nested with errors

NESTED: {
  my $person = $find->(+{
    first_name => "john",
    last_name => "napiorkowski",
    username => "jjn1",
    profile => {
      id => $profile_id,
      address => "15604 Harry Lind Road",
      birthday => "2000-02-13",
      city => "Elgin",
      phone_number => "16467081837",
      state_id => 1,
      zip => 'aaa', ## bad
    },
    roles => [   
      { id => 2 },
    ],
    credit_cards => [
      {
        id => $cc_id[0],
        card_number => "3423423423423423",
        expiration => "2222-02-02",
      },
      {
        id => $cc_id[1],
        card_number => "1111222233334444",
        expiration => "2333-02-02",
        _delete => 1, 
      },
      {
        card_number => "55555556666666",
        expiration => "3333-02-02",
      },

    ],
  });
  
  is $person->first_name, 'john';
  is $person->last_name, 'napiorkowski';
  is $person->username, 'jjn1';

  is $person->profile->address, '15604 Harry Lind Road';
  is $person->profile->get_column('birthday'), '2000-02-13';
  is $person->profile->city, 'Elgin';
  is $person->profile->phone_number, '16467081837';
  is $person->profile->zip, 'aaa';
  is $person->profile->state_id, '1';
  is $person->profile->id, $profile_id;

  ok my $roles_rs = $person->roles;
  ok my $r1 = $roles_rs->next;
    is $r1->id, '2';
  ok my $r2 = $roles_rs->next;
    is $r2->id, '1';
    ok $r2->is_pruned;
  ok my $r3 = $roles_rs->next;
    is $r3->id, '4';
    ok $r3->is_pruned;
  ok ! $roles_rs->next;

  ok my $cc_rs = $person->credit_cards;
  ok my $cc1 = $cc_rs->next;
    is $cc1->card_number, '3423423423423423';
    is $cc1->expiration->ymd, '2222-02-02';
    is $cc1->id, $cc_id[0];
  ok my $cc2 = $cc_rs->next;
    is $cc2->card_number, '1111222233334444';
    is $cc2->expiration->ymd, '2333-02-02';
    is $cc2->id, $cc_id[1];
    ok $cc2->is_marked_for_deletion;
  ok my $cc3 = $cc_rs->next;
    is $cc3->card_number, '55555556666666';
    is $cc3->expiration->ymd, '3333-02-02';
    ok !$cc3->id;
    ok !$cc3->in_storage;
  ok !$cc_rs->next;

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    profile => [
      "Profile Is Invalid",
    ],
    "profile.zip" => [
      "Profile Zip is not a zip code",
    ],
  };
}

NESTED2: {
  my $person = $find->(+{
    first_name => "john",
    last_name => "napiorkowski",
    username => "jjn1",
    profile => {
      id => $profile_id,
      address => "15604 Harry Lind Road",
      birthday => "2000-02-13",
      city => "Elgin",
      phone_number => "16467081837",
      state_id => 1,
      zip => 'aaa', ## bad
    },
    person_roles => [
      { person_id=>$pid, role_id=>1, '_action'=>['nop','delete']},
      { person_id=>$pid, role_id=>2, '_action'=>'nop' },
      { person_id=>$pid, role_id=>4, '_action'=>'delete'},
    ],
    credit_cards => [
      {
        id => $cc_id[0],
        card_number => "3423423423423423",
        expiration => "2222-02-02",
      },
      {
        id => $cc_id[1],
        card_number => "1111222233334444",
        expiration => "2333-02-02",
        _action => 'delete',
      },
      {
        card_number => "55555556666666",
        expiration => "3333-02-02",
      },

    ],
  });
  
  is $person->first_name, 'john';
  is $person->last_name, 'napiorkowski';
  is $person->username, 'jjn1';

  is $person->profile->address, '15604 Harry Lind Road';
  is $person->profile->get_column('birthday'), '2000-02-13';
  is $person->profile->city, 'Elgin';
  is $person->profile->phone_number, '16467081837';
  is $person->profile->zip, 'aaa';
  is $person->profile->state_id, '1';
  is $person->profile->id, $profile_id;

  ok my $pr_rs = $person->person_roles;
  ok my $pr1 = $pr_rs->next;
    is $pr1->role_id, '1';
    ok $pr1->is_removed;
  ok my $pr2 = $pr_rs->next;
    is $pr2->role_id, '2';
    ok !$pr2->is_removed;
  ok my $pr3 = $pr_rs->next;
    is $pr3->role_id, '4';
    ok $pr3->is_removed;
  ok ! $pr_rs->next;

  {
    ok my $rs = $person->roles;
  }

  ok my $cc_rs = $person->credit_cards;
  ok my $cc1 = $cc_rs->next;
    is $cc1->card_number, '3423423423423423';
    is $cc1->expiration->ymd, '2222-02-02';
    is $cc1->id, $cc_id[0];
  ok my $cc2 = $cc_rs->next;
    is $cc2->card_number, '1111222233334444';
    is $cc2->expiration->ymd, '2333-02-02';
    is $cc2->id, $cc_id[1];
    ok $cc2->is_marked_for_deletion;
  ok my $cc3 = $cc_rs->next;
    is $cc3->card_number, '55555556666666';
    is $cc3->expiration->ymd, '3333-02-02';
    ok !$cc3->id;
    ok !$cc3->in_storage;
  ok !$cc_rs->next;

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    profile => [
      "Profile Is Invalid",
    ],
    "profile.zip" => [
      "Profile Zip is not a zip code",
    ],
  };
}


NESTED_OK1: {
  my $person = $find->(+{
    first_name => "john",
    last_name => "napiorkowski",
    username => "jjn1",
    profile => {
      id => $profile_id,
      address => "15604 Harry Lind Road",
      birthday => "2000-02-13",
      city => "Elgin",
      phone_number => "16467081837",
      state_id => 1,
      zip => '30000',
    },
    person_roles => [
      { person_id=>$pid, role_id=>1, '_action'=>['nop','delete']},
      { person_id=>$pid, role_id=>2, '_action'=>'nop' },
      { person_id=>$pid, role_id=>4, '_action'=>'delete'},
    ],
    credit_cards => [
      {
        id => $cc_id[0],
        card_number => "3423423423423423",
        expiration => "2222-02-02",
      },
      {
        id => $cc_id[1],
        card_number => "1111222233334444",
        expiration => "2333-02-02",
        _action => 'delete',
      },
      {
        card_number => "55555556666666",
        expiration => "3333-02-02",
      },

    ],
  });
  
  is $person->first_name, 'john';
  is $person->last_name, 'napiorkowski';
  is $person->username, 'jjn1';

  is $person->profile->address, '15604 Harry Lind Road';
  is $person->profile->get_column('birthday'), '2000-02-13';
  is $person->profile->city, 'Elgin';
  is $person->profile->phone_number, '16467081837';
  is $person->profile->zip, '30000';
  is $person->profile->state_id, '1';
  is $person->profile->id, $profile_id;

  ok my $pr_rs = $person->person_roles;
  ok my $pr2 = $pr_rs->next;
    is $pr2->role_id, '2';
    ok !$pr2->is_removed;
  ok ! $pr_rs->next;

  ok my $cc_rs = $person->credit_cards;
  ok my $cc1 = $cc_rs->next;
    is $cc1->card_number, '3423423423423423';
    is $cc1->expiration->ymd, '2222-02-02';
    is $cc1->id, $cc_id[0];
  ok my $cc3 = $cc_rs->next;
    is $cc3->card_number, '55555556666666';
    is $cc3->expiration->ymd, '3333-02-02';
    ok $cc_id[1] = $cc3->id;
    ok $cc3->in_storage;
  ok !$cc_rs->next;

  ok $person->valid;
}

NESTED_OK2: {
  my $person = $find->();
  is $person->first_name, 'john';
  is $person->last_name, 'napiorkowski';
  is $person->username, 'jjn1';

  is $person->profile->address, '15604 Harry Lind Road';
  is $person->profile->get_column('birthday'), '2000-02-13';
  is $person->profile->city, 'Elgin';
  is $person->profile->phone_number, '16467081837';
  is $person->profile->zip, '30000';
  is $person->profile->state_id, '1';
  is $person->profile->id, $profile_id;

  ok my $pr_rs = $person->person_roles;
  ok my $pr2 = $pr_rs->next;
    is $pr2->role_id, '2';
    ok ! $pr2->is_removed;
    ok ! $pr2->is_marked_for_deletion;
    ok ! $pr2->is_pruned;
  ok ! $pr_rs->next;

  ok my $cc_rs = $person->credit_cards;
  ok my $cc1 = $cc_rs->next;
    is $cc1->card_number, '3423423423423423';
    is $cc1->expiration->ymd, '2222-02-02';
    is $cc1->id, $cc_id[0];
  ok my $cc3 = $cc_rs->next;
    is $cc3->card_number, '55555556666666';
    is $cc3->expiration->ymd, '3333-02-02';
    is $cc3->id, $cc_id[1];
    ok $cc3->in_storage;
  ok !$cc_rs->next;

  ok $person->valid;
}

NESTED_FAIL4: {
  my $person = $find->(+{ roles=>[] });

  ok $person->invalid;
  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    person_roles => [
      "Person Roles has too few rows (minimum is 1)",
      ],
  };

  is $person->first_name, 'john';
  is $person->last_name, 'napiorkowski';
  is $person->username, 'jjn1';

  is $person->profile->address, '15604 Harry Lind Road';
  is $person->profile->get_column('birthday'), '2000-02-13';
  is $person->profile->city, 'Elgin';
  is $person->profile->phone_number, '16467081837';
  is $person->profile->zip, '30000';
  is $person->profile->state_id, '1';
  is $person->profile->id, $profile_id;

  ok my $pr_rs = $person->person_roles;
  ok my $pr2 = $pr_rs->next;
    is $pr2->role_id, '2';
    ok $pr2->is_removed;
    ok $pr2->is_marked_for_deletion;
    ok $pr2->is_pruned;
  ok ! $pr_rs->next;

  ok my $cc_rs = $person->credit_cards;
  ok my $cc1 = $cc_rs->next;
    is $cc1->card_number, '3423423423423423';
    is $cc1->expiration->ymd, '2222-02-02';
    is $cc1->id, $cc_id[0];
  ok my $cc3 = $cc_rs->next;
    is $cc3->card_number, '55555556666666';
    is $cc3->expiration->ymd, '3333-02-02';
    is $cc3->id, $cc_id[1];
    ok $cc3->in_storage;
  ok !$cc_rs->next;
}

## Some security tests.   Create a A person and then try to create
# a second person but hijack the first persons profile

{
  my $person1 = Schema->resultset('Person')
    ->create(+{
    first_name => "john",
    last_name => "nap",
    username => "jjn11111",
    password => 'aaaaaaa',
    password_confirmation => 'aaaaaaa',
    profile => {
      address => "15604 Harry Lind Road",
      birthday => "2000-02-13",
      city => "Elgin",
      phone_number => "16467081837",
      state_id => 2,
      zip => '10000'
    },
    roles => [   
      { id => 1 },
      { id => 2 },
      { id => 4 },
    ],
    credit_cards => [
      {
        card_number => "3423423423423423",
        expiration => "2222-02-02",
      },
      {
        card_number => "1111222233334444",
        expiration => "2333-02-02",
      },
    ],
  });

  ok $person1->valid;
  ok $person1->in_storage;
  ok my $profile_id = $person1->profile->id;
  ok my $cc_id = $person1->credit_cards->next->id;

  eval { Schema->resultset('Person')
    ->create(+{
    first_name => "john",
    last_name => "nap",
    username => "jjn111112",
    password => 'aaaaaaa',
    password_confirmation => 'aaaaaaa',
    profile => {
      #id => $profile_id,
      person_id => $person1->id,
      address => "15604 Harry Lind Road",
      birthday => "2001-02-13",
      city => "Elgin",
      phone_number => "16467081837",
      state_id => 2,
      zip => '20000'
    },
    roles => [   
      { id => 1 },
      { id => 2 },
      { id => 4 },
    ],
    credit_cards => [
      {
        card_number => "3423423423423423",
        expiration => "2222-02-02",
      },
      {
        card_number => "1111222233334444",
        expiration => "2333-02-02",
      },
    ],
  }) } || do {
    ok $@->isa('DBIx::Class::Valiant::Util::Exception::BadParameters');
  };

  eval {
    Schema->resultset('Person')
      ->create(+{
      first_name => "john",
      last_name => "nap",
      username => "jjn111112",
      password => 'aaaaaaa',
      password_confirmation => 'aaaaaaa',
      profile => {
        id => $profile_id, # try to hijack someone's profile.  Really this should be, its a bad DB design
        address => "15604 Harry Lind Road",
        birthday => "2001-02-13",
        city => "Elgin",
        phone_number => "16467081837",
        state_id => 2,
        zip => '20000'
      },
      roles => [   
        { id => 1 },
        { id => 2 },
        { id => 4 },
      ],
      credit_cards => [
        {
          card_number => "3423423423423423",
          expiration => "2222-02-02",
        },
        {
          card_number => "1111222233334444",
          expiration => "2333-02-02",
        },
      ],
    });
  } || do { ok $@, 'some sort of error' };


    eval { Schema->resultset('Person')
      ->create(+{
      first_name => "john",
      last_name => "nap",
      username => "jjn11134",
      password => 'aaaaaaa',
      password_confirmation => 'aaaaaaa',
      profile => {
        address => "15604 Harry Lind Road",
        birthday => "2001-02-13",
        city => "Elgin",
        phone_number => "16467081837",
        state_id => 2,
        zip => '20000'
      },
      roles => [   
        { id => 1 },
        { id => 2 },
        { id => 4 },
      ],
      credit_cards => [
        {
          person_id => $person1->id,
          card_number => "3423423423423423",
          expiration => "2222-02-02",
        },
        {
          card_number => "1111222233334444",
          expiration => "2333-02-02",
        },
      ],
    }) } || do { ok $@->isa('DBIx::Class::Valiant::Util::Exception::BadParameterFK') };

     my $p3 = Schema->resultset('Person')
      ->create(+{
      first_name => "john",
      last_name => "nap",
      username => "jjn11135",
      password => 'aaaaaaa',
      password_confirmation => 'aaaaaaa',
      profile => {
        address => "15604 Harry Lind Road",
        birthday => "2001-02-13",
        city => "Elgin",
        phone_number => "16467081837",
        state_id => 2,
        zip => '20000'
      },
      person_roles => [   
        { role_id => 1 },
        { role_id => 2 },
      ],
      credit_cards => [
        {
          id=>$cc_id,
          card_number => "00000111110000111",
        },
        {
          card_number => "9999988888887777777",
          expiration => "2333-02-02",
        },
      ],
    });

  # Make sure we didn't hijack the CC
  my @ccs = $p3->credit_cards->all;
  is scalar(@ccs), 1;
  is $ccs[0]->card_number, '9999988888887777777';

  {
    ok my $hijackcheck = Schema->resultset('CreditCard')->find({id=>$cc_id});
    is $hijackcheck->card_number, '3423423423423423';
  }

  {
    my $p3_new = Schema->resultset('Person')->find(
      { 'me.id'=>$p3->id },
      { prefetch => ['profile', 'credit_cards', {person_roles => 'role' }] }
    );
    $p3_new->build_related_if_empty('profile'); # We want to display a profile form object even if its not there. 

    # Ok now try to hijack a credicard again
    $p3_new->update({
      username=>'jjn444444',
      credit_cards=>[
          {
            id=>$cc_id,
            card_number => "00000111110000111",
          },
          {
            card_number => "11999988888887777777",
            expiration => "3333-02-02",
          },
          {
            card_number => "9999988888887777777",
            expiration => "2333-02-02",
          },
        ]
      });

    # I'd prefer this threw and error but I will settle for it not hijakcking
    # Not sure how to detect this case and throw an err.

    ok $p3_new->valid;
    # Make sure we didn't hijack the CC
    my @ccs = $p3_new->credit_cards->all;
    is scalar(@ccs), 2;
    is $ccs[0]->card_number, '11999988888887777777';
    is $ccs[1]->card_number, '9999988888887777777';

    {
      ok my $hijackcheck = Schema->resultset('CreditCard')->find({id=>$cc_id});
      is $hijackcheck->card_number, '3423423423423423';
    }

  }


}

done_testing;

__END__

  use Devel::Dwarn;
  Dwarn +{$person->errors->to_hash(full_messages=>1)};

