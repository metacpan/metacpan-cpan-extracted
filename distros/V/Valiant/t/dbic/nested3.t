use Test::Most;
use Test::Lib;
use Test::DBIx::Class
  -schema_class => 'Schema::Nested';

# Create a person as a fixture

Schema->resultset("State")->populate([
  [ qw( name abbreviation ) ],
  [ 'Texas', 'TX' ],
  [ 'New York', 'NY' ],
  [ 'California', 'CA' ],
]);

ok my $person = Schema
  ->resultset('Person')
  ->create({
    username => 'jjn',
    last_name => 'napiorkowski',
    first_name => 'john',
    state => { abbreviation => 'TX' },
  });

ok $person->valid;
ok $person->in_storage;

# Find it like as in a web session
ok my $person_for_meeting = Schema->resultset('Person')->find($person->id);
ok my $meetings_nested_attendees = $person_for_meeting->meetings->search({},{prefetch=>'attendees'});
ok my $new_meeting = $meetings_nested_attendees->new_result(+{});

ok $new_meeting->set_columns_recursively({
    title=>'first meeting',
    purpose=>'test this',
    attendees=>[
      {
        role => 'one',
        background => 'back1',
        desired_outcome => 'misery',
        personality => 'hateful',
        motivation => 'much',
      },
      {
        role => 'two',
        background => 'back2',
        desired_outcome => 'happy',
        personality => 'lawful evil',
        motivation => 'slacker',
      },
    ],
  });

ok exists $new_meeting->{related_resultsets}{attendees};
ok $new_meeting->insert_or_update;
ok !exists $new_meeting->{related_resultsets}{attendees};

ok $new_meeting->valid;

# RThis is not a bug its due to DBIC clearing the cache after insert
# #$new_meeting->transcript('Hey hey hey');
#$new_meeting->update;

#ok $new_meeting->valid;

#use Devel::Dwarn;
#Dwarn $new_meeting->errors->to_hash(full_messages=>1);

done_testing;
