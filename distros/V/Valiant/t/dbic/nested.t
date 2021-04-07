use Test::Most;
use Test::Lib;
use Test::DBIx::Class
  -schema_class => 'Schema::Nested';

# Create Tests.  Tests that follow into a nested relationship via an initial
# create

# One to One. When creating a record and nesting into a 1-1 relationship we
# always create a new related record UNLESS there is a match PK or UNIQUE field
# present in the nested related data, if there is a match like that then we instead
# do a FIND and update that found record with the new FK info and any updated fields
# if valid.  If the find fails for unique or PK we go ahead and create anyway.

# If one wants to replace a might have with a new record you should first delete the
# exising record.

{
  # Just successfully create a nested relationship.
  ok my $one = Schema
    ->resultset('OneOne')
    ->create({
      value => 'test',
      one => { value => 'hello'},
    }), 'created fixture';
  
  ok $one->valid;
  ok $one->in_storage;
  ok $one->one->in_storage;

  # do a good update
  $one->update({
    value => 'test2',
    one => { value => 'test3' }
  });

  ok $one->valid;
  ok $one->in_storage;
  ok $one->one->in_storage;

  # do a bad update
  $one->update({
    value => 't',
    one => { value => 't' }
  });

  ok $one->invalid;
  is_deeply +{$one->errors->to_hash(full_messages=>1)}, +{
    value => [
      "Value is too short (minimum is 3 characters)",
    ],
    one => [
      "One Is Invalid",
    ],
    "one.value" => [
      "One Value is too short (minimum is 2 characters)",
    ],
  }, 'Got expected errors';

  # good update
  $one->update({
    value => 'ttttt',
    one => { value => 'ttttt' }
  });

  ok $one->valid;
  $one->discard_changes;
  is $one->value, 'ttttt';
  is $one->one->value, 'ttttt';
}

{
  # Fail in the parent
  ok my $one = Schema
    ->resultset('OneOne')
    ->create({
      value => 't', # to short
      one => { value => 'hhhhhhhhh'}, 
    }), 'created fixture';
  
  ok $one->invalid;
  ok !$one->in_storage;
  ok !$one->one->in_storage;

  is_deeply +{$one->errors->to_hash(full_messages=>1)}, +{
    value => [
      "Value is too short (minimum is 3 characters)",
    ],
  }, 'Got expected errors';

  $one->value("ffffffff");
  $one->insert;
  
  ok $one->valid;
  ok $one->in_storage;
  ok $one->one->in_storage;
}

{
  # Fail in the nested rel
  ok my $one = Schema
    ->resultset('OneOne')
    ->create({
      value => 'test',
      one => { value => 'h'}, # to short
    }), 'created fixture';
  
  ok $one->invalid;
  ok !$one->in_storage;
  ok !$one->one->in_storage;

  is_deeply +{$one->errors->to_hash(full_messages=>1)}, +{
    one => [
      "One Is Invalid",
    ],
    "one.value" => [
      "One Value is too short (minimum is 2 characters)",
    ],
  }, 'Got expected errors';

  $one->one->value("ffffffff");
  $one->insert;
  
  ok $one->valid;
  ok $one->in_storage;
  ok $one->one->in_storage;
}

{
  #test bulk
  my $rs = Schema
    ->resultset('OneOne')
    ->search({},{cache=>1});
  $rs->update_all({value=>'h'});

  while(my $result = $rs->next) {
    ok $result->invalid;
    is $result->value, 'h';
    is_deeply +{$result->errors->to_hash(full_messages=>1)}, +{
      value => [
        "Value is too short (minimum is 3 characters)",
      ],
    }, 'Got expected errors';
  }
}

{
  #test bulk nested 
  my $rs = Schema
    ->resultset('OneOne')
    ->search({},{cache=>1});
  $rs->update_all({one => {value=>'h'}});

  while(my $result = $rs->next) {
    ok $result->invalid;
    is $result->one->value, 'h';
    is_deeply +{$result->errors->to_hash(full_messages=>1)}, +{
      one => [
        "One Is Invalid",
      ],
      "one.value" => [
        "One Value is too short (minimum is 2 characters)",
      ],
    }, 'Got expected errors';
  }
}

{
  # test double nested and make sure we can insert all the way down
  ok my $one = Schema
    ->resultset('OneOne')
    ->create({
      value => 'test01',
      one => {
        value => 'hhh',
        might => { value => 'mighth' }
      },
    }), 'created fixture';

  ok $one->valid;
  ok $one->in_storage;
  ok $one->one->in_storage;
  ok $one->one->might->in_storage;

  $one->discard_changes;

  is $one->value, 'test01';
  is $one->one->value, 'hhh';
  is $one->one->might->value, 'mighth';

  $one->update({
    one => {
      might => { value => 'xtest01' },
    },
  });

  ok $one->valid;
  $one->discard_changes;
  is $one->one->might->value, 'xtest01';

  $one->one->might->value('xtest02');
  $one->update;
  ok $one->valid;
  $one->discard_changes;
  is $one->one->might->value, 'xtest02';

  $one->one->might->value('ggggfffffdddd too long...');
  $one->update;
  
  ok $one->invalid;
  is $one->one->might->value, 'ggggfffffdddd too long...';
  is_deeply +{$one->errors->to_hash(full_messages=>1)}, +{
    one => [
      "One Is Invalid",
    ],
    "one.might" => [
      "One Might Is Invalid",
    ],
    "one.might.value" => [
      "One Might Value is too long (maximum is 8 characters)",
    ],
  }, 'Got expected errors';

  is_deeply +{$one->one->might->errors->to_hash(full_messages=>1)}, +{
    "value" => [
      "Value is too long (maximum is 8 characters)",
    ],
  }, 'Got expected errors';

  $one->one->might->value('ok');
  $one->update;
  ok $one->valid;
  $one->discard_changes;
  is $one->one->might->value, 'ok';
  is $one->one->value, 'hhh';
  is $one->value, 'test01';
}

{
  # test double nested and make sure we can insert all the way down
  ok my $one = Schema
    ->resultset('OneOne')
    ->create({
      value => 'test02',
      one => {
        value => 'hhh2',
        might => { value => 'mightxxxxhxxxxxxxxxxxxx' }
      },
    }), 'created fixture';

  ok $one->invalid;
  is_deeply +{$one->errors->to_hash(full_messages=>1)}, +{
    one => [
      "One Is Invalid",
    ],
    "one.might" => [
      "One Might Is Invalid",
    ],
    "one.might.value" => [
      "One Might Value is too long (maximum is 8 characters)",
    ],
  }, 'Got expected errors';

  $one->one->might->value('ff');

  $one->insert;
  ok $one->valid;

  {
    # deep update
    ok my $result = Schema->resultset('OneOne')->find($one->id);
    $result->update(
      {
        value =>'test04',
        one => {
          value => 'test05',
          might => {
            value => 'test06',
          },
        },
      }
    );
   
    $one->insert;
    ok $one->valid;

    ok my $copy = $one->get_from_storage;
    is $copy->value, 'test04';
    is $copy->one->value, 'test05';
    is $copy->one->might->value, 'test06';
  }
}

{
  # reject_if  tests
  ok my $one = Schema
    ->resultset('OneOne')
    ->create({
      value => 'test12',
      one => {
        value => 'test13',
        might => { value => 'test14' }
      },
    }), 'created fixture';

  ok $one->valid;
  ok $one->one;
  ok !$one->one->might;
}

# Lets do one or two reverse to stress belongs to.  Here's
# a bunch that shoud all always pass.
#

{
  my $might = Schema
    ->resultset('Might')
    ->create({
      value => 'might01',
      one => {
        value => 'might02',
        oneone => {
          value => 'might03',
        },
      },
    });

  ok $might->valid;
  ok $might->in_storage;
  ok $might->one->in_storage;
  ok $might->one->oneone->in_storage;

  $might->update({
    value => 'might05',
    one => {
      oneone => {
        value => 'might04'
      },
    },
  });
 
  ok $might->valid;
  is $might->value, 'might05';
  is $might->one->value, 'might02';
  is $might->one->oneone->value, 'might04';
  
  $might->discard_changes; # reload
  
  is $might->value, 'might05';
  is $might->one->value, 'might02';
  is $might->one->oneone->value, 'might04';

  $might->value('might06');
  $might->one->value('might07');
  $might->one->oneone->value('might08');
  $might->update;

  ok $might->valid;
  $might->discard_changes; # reload
  
  is $might->value, 'might06';
  is $might->one->value, 'might07';
  is $might->one->oneone->value, 'might08';

  $might->value('might09');
  $might->one->oneone->value('might10');
  $might->update;
  ok $might->valid;

  $might->discard_changes; # reload
  
  is $might->value, 'might09';
  is $might->one->value, 'might07';
  is $might->one->oneone->value, 'might10';
}

SKIP: {
  skip "Can't have classes that validate each other yet", 4 if 1;
  ok my $might = Schema
    ->resultset('Might')
    ->create({
      value => 'a',
      one => {
        value => 'b',
        oneone => {
          value => 'c',
        },
      },
    });

  ok $might->invalid;
  ok !$might->in_storage;

  is_deeply +{$might->errors->to_hash(full_messages=>1)}, +{
    one => [
      "One Is Invalid",
    ],
    "one.might" => [
      "One Might Is Invalid",
    ],
    "one.might.value" => [
      "One Might Value is too long (maximum is 8 characters)",
    ],
  }, 'Got expected errors';
}

{
  ok my $might = Schema
    ->resultset('Might2')
    ->create({
      value => 'a',
      one => {
        value => 'b',
        oneone => {
          value => 'c',
        },
      },
    });

  ok $might->invalid;
  ok !$might->in_storage;


  is_deeply +{$might->errors->to_hash(full_messages=>1)}, +{
    one => [
      "One Is Invalid",
    ],
    "one.oneone" => [
      "One Oneone Is Invalid",
    ],
    "one.oneone.value" => [
      "One Oneone Value is too short (minimum is 3 characters)",
    ],
    "one.value" => [
      "One Value is too short (minimum is 2 characters)",
    ],
  }, 'Got expected errors';
}


Schema->resultset("State")->populate([
  [ qw( name abbreviation ) ],
  [ 'Texas', 'TX' ],
  [ 'New York', 'NY' ],
  [ 'California', 'CA' ],
]);

# These next two tests are to test the case where you have a belongs to when
# the far side of the relationships is a 'fixed' set, like states, etc and
# you want to not allow states to be created
{
  ok my $person = Schema
    ->resultset('Person')
    ->create({
      username => 'jjn',
      last_name => 'napiorkowski',
      first_name => 'john',
      state => { abbreviation => 'TX' }
    });

  ok $person->valid;
  ok $person->in_storage;

  # modif it
  $person->discard_changes;

  # If the relation exists (as it does now) and we try to mutate it
  # and don't provide the PK then that means 'create/find a new record'
  # rather than actually do an update.   For lookup belongs_to like this
  # one I think that is the expected behavior.
  $person->update({
    state => { id => 3, abbreviation => 'CA' }
  });

  ok $person->valid;
  ok $person->in_storage;
  is $person->state->abbreviation, 'CA';
  is $person->state->id, 3;

  $person->discard_changes;

  is $person->state->abbreviation, 'CA';
  is $person->state->id, 3;

  $person->discard_changes;
  $person->update({
    state => { abbreviation => 'aa' }
  });

  ok !$person->valid;
  ok $person->state->is_changed;

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    state => [
      "State Is Invalid",
    ],
    "state.abbreviation" => [
      "State Abbreviation aa is not a valid State Abbreviation",
    ],
  }, 'Got expected errors';

  $person->discard_changes;
  #$person = Schema->resultset('Person')->find({id=>$person->id},{prefetch=>'state'});

  $person->update({
    state => { abbreviation => 'TX' }
    #state => { id => 1 }
  });

  ok $person->valid;
  ok $person->in_storage;
  is $person->state->abbreviation, 'TX';
  is $person->state->id, 1;

  $person->discard_changes;

  is $person->state->abbreviation, 'TX';
  is $person->state->id, 1;
}

{
  ok my $person = Schema
    ->resultset('Person')
    ->create({
      username => 'jjn2',
      last_name => 'napiorkowski',
      first_name => 'john',
      state => { abbreviation => 'Ta' }
    });

  ok !$person->valid;
  ok !$person->in_storage;

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    state => [
      "State Is Invalid",
    ],
    "state.abbreviation" => [
      "State Abbreviation Ta is not a valid State Abbreviation",
    ],
  }, 'Got expected errors';
}

# Same as above these but the common person roles pattern

Schema->resultset("Role")->populate([
  [ qw( label ) ],
  [ 'admin' ],
  [ 'user' ],
  [ 'superuser' ],
]);

{
  # just make sure we can create.
  ok my $person = Schema
    ->resultset('Person')
    ->create({
      username => 'jjn3',
      last_name => 'napiorkowski',
      first_name => 'john',
      state => { abbreviation => 'TX' },
      person_roles => [
        {role => {label=>'user'}},
      ],
    });

  ok $person->valid;
  ok $person->in_storage;

  # modif it.   We expect to replace the existing
  $person->discard_changes;
  $person->update({
    'person_roles' => [
        {role => {label=>'admin'}},
    ]
  });

  ok $person->valid;
  $person->discard_changes;
  is $person->username, 'jjn3';
  is $person->state->abbreviation, 'TX';
  my $rs = $person->person_roles->search({},{order_by=>'role_id ASC'});
  is $rs->next->role->label, 'admin';
  ok !$rs->next;

  $person->discard_changes;
  $person->update({
    person_roles => [
        {role => {label=>'adminxx'}},
        {role => {label=>'superuser'}},
        {role => {label=>'admin'}},
    ]
  });

  ok $person->invalid;
  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    person_roles => [
      "Person Roles Is Invalid",
    ],
    "person_roles.0.role" => [
      "Person Roles Role Is Invalid",
    ],
    "person_roles.0.role.label" => [
      "Person Roles Role Label adminxx is not a valid",
    ],
    "person_roles.2.role" => [
      "Person Roles Role already has role admin",
    ],
  }, 'Got expected errors';

  $person->update({
    person_roles => [
        {role => {label=>'superuser'}},
    ]
  });

  ok $person->valid;
  my $rs2 = $person->person_roles->search({},{order_by=>'role_id ASC'});
  is $rs2->next->role->label, 'superuser';
  ok !$rs->next;
}

{
  # just make sure we can create.
  ok my $parent = Schema
    ->resultset('Parent')
    ->create({
        value => 'one',
        children => [
          { value => 'one.one' },
          { value => 'one.two' },
        ],
      }
    );

  ok $parent->valid;
  ok $parent->in_storage;
  #is scalar @{$parent->children->get_cache||[]}, 2;    Maybe this is not right....
  is $parent->children->count, 2;

  # Ok so we gotta make sure this respects the existing resultset cache!!

  $parent->update({
    children => [
      { id => 1, value => 'one.three' },  # update
      { value => 'two.one' },   # insert
    ],
  });

  ok $parent->valid;
  is scalar @{$parent->children->get_cache}, 2;
  is $parent->children->count, 2;   # TODO busted cache issue


}

# Need some tests with errors on create with one->many 

{
  ok my $parent = Schema
    ->resultset('Parent')
    ->create({
        value => 'one',
        children => [
          { value => 'one' },
          { value => 'two' },
        ],
      }
    );

  ok $parent->invalid;
  ok !$parent->in_storage;
  is scalar @{$parent->children->get_cache||[]}, 2;

  is_deeply +{$parent->errors->to_hash(full_messages=>1)}, +{
    children => [
      "Children Is Invalid",
    ],
    "children.0.value" => [
      "Children Value is too short (minimum is 5 characters)",
    ],
    "children.1.value" => [
      "Children Value is too short (minimum is 5 characters)",
    ],
  }, 'Got expected errors';

  is scalar @{$parent->children->get_cache}, 2;
  ok my $rs = $parent->children;
  ok my $first = $rs->next;
  ok my $second = $rs->next;

  is $first->value, 'one';
  is $second->value, 'two';

  $first->value('111111');
  $second->value('222222');

  $parent->insert;

  ok $parent->valid;
  ok $parent->in_storage;

  $parent->discard_changes;

  is $parent->value, 'one';
  {
    ok my $rs = $parent->children;
    ok my $first = $rs->next;
    ok my $second = $rs->next;
    is $first->value, '111111';
    is $second->value, '222222';
  }

}

done_testing;
