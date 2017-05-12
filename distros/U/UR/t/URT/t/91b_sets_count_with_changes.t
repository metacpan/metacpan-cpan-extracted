use strict;
use warnings;
use Test::More tests=> 125;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use Sub::Install;

# Test getting some objects that includes -hints, and then that later get()s
# don't re-query the DB

use URT;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got a database handle');

ok($dbh->do('create table PERSON
            ( person_id int NOT NULL PRIMARY KEY, name varchar, is_cool integer, age integer )'),
   'created person table');
ok($dbh->do('create table CAR
            ( car_id int NOT NULL PRIMARY KEY, color varchar, is_primary int, owner_id integer references PERSON(person_id))'),
   'created car table');

ok(UR::Object::Type->define(
    class_name => 'URT::Person',
    table_name => 'PERSON',
    id_by => [
        person_id => { is => 'NUMBER' },
    ],
    has => [
        name              => { is => 'String' },
        is_cool           => { is => 'Boolean' },
        age               => { is => 'Integer' },
        cars              => { is => 'URT::Car', reverse_as => 'owner', is_many => 1, is_optional => 1 },
        primary_car       => { is => 'URT::Car', via => 'cars', to => '__self__', where => ['is_primary true' => 1] },
        car_colors        => { via => 'cars', to => 'color', is_many => 1 },
        primary_car_color => { via => 'primary_car', to => 'color' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
),
'Created class for people');

ok(UR::Object::Type->define(
        class_name => 'URT::Car',
        table_name => 'CAR',
        id_by => [
            car_id =>           { is => 'NUMBER' },
        ],
        has => [
            color   => { is => 'String' },
            is_primary => { is => 'Boolean' },
            owner   => { is => 'URT::Person', id_by => 'owner_id' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "Created class for Car");

# Insert some data
# Bob and Mike have red cars, Fred and Joe have blue cars.  Frank has no car.  Bob, Joe and Frank are cool
# Bob also has a yellow car that's his primary car
my $insert = $dbh->prepare('insert into person values (?,?,?,?)');
foreach my $row ( [ 11, 'Bob',1, 25 ], [12, 'Fred',0, 30], [13, 'Mike',0, 35],[14,'Joe',1, 40], [15,'Frank', 1, 45] ) {
    $insert->execute(@$row);
}
$insert->finish();

$insert = $dbh->prepare('insert into car values (?,?,?,?)');
foreach my $row ( [ 1,'red',0,  11], [ 2,'blue',1, 12], [3,'red',1,13],[4,'blue',1,14],[5,'yellow',1,11] ) {
    $insert->execute(@$row);
}
$insert->finish();


my $aggr_query_count = 0;
my $query_count = 0;
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub {
                        my ($observed, $aspect, $data) = @_;
                        if ($data =~ /count|sum|min|max/) {
                            $aggr_query_count++
                        }
                        $query_count++;
                    }),
    'Created a subscription for query');

# Test creating/deleting/modifying objects that match extant sets.
$query_count = 0;
my $uncool_person_set = URT::Person->define_set(is_cool => 0);
ok($uncool_person_set, 'Defined set of people that are not cool');
my $cool_person_set = URT::Person->define_set(is_cool => 1);
ok($cool_person_set, 'Defined set of people that are cool');
is($cool_person_set->is_cool, 1, "access to a defining property works");
is($query_count, 0, 'Made no queries');

# Test set-relaying.
my $car_set = $cool_person_set->cars_set;
ok($car_set, "got a set of cars for the person set: object set -> value set");

# We're going to roll back all these changes just before the last block of tests
my $t = UR::Context::Transaction->begin();

# Test aggregate function on a set that has no member changes.
# All aggregate functions should trigger query since function is
# performed server-side on the data source.
{
    ok(!$cool_person_set->_members_have_changes, 'cool set has no changed objects');

    $aggr_query_count = 0;
    is($cool_person_set->count, 3, '3 people are cool');
    is($aggr_query_count, 1, 'count triggered one query');

    $aggr_query_count = 0;
    is($cool_person_set->min('age'), 25, 'determined min age');
    is($aggr_query_count, 1, 'min triggered one query');

    $aggr_query_count = 0;
    is($cool_person_set->max('age'), 45, 'determined max age');
    is($aggr_query_count, 1, 'max triggered one query');

    $aggr_query_count = 0;
    is($cool_person_set->sum('age'), 110, 'determined the sum of all ages of the set');
    is($aggr_query_count, 1, 'sum triggered one query');
}

# Now induce a change in a member and ensure no queries are performed.
{
    my $p = URT::Person->get(11);
    ok($cool_person_set->rule->evaluate($p), 'person is member of cool person set');
    ok($p->age($p->age + 1), 'changed the age of the youngest person to be +1 (26)');

    ok($cool_person_set->_members_have_changes, 'cool person set now has changes');

    $aggr_query_count = 0;
    is($cool_person_set->count, 3, 'set membership count is still the same');
    is($aggr_query_count, 0, 'count did not trigger query');

    $aggr_query_count = 0;
    is($cool_person_set->min('age'), 26, 'minimum age is now 26');
    is($aggr_query_count, 0, 'min did not trigger query');

    $aggr_query_count = 0;
    is($cool_person_set->max('age'), 45, 'maximum age is still 45');
    is($aggr_query_count, 0, 'max did not trigger query');

    $aggr_query_count = 0;
    is($cool_person_set->sum('age'), 111, 'the sum of all ages is now 111');
    is($aggr_query_count, 0, 'sum did not trigger query');
}

# Now ensure that a set with same member class but without any actual
# member changes is not affected.
{
    is($uncool_person_set->member_class_name, $cool_person_set->member_class_name, 'sets have the same member class');
    isnt($uncool_person_set, $cool_person_set, 'sets are not the same');
    ok(!$uncool_person_set->_members_have_changes, 'uncool set has no changed objects');

    $aggr_query_count = 0;
    is($uncool_person_set->count, 2, 'set membership count is still the same');
    is($aggr_query_count, 1, 'count triggered one query');

    $aggr_query_count = 0;
    is($uncool_person_set->min('age'), 30, 'minimum age is now 30');
    is($aggr_query_count, 1, 'min triggered one query');

    $aggr_query_count = 0;
    is($uncool_person_set->max('age'), 35, 'maximum age is still 35');
    is($aggr_query_count, 1, 'max triggered one query');

    $aggr_query_count = 0;
    is($uncool_person_set->sum('age'), 65, 'the sum of all ages is now 65');
    is($aggr_query_count, 1, 'sum triggered one query');
}

# Now ensure that changes to members are reflected in the set.
{
    my $cool_person_count = $cool_person_set->count;

    my $jamesbond = URT::Person->create(name => 'James Bond', is_cool => 1, age => '35');
    ok($jamesbond, 'Create a new cool person');

    $aggr_query_count = 0;
    is($cool_person_set->count, $cool_person_count + 1, 'count increased');
    is($aggr_query_count, 0, 'count did not trigger query');

    my $fred = URT::Person->get(12);
    is($fred->is_cool, 0, 'fred is not cool (yet)');
    $fred->is_cool(1);

    $aggr_query_count = 0;
    is($cool_person_set->count, $cool_person_count + 2, 'count increased again');
    is($aggr_query_count, 0, 'count did not trigger query');

    $aggr_query_count = 0;
    ok($jamesbond->delete, 'Delete James Bond');
    is($cool_person_set->count, $cool_person_count + 1, 'count decreased after delete');
    is($aggr_query_count, 0, 'Made no queries');
}

# Fab up a method wrapper so we can tell if the accessor is called
my $original_age_accessor = \&URT::Person::age;
my $age_accessor_called = 0;
Sub::Install::reinstall_sub({
    into => 'URT::Person',
    as => 'age',
    code => sub { $age_accessor_called = 1; goto &$original_age_accessor }
});

my $original_name_accessor = \&URT::Person::name;
my $name_accessor_called = 0;
Sub::Install::reinstall_sub({
    into => 'URT::Person',
    as => 'name',
    code => sub { $name_accessor_called = 1; goto &$original_name_accessor }
});

# Make a change, then do a set aggregate on a different property
# it should do a single aggregate query on the DB and not load all
# members
ok($t->rollback(), 'Rollback changes');
$t = UR::Context::Transaction->begin();
{
    ok(URT::Person->unload(), 'Unload all Person objects');
    my $p = URT::Person->get(11);
    is(scalar(@{[URT::Person->is_loaded]}), 1, 'One Person object is loaded');

    $aggr_query_count = 0;
    is($cool_person_set->count, 3, 'set membership count is still the same');
    is($aggr_query_count, 1, 'count made an aggregate query');
    is(scalar(@{[URT::Person->is_loaded]}), 1, 'Still, one Person object is loaded');

    $aggr_query_count = $age_accessor_called = 0;
    is($cool_person_set->sum('age'), 110, 'Get sum(age)');
    is($aggr_query_count, 1, 'count made an aggregate query');
    is($age_accessor_called, 0, '"age" accessor was not called');
    is(scalar(@{[URT::Person->is_loaded]}), 1, 'Still, one Person object is loaded');

    ok($cool_person_set->rule->evaluate($p), 'person is member of cool person set');
    ok($p->name('AAAA'), 'changed the name of the person to AAAA');

    ok($cool_person_set->_members_have_changes, 'cool person set now has changes');

    # After changing the name, count and sum should still be valid cached values
    $aggr_query_count = 0;
    is($cool_person_set->count, 3, 'set membership count is still the same');
    is($aggr_query_count, 0, 'count did not trigger query');

    $aggr_query_count = 0;
    is($cool_person_set->sum('age'), 110, 'Get sum(age)');
    is($aggr_query_count, 0, 'sum did not trigger query');
    is($age_accessor_called, 0, '"age" accessor was not called');

    $aggr_query_count = 0;
    is($cool_person_set->min('age'), 25, 'Minimum age is 25');
    is($age_accessor_called, 0, "'age' accessor was not called");  # ran in the DB
    is($aggr_query_count, 1, 'Did one aggregate query');
    is(scalar(@{[URT::Person->is_loaded]}), 1, 'Still, one Person object is loaded');

    $aggr_query_count = 0;
    is($cool_person_set->min('name'), 'AAAA', 'Minimum name is AAAA');
    is($aggr_query_count, 0, 'Made no aggregate queries');
    is(scalar(@{[URT::Person->is_loaded]}), 3, 'All 3 Person objects were loaded that are is_cool');

    # After changing the name, the min(age) value should still be cached
    $age_accessor_called = $aggr_query_count = 0;
    is($cool_person_set->min('age'), 25, 'Minimum age is 25');
    is($age_accessor_called, 0, "'age' accessor was not called");
    is($aggr_query_count, 0, 'Did no aggregate queries');


    # Now, change age, and test that it has to re-calculate the age-dependant aggregates
    # but not the name-related aggregate
    ok($p->age(26), 'Change person age to 26');
    $age_accessor_called = 0;
    is($cool_person_set->sum('age'), 111, 'Get sum(age)');
    is($aggr_query_count, 0, 'sum did not trigger query');
    is($age_accessor_called, 1, '"age" accessor was called');

    $age_accessor_called = 0;
    is($cool_person_set->min('age'), 26, 'Minimum age is 26');
    is($age_accessor_called, 1, "'age' accessor was called");

    $name_accessor_called = 0;
    is($cool_person_set->min('name'), 'AAAA', 'Minimum name is AAAA');
    is($name_accessor_called, 0, "'name' accessor was not called");
}

# Test that changing set membership invalidates the whole cache of aggregate values
ok($t->rollback(), 'Rollback changes');
$t = UR::Context::Transaction->begin();
{
    my $p = URT::Person->get(11);

    is($cool_person_set->min('age'), 25, 'Minimum age is 25');
    is($cool_person_set->sum('age'), 110, 'Get sum(age)');
    is($cool_person_set->min('name'), 'Bob', 'Minimum name is Bob');

    ok(defined($p->is_cool(0)), 'Set person to be not cool');

    $age_accessor_called = 0;
    is($cool_person_set->min('age'), 40, 'Minimum cool age is 40');
    is($age_accessor_called, 1, "'age' accessor was called");

    $age_accessor_called = 0;
    is($cool_person_set->sum('age'), 85, 'Get cool sum(age)');
    is($age_accessor_called, 1, '"age" accessor was called');

    $name_accessor_called = 0;
    is($cool_person_set->min('name'), 'Frank', 'Minimum cool name is Frank');
    is($name_accessor_called, 1, "'name' accessor was called");
}

# Test that changing a property on an object of the same class, but not a member
# of the set, does not invalidate cached aggregate values
ok($t->rollback(), 'Rollback changes');
{
    my $p = URT::Person->get(12);
    is($p->is_cool, 0, 'Got an uncool person');

    is($cool_person_set->min('age'), 25, 'Minimum cool age is 25');
    is($cool_person_set->sum('age'), 110, 'Get cool sum(age)');
    is($cool_person_set->min('name'), 'Bob', 'Minimum cool name is Bob');

    ok($p->age(99), "Change uncool person's age");
    ok($p->name('goo'), "Change uncool person's name");

    my $check_aggrs = sub {
        $age_accessor_called = 0;
        is($cool_person_set->min('age'), 25, 'Minimum cool age is 25');
        is($age_accessor_called, 0, '"age" accessor was not called');

        $age_accessor_called = 0;
        is($cool_person_set->sum('age'), 110, 'Get cool sum(age)');
        is($age_accessor_called, 0, '"age" accessor was not called');

        $name_accessor_called = 0;
        is($cool_person_set->min('name'), 'Bob', 'Minimum cool name is Bob');
        is($name_accessor_called, 0, '"name" accessor not called');
    };
    $check_aggrs->();

    ok($p->delete, 'Delete the uncool person');
    $check_aggrs->();

    ok(URT::Person->create(is_cool => 0, name => 'Porky Pig', age => 60), 'Create a new uncool person');
    $check_aggrs->();
}
