use strict;
use warnings;
use Test::More tests=> 12;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

# This test tries getting a property delegated through an object accessor
# with an id_class_by, effectively making it doubly-delegated
#
# In this situation, the accessor should collect the bridge objects
# (Inventory in this test), bucket them by final result class, and
# then do a single get() for each result class with the IDs of 
# the result items collected from the bridge objects

use URT;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got a database handle');

ok($dbh->do('create table PERSON
            ( person_id int NOT NULL PRIMARY KEY, name varchar)'),
   'created person table');
ok($dbh->do('create table INVENTORY
            ( inv_id int NOT NULL PRIMARY KEY, owner_id integer, value_id varchar, value_class varchar, category varchar)'),
   'created inventory table');
ok($dbh->do('create table PROPERTY
             ( property_id int NOT NULL PRIMARY KEY, name varchar, size integer)'),
    'created item table');
ok($dbh->do('create table ITEM
             ( item_id int NOT NULL PRIMARY KEY, name varchar, size integer)'),
    'created item table');


UR::Object::Type->define(
    class_name => 'URT::OwnedThing',
    is_abstract => 1,
);

UR::Object::Type->define(
    class_name => 'URT::Property',
    is => 'URT::OwnedThing',
    doc => 'Things someone can own that has a record of title',
    id_by => 'property_id',
    has => ['name','size'],
    table_name => 'PROPERTY',
    data_source => 'URT::DataSource::SomeSQLite',
);

UR::Object::Type->define(
    class_name => 'URT::Item',
    is => 'URT::OwnedThing',
    doc => 'Things someone can own that has no record of title',
    id_by => 'item_id',
    has => ['name','size'],
    table_name => 'ITEM',
    data_source => 'URT::DataSource::SomeSQLite',
);

UR::Object::Type->define(
    class_name => 'URT::Person',
    id_by => 'person_id',
    has => [
        name => { is => 'String' },
    ],
    has_many => [
        inventory => { is => 'URT::Inventory', reverse_as => 'owner' },
        vehicles => { is => 'URT::Property', via => 'inventory', to => 'thing', where => [category => 'vehicles'] },
        money    => { is => 'URT::Item', via => 'inventory', to => 'thing', where => [category => 'money'] },
        things   => { is => 'URT::OwnedItem', via => 'inventory', to => 'thing' },
    ],
    table_name => 'PERSON',
    data_source => 'URT::DataSource::SomeSQLite',
);

UR::Object::Type->define(
    class_name => 'URT::Inventory',
    id_by => 'inv_id',
    has => [
        category => { is => 'String' },

        thing => { is => 'URT::OwnedThing', id_by => 'value_id', id_class_by => 'value_class' },
        owner => { is => 'URT::Person', id_by => 'owner_id' },
    ],
    table_name => 'INVENTORY',
    data_source => 'URT::DataSource::SomeSQLite',
);



# Insert some data
# Bob has 2 cars, a house, 3 pieces of money and a dog
# Fred has 1 car, 1 snowmobile and a cat
my $insert = $dbh->prepare('insert into person values (?,?)');
foreach my $row ( [ 1, 'Bob'], [2,'Fred'] ) {
    $insert->execute(@$row);
}
$insert->finish;

$insert = $dbh->prepare('insert into item values (?,?,?)');
foreach my $row ( [ 1, 'coin', 1], [2, 'dollar', 2], [3, 'coin', 1], [4, 'dog', 10],
                  [ 5, 'cat', 8],
) {
    $insert->execute(@$row);
}
$insert->finish();

$insert = $dbh->prepare('insert into property values (?,?,?)');
foreach my $row ( [ 1, 'blue car', 100], [2, 'house', 1000], [3, 'red car', 200],
                  [ 4, 'yellow car', 100], [5, 'snowmobile', 50],
) {
    $insert->execute(@$row);
}
$insert->finish();

# id, owner_id, value_id, value_class, category
$insert = $dbh->prepare('insert into inventory values (?,?,?,?,?)');
foreach my $row ( [1,  1, 1, 'URT::Item', 'money'],
                  [2,  1, 2, 'URT::Item', 'money'],
                  [3,  1, 3, 'URT::Item', 'money'],
                  [4,  1, 4, 'URT::Item', 'livestock'],
                  [5,  1, 1, 'URT::Property', 'vehicles'],
                  [6,  1, 2, 'URT::Property', 'land'],
                  [7,  1, 3, 'URT::Property', 'vehicles'],
                  [8,  2, 5, 'URT::Item', 'livestock'],
                  [9,  2, 4, 'URT::Property', 'vehicles'],
                  [10, 2, 5, 'URT::Property', 'vehicles'],
) {
    $insert->execute(@$row);
}


my $query_count = 0;
my $query_text = '';
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub {$query_text = $_[0]; $query_count++}),
    'Created a subscription for query');

my $person = URT::Person->get(1);
ok($person, 'Got person object');

$query_count = 0;
my @money = $person->money();
is(scalar(@money), 3, 'person has 3 pieces of money');
is($query_count, 2, 'made 2 queries');  # 1 for the inventory bridges and 1 for all the money items


$person = URT::Person->get(2);
ok($person, 'Got a different person');

$query_count = 0;
my @things = $person->things();
is(@things, 3, 'Second person has 3 things');
is($query_count, 3, 'Made 3 queries'); # 1 for the inventory bridges, 1 for the Items and 1 for the Propertys
