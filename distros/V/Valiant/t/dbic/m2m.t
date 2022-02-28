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

  #$person->discard_changes;

  $person = Schema
    ->resultset('Person')
    ->find(
      {'me.id'=>$person->id},
      {prefetch=>{person_roles=>'role'}}
    );

  $person->update({
    roles => [
      { label => 'superuserX' },
    ],
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
      "Person Roles Role Label superuserX is not a valid",
    ],
    roles => [
      "Roles Is Invalid",
    ],
    "roles.0.label" => [
      "Roles Label superuserX is not a valid",
    ],
  }, 'Got expected errors';

  is scalar(my @prs = @{$person->person_roles->get_cache||[]}), 3;

  {
    ok my $roles_rs = $person->roles;
    is scalar @{$roles_rs->get_cache||[]}, 3;
    is $roles_rs->next->label, 'superuserX';
  }

  is $prs[0]->role->label, 'superuserX';
  is $prs[2]->role->label, 'user';
  is $prs[1]->role->label, 'admin';

  ok not $prs[0]->is_marked_for_deletion;
  ok $prs[1]->is_marked_for_deletion;
  ok $prs[2]->is_marked_for_deletion;



  #$person->discard_changes;
  $person = Schema
    ->resultset('Person')
    ->find(
      {'me.id'=>$person->id},
      {prefetch=>{person_roles=>'role'}}
    );

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

  #$person->discard_changes;
  $person = Schema
    ->resultset('Person')
    ->find(
      {'me.id'=>$person->id},
      {prefetch=>{person_roles=>'role'}}
    );

  {
    my $new = 'superuserx';
    $person->update({
      person_roles => [
        { role => {  label => $new } },
      ],
    });

    ok $person->invalid;
    is scalar(my @prs = @{$person->person_roles->get_cache||[]}), 2;
    is $prs[0]->role->label, $new;
    is $prs[1]->role->label, 'superuser';
    ok $prs[1]->is_marked_for_deletion;
  }

  #$person->discard_changes;
  $person = Schema
    ->resultset('Person')
    ->find(
      {'me.id'=>$person->id},
      {prefetch=>{person_roles=>'role'}}
    );

  {
    my $new = 'superuserx';
    $person->update({
      roles => [{  label => $new }], 
    });

    ok $person->invalid;
    is scalar @{$person->roles->get_cache||[]}, 2;
    is scalar @{$person->person_roles->get_cache||[]}, 2;
    ok my $roles_rs = $person->roles;
    is $roles_rs->count, 2;
    ok my $next = $roles_rs->next;
    is $next->label, $new;
    ok $next = $roles_rs->next;
    is $next->label, 'superuser';
    ok $person->person_roles->get_cache->[1]->is_marked_for_deletion;
  }

  $person->person_roles->delete;
  $person->update({ roles => [{  label => 'user' }] });
  ok $person->valid;
  $person->discard_changes;

  {
    # there may be a problem with discard changes and how all this works
    # I'm worried about that.
    $person = Schema
      ->resultset('Person')
      ->find(
        {'me.id'=>$person->id},
        {prefetch=>{person_roles=>'role'}}
      );

    ok my $new = 'superuser';
    is scalar($person->roles->all), 1, "One role only";
    ok $person->update({
      roles => [{  label => $new }], 
    }), 'Did update to role superuser';

    ok $person->valid;
    ok $person->in_storage;
    is scalar($person->roles->all), 1, "One role only";
    
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

  {
    ok $person->in_storage;
    ok !$person->is_changed;
    $person->discard_changes;

    $person = Schema->resultset('Person')->find({ 'me.id'=>$person->id }, { prefetch => [{person_roles => 'role' }] });

    $person->context('min')->update({
      roles => [],
    });

    ok $person->invalid;
    {
      my $rs = $person->person_roles;
      ok my $row = $rs->next;
      is $row->role->label, 'superuser';
      ok $row->is_marked_for_deletion;
      ok $row->role->is_pruned;
      ok !$rs->next;
    }
    
    is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
      person_roles => [
        "Person Roles has too few rows (minimum is 1)",
      ],
      roles => [
        "Roles has too few rows (minimum is 1)",
      ],
    }, 'Got expected errors';
  }

  {
    ok my $new_person = Schema->resultset('Person')->find(
      { 'me.id'=>$person->id },
      { prefetch => [{person_roles => 'role' }] }
    );

    $new_person->context('min')->update({
      roles => [],
    });

    {
      is scalar @{$new_person->person_roles->get_cache||[]}, 1;
      ok my $rs = $new_person->person_roles;
      {
        ok my $row = $rs->next;
        is $row->role->label, 'superuser';
        ok $row->is_marked_for_deletion;
      }
      ok ! $rs->next;
    }

    {
      is scalar @{$new_person->roles()->get_cache||[]}, 1;
      ok my $rs = $new_person->roles;
      {
        ok my $row = $rs->next;
        is $row->label, 'superuser';
        ok $row->is_pruned;
      }
      ok ! $rs->next;
    }

    is_deeply +{$new_person->errors->to_hash(full_messages=>1)}, +{
      person_roles => [
        "Person Roles has too few rows (minimum is 1)",
      ],
      roles => [
        "Roles has too few rows (minimum is 1)",
      ],
    }, 'Got expected errors';
  }
}

{
  # just make sure we can create.
  ok my $person = Schema
    ->resultset('Person')
    ->create({
      username => 'jjn41',
      last_name => 'napiorkowski',
      first_name => 'john',
      state => { abbreviation => 'TX' },
      person_roles => [ 
        { role_id => 1 },
        { role_id => 2 },
        #{ role => { label => 'user' }  },
        #{ role => { label => 'admin' }  },
      ]
    });

  $person->update({
    first_name => 'd',
    person_roles => [ 
      { role_id => 1 },
      { role_id => 3 },
    ],
  });

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    first_name => [
      "First Name is too short (minimum is 2 characters)",
    ],
  }, 'Got expected errors';

  ok my $pr_rs = $person->person_roles;
  {
    my $pr = $pr_rs->next;
    ok !$pr->is_marked_for_deletion;
    ok $pr->in_storage;
  }
  {
    my $pr = $pr_rs->next;
    ok !$pr->is_marked_for_deletion;
    is $pr->role_id, 3;
    ok !$pr->in_storage;

  }  
  {
    my $pr = $pr_rs->next;
    ok $pr->is_marked_for_deletion;
    ok $pr->in_storage;
  }

  #  use Devel::Dwarn;
  #  Dwarn +{ $person->errors->to_hash(full_messages=>1) };

}

done_testing;
