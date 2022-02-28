BEGIN { $ENV{VALIANT_DEBUG} = '4,Valiant::I18N'; }

use Test::Most;
use Test::Lib;
use DateTime;
use Test::DBIx::Class
  -schema_class => 'Schema::Create';

{
  # Basic create test which also check the confirmation validation and
  # checks to make sure the default 'create' context works.

  ok my $person = Schema
    ->resultset('Person')
    ->create({
      username => '  jjn   ',
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'hello',
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

  # Ok now fix and try again

  $person->password('thisislongenough');
  $person->insert;

  ok $person->invalid, 'attempted record invalid';
  ok !$person->in_storage, 'record was not saved';

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    password_confirmation => [
      "Password Confirmation doesn't match 'Password'",
    ],
  }, 'Got expected errors';

  # Finally fix it right

  $person->password('thisislongenough2');
  $person->password_confirmation('thisislongenough2');
  $person->insert;

  ok $person->valid, 'valid record';
  ok $person->in_storage, 'record was saved';

  # check the filter.   We need a ton of stand alone tests for this but this
  # is just a very basic test to make sure it compiles and appears to work.

  is $person->username, 'jjn', 'username got trim filter applied';

  # Given this record, show that basic update works.  even though these are
  # create oriented tests we want to test for edge cases like if someone does a
  # create and then holds that object to do updates later. I could see people
  # thinking that was a performance trick or doing it by mistake.

  $person->last_name('nap');
  $person->update;

  ok $person->valid, 'valid record';
  ok $person->in_storage, 'record was saved';

  # Flex the 'needs confirmation if changed' condition.   This is also testing
  # the default 'update' context that gets set when you do an update.  If you
  # check the Person class we are triggering a confirmation check on update only
  # if the password is actually changed.

  $person->password('thisislongenough3');
  $person->update;

  ok $person->invalid, 'attempted record invalid';
  ok $person->in_storage, 'record still in storage';
  ok $person->is_changed;

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    password_confirmation => [
      "Password Confirmation doesn't match 'Password'",
    ],
  }, 'Got expected errors';

  $person->password_confirmation('thisislongenough3');
  $person->update;
  ok $person->valid, 'valid record';

  # Next check that the create relationship helpers also work as expected.  we only
  # need to check 'create_related' since all the others either proxy to it or we
  # don't need to auto validate (for example new_related we don't validate since
  # we don't validate automatically on new or new_result either.   If you call those
  # you need to run validate yourself (just like with ->new on Moo/se classes.).

  my $profile = $person->create_related('profile', {
  });

  ok $profile->invalid, 'invalid record';
  ok !$profile->in_storage, 'record wasnt saved';

  is_deeply +{$profile->errors->to_hash(full_messages=>1)}, +{
    "address",
    [
      "Address can't be blank",
      "Address is too short (minimum is 2 characters)",
    ],
    "city",
    [
      "City can't be blank",
      "City is too short (minimum is 2 characters)",
    ],
    "birthday",
    [
      "Birthday doesn't look like a date",
    ],
    "zip",
    [
      "Zip can't be blank",
      "Zip is not a zip code",
    ],
  }, 'Got expected errors';

  # Fix it

  $profile->address('15604 Harry Lind Road');
  $profile->city('Elgin');
  $profile->zip('78621');
  $profile->birthday(DateTime->now->subtract(years=>20)->ymd);
  $profile->update_or_insert;

  ok $profile->valid, 'valid record';
  ok $profile->in_storage, 'record was saved';
}

# For kicks lets test the uniqueness constraint in concert with
# the trim filter

{
  my $person = Schema
    ->resultset('Person')
    ->create({
      username => '     jjn ', # will be 'jjn' after trim
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'hellohello',
      password_confirmation => 'hellohello',
    });

  ok $person->invalid, 'attempted record invalid';
  ok !$person->in_storage, 'record was not saved';

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    username => [
      'Username chosen is not unique',
    ],
  }, 'Got expected errors';

  # ok fix it

  $person->username('jjn2');
  $person->insert;

  ok $person->valid, 'valid record';
  ok $person->in_storage, 'record was saved';

  # Ok not try to update it to a username that is taken

  $person->username('jjn');
  $person->update;

  ok $person->invalid, 'attempted record invalid';

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    username => [
      'Username chosen is not unique',
    ],
  }, 'Got expected errors';
}

# Some simple update tests.  We also test the password confirmation
# validation on update when changed.

{
  ok my $person = Schema
    ->resultset('Person')
    ->find({username=>'jjn'});

  $person->first_name('j');
  $person->update;

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    first_name => [
      'First Name is too short (minimum is 2 characters)',
    ],
  }, 'Got expected errors';

  $person->first_name('jon');
  $person->password('abc');
  $person->update;

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    password => [
      "Password is too short (minimum is 8 characters)",
    ],
    password_confirmation => [
      "Password Confirmation doesn't match 'Password'",
    ],
  }, 'Got expected errors';

  $person->password('abc124efg');
  $person->password_confirmation('abc124efg');
  $person->update;

  ok $person->valid, 'valid record';

  # Again for kicks and since we are here likes do a nestd update

  $person->last_name('n');
  $person->profile->zip('sadsdasdasdasdsdfsdfsdfsdf');
  $person->update;

  ok $person->invalid;

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    "last_name",
    [
      "Last Name is too short (minimum is 2 characters)",
    ],
    "profile",
    [
      "Profile Is Invalid",
    ],
    "profile.zip",
    [
      "Profile Zip is not a zip code",
    ],
  }, 'Got expected errors';

  is_deeply +{$person->profile->errors->to_hash(full_messages=>1)}, +{
    "zip",
    [
      "Zip is not a zip code",
    ],
  }, 'Got expected errors';

  # Ok, try a deep update and expect it to work this time. (might_have relation
  # and we are expecting an update on the relation)

  $person->update({
    last_name => 'longenough',
    profile => {
      zip => '12345',
    }
  });

  ok $person->valid; #ok properly updated the profile relation otherwise if it did a create we'd expect missing field errors
}

{
  # create a person, then do an update with nested and make sure
  # we validate aand then insert the new profile.
  #
  ok my $person = Schema
    ->resultset('Person')
    ->create({
      username => '     jjn3 ', # will be 'jjn3' after trim
      first_name => 'john',
      last_name => 'napiorkowski',
      password => 'hellohello',
      password_confirmation => 'hellohello',
    }), 'created fixture';

  ok $person->valid, 'attempted record valid';
  ok $person->in_storage, 'record was saved';
  is $person->username, 'jjn3';

  # Lets reload from the DB rather than reuse the existing object this
  # time (like we did in the above tests) to make sure there's no weird
  # stuff going on in th caches.

  {
    ok my $person = Schema->resultset('Person')->find({username=>'jjn3'});

    # Ok try to update and let the nested profile require a create but
    # be invalid so that we get error results.
    $person->update({
      last_name => 'n',
      profile => {
        zip => '12345',
        city => 'Elgin',
        birthday => '2011-01-01',
      }
    });

    ok $person->invalid;
    ok !$person->profile->in_storage;
    is $person->last_name, 'n';
    is $person->profile->zip, '12345';
    is $person->profile->city, 'Elgin';
    is $person->profile->birthday->ymd, '2011-01-01'; #this gets inflated to a DateTime object

    is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
      "profile.address",
      [
        "Profile Address can't be blank",
        "Profile Address is too short (minimum is 2 characters)",
      ],
      "profile",
      [
        "Profile Is Invalid",
      ],
      "last_name",
      [
        "Last Name is too short (minimum is 2 characters)",
      ],
    }, 'Got expected errors';

    #  Now fix it si that Person properly updates and the profile gets saved
    $person->update({
      last_name => 'nnnnnnnnnnnnnn',
      profile => {
        address => '12345 Home Way',
      }
    });

    ok $person->valid;
    ok $person->profile->in_storage;
    is $person->last_name, 'nnnnnnnnnnnnnn';
    is $person->profile->address, '12345 Home Way';

    # reload from DB once last time and make sure all the expected updates 
    # happened

    {
      ok my $person = Schema->resultset('Person')->find({username=>'jjn3'});
      is $person->last_name, 'nnnnnnnnnnnnnn';
      is $person->profile->address, '12345 Home Way';
    }
  }
}

# find_or_create we only test the create side

{
  ok my $person = Schema
    ->resultset('Person')
    ->find_or_create({
      username => '     jjn4 ', # will be 'jjn4' after trim
      first_name => 'john',
      last_name => 'napiorkowski',
    }), 'created fixture';

  ok $person->invalid;
  ok !$person->in_storage;

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    password => [
      "Password can't be blank",
      "Password is too short (minimum is 8 characters)",
    ],
  }, 'Got expected errors';
}

# update_or_create need to test both the create and update side
# we do create first

{
  ok my $person = Schema
    ->resultset('Person')
    ->update_or_create({
      username => '     jjn4 ', # will be 'jjn4' after trim
      first_name => 'john',
      last_name => 'napiorkowski',
    }), 'created fixture';

  ok $person->invalid;
  ok !$person->in_storage;

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    password => [
      "Password can't be blank",
      "Password is too short (minimum is 8 characters)",
    ],
  }, 'Got expected errors';
}

# now test the update side

{
  ok my $person = Schema
    ->resultset('Person')
    ->update_or_create({
      username => 'jjn3',
      first_name => 'j',
    }), 'created fixture';

  ok $person->invalid;
  ok $person->is_changed;

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    "first_name", [
      "First Name is too short (minimum is 2 characters)",
    ],
  }, 'Got expected errors';
}

# For kicks lets try this with a nested relation.  When updating a record
# with a 'might_have' relation IF the relation exists we update that relation

{
  ok my $person = Schema
    ->resultset('Person')
    ->find({username => 'jjn3'});

    #$person->profile;  # Ok so lets NOT inflate the relation and make sure
    #the code does the right thing and inflates it for us.

  $person->update({
      username => 'jjn3',
      first_name => 'j',
      profile => { zip => 'asfdsadfsafasdfsdf' }
    });

  ok $person->invalid;
  ok $person->is_changed;

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    "first_name", [
      "First Name is too short (minimum is 2 characters)",
    ],
    "profile", [
      "Profile Is Invalid",
    ],
    "profile.zip", [
      "Profile Zip is not a zip code",
    ],
  }, 'Got expected errors';
}

{
  ok my $person = Schema
    ->resultset('Person')
    ->update_or_create({
      username => 'jjn3',
      first_name => 'j',
      profile => { zip => 'asfdsadfsafasdfsdf' }
    }), 'created fixture update_or_create';

  ok $person->invalid;
  ok $person->is_changed;

  is_deeply +{$person->errors->to_hash(full_messages=>1)}, +{
    "first_name", [
      "First Name is too short (minimum is 2 characters)",
    ],
    "profile", [
      "Profile Is Invalid",
    ],
    "profile.zip", [
      "Profile Zip is not a zip code",
    ],
  }, 'Got expected errors';
}

{
  ok my $person = Schema
    ->resultset('Person')
    ->find({username => 'jjn3'});

  my $profile = $person->find_or_create_related('profile', +{});

  is $profile->zip, 12345; # Found expected

  $profile->zip("asdasda");
  $person->update;

  ok $person->valid;
  ok $person->profile->valid;

  $profile->update;
  ok $profile->invalid;

  # Still valid because its got cached the orginal
  ok $person->profile->valid;
  is $person->profile->zip, 12345;
}

done_testing;
