use Test::Most;
use Test::Lib;
use Test::DBIx::Class
  -schema_class => 'Schema::Nested';

# Testing m2m

Schema->resultset("State")->populate([
  [ qw( name abbreviation ) ],
  [ 'Texas', 'TX' ],
  [ 'New York', 'NY' ],
  [ 'California', 'CA' ],
]);

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
      roles => [ 
        { label => 'user' },
        { label => 'adminx' },
      ]
    });

  ok $person->invalid;
  ok !$person->in_storage;

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    person_roles => [
      "Person Roles Is Invalid",
    ],
    "person_roles.1.role" => [
      "Person Roles Role Is Invalid",
    ],
    "person_roles.1.role.label" => [
      "Person Roles Role Label adminx is not a valid",
    ],
    roles => [
      "Roles Is Invalid",
    ],
    "roles.1.label" => [
      "Roles Label adminx is not a valid",
    ],
  }, 'Got expected errors';

  ok my $roles_rs = $person->roles;
  is scalar @{$roles_rs->get_cache||[]}, 2;  
  is $roles_rs->count, 2;
  is $roles_rs->next->label, 'user';
  ok my $last = $roles_rs->next;
  is $last->label, 'adminx';

  is_deeply +{$last->errors->to_hash(full_messages=>1)}, +{
    label => [
      "Label adminx is not a valid",
    ],
  }, 'Got expected errors';

  $last->label('admin');
  $person->insert;

  ok $person->valid;
  ok $person->in_storage;

  $person->discard_changes;

  $person->update({
    roles => [
        { label => 'superuserX' },
    ],
  });

  ok $person->invalid;
  is scalar @{$person->person_roles->get_cache||[]}, 1;
  {
    ok my $roles_rs = $person->roles;
    is scalar @{$roles_rs->get_cache||[]}, 1;
    is $roles_rs->next->label, 'superuserX';
  }

  $person->discard_changes;

  {
    my $new = 'superuser';
    $person->update({
      person_roles => [
        { role => {  label => $new } },
      ],
    });

    ok $person->valid;
    is scalar @{$person->person_roles->get_cache||[]}, 1;
    ok my $next = $person->person_roles->next;
    ok $next->{_relationship_data}{role}, 'found in relationship_data';
    is $next->role->label, $new;
  }

  $person->discard_changes;

  {
    my $new = 'superuserx';
    $person->update({
      person_roles => [
        { role => {  label => $new } },
      ],
    });

    ok $person->invalid;
    is scalar @{$person->person_roles->get_cache||[]}, 1;
    ok my $next = $person->person_roles->next;
    ok $next->{_relationship_data}{role}, 'found in relationship_data';
    is $next->role->label, $new;
  }

  $person->discard_changes;

  {
    my $new = 'superuserx';
    $person->update({
      roles => [{  label => $new }], 
    });

    ok $person->invalid;
    is scalar @{$person->roles->get_cache||[]}, 1;
    is scalar @{$person->person_roles->get_cache||[]}, 1;
    ok my $roles_rs = $person->roles;
    is $roles_rs->count, 1;
    ok my $next = $person->roles->next;
    is $next->label, $new;
  }

  $person->person_roles->delete;
  $person->update({ roles => [{  label => 'user' }] });
  $person->discard_changes;

  {
    my $new = 'superuser';
    $person->update({
      roles => [{  label => $new }], 
    });

    ok $person->valid;
    
    {
      is scalar @{$person->person_roles->get_cache||[]}, 1;
      ok my $next = $person->person_roles->next;
      ok $next->{_relationship_data}{role}, 'found in relationship_data';
      is $next->role->label, $new;
    }

    {
      my $person_roles_rs = $person->search_related('person_roles');
      ok my $next = $person_roles_rs->next;
      ok $next->{_relationship_data}{role}, 'found in relationship_data';
      is $next->role->label, $new;
    }

    {
      my $person_roles_rs = $person->search_related('person_roles');
      is $person_roles_rs->count, 1;
      my $role_rs = $person_roles_rs->search_related('role');
 
      ok my $next = $role_rs->next;
      is $next->label, $new;
    }


  }

}

done_testing;

__END__



      use Devel::Dwarn;
      $person->clear_validated;
      delete $person->{__valiant_related_resultset};
      delete $person->{errors};
      delete $person->{validated};
      delete $person->{_relationship_data}{person_roles}[0]{__valiant_related_resultset};

      #Dwarn $person;

"........"
{
  "me.id" => 3,
}
{
  accessor => "single",
  fk_columns => {
    role_id => 1,
  },
  is_depends_on => 1,
  is_foreign_key_constraint => 1,
  undef_on_null_fk => 1,
}

"........"
{
  "me.id" => 1,
}
{
  accessor => "single",
  fk_columns => {
    state_id => 1,
  },
  is_depends_on => 1,
  is_foreign_key_constraint => 1,
  undef_on_null_fk => 1,
}


    {
      use Devel::Dwarn;
      Dwarn [sort  keys %{ $person}];
      Dwarn [sort keys %{$person->{related_resultsets}}];
      Dwarn [sort keys %{$person->{related_resultsets}{person_roles}}];
      Dwarn [sort keys %{$person->{related_resultsets}{person_roles}{all_cache}[0]{related_resultsets}  }  ];

      is scalar @{$person->roles()->get_cache||[]}, 1;

      warn 1111;
      #$person->search_related('person_roles')->search_related('role')
      warn $person->search_related('person_roles');
      warn $person->{related_resultsets}{person_roles}{all_cache}[0];
      #warn $person->{related_resultsets}{person_roles}{all_cache}[0]{_relationship_data}{role};
      #warn $person->search_related('person_roles')->search_related('role');
            warn '........';
      #warn $person->{related_resultsets}{person_roles}{all_cache}[0]{related_resultsets};
      #warn $person->search_related('person_roles')->{related_resultsets};
      Dwarn [sort keys %{ $person->search_related('person_roles')} ];
      Dwarn [sort keys %{$person->{related_resultsets}{person_roles}{all_cache}[0] }];


      # must be difference in related_resulsetst
      #$self->{related_resultsets}{$rel}

      #ok my $next = $person->roles->next;
      #is $next->label, $new;
    }







  $person->update({
    roles => [
        { label => 'superuser' },
    ],
  });

  ok $person->valid;
  is scalar @{$person->person_roles->get_cache||[]}, 1;
  is $person->person_roles->next->role->label, 'superuser';

  {
    #ok my $roles_rs = $person->roles;
    #is scalar @{$roles_rs->get_cache||[]}, 1;
    #is $roles_rs->next->label, 'superuser';
  }


  


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

  # modif it.   We expect to add one
  $person->discard_changes;
  $person->update({
    person_roles => [
        {role => {label=>'admin'}},
    ]
  });

  ok $person->valid;
  $person->discard_changes;
  is $person->username, 'jjn3';
  is $person->state->abbreviation, 'TX';
  my $rs = $person->person_roles->search({},{order_by=>'role_id ASC'});
  is $rs->next->role->label, 'admin';
  is $rs->next->role->label, 'user';
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
  is $rs2->next->role->label, 'admin';
  is $rs2->next->role->label, 'user';
  is $rs2->next->role->label, 'superuser';
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

__END__

  warn scalar @{$parent->children->get_cache};

  $parent->discard_changes;
  is $parent->children->count, 3;




  $parent->discard_changes;

  $parent->update({
    children => [
      { id => 1, value => 'one.four' },
      { value => 'two.two' },
    ],
  });

  ok $parent->valid;
  is $parent->children->count, 4;



  

  use Devel::Dwarn;
  Dwarn +{$person->errors->to_hash(full_messages=>1)};

  
  is_deeply +{$might->errors->to_hash(full_messages=>1)}, +{
    one => [
      "One Is Invalid",
    ],
    "one.value" => [
      "One Value is too short (minimum is 2 characters)",
    ],
  }, 'Got expected errors';

  use Devel::Dwarn;
  Dwarn +{$might->one->oneone->errors->to_hash(full_messages=>1)};
  Dwarn $might->one->oneone->value;


$might->one->oneone->validate;
  Dwarn +{$might->one->oneone->errors->to_hash(full_messages=>1)};
  Dwarn +{$might->errors->to_hash(full_messages=>1)};



  
  use Devel::Dwarn;
  Dwarn +{$one->errors->to_hash(full_messages=>1)};

# also terset from oneone to one (we expect one to exist so that should always be an update)
