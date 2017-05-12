use strict;
use warnings;
use Test::More tests=> 15;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

# Tests that calling car_parts_prices on a URT::Person object is efficient
# The AccessorWriter does the retrieval differently if these conditions hold:
#     1) car_parts_prices is_delegated and is_many
#     2) the thing it is 'via' (cars) is an object accessor (has a data_type: URT::Car) and is_many
#     3) the thing it is 'to' (parts_prices) is_delegated and has a via as well
#     4) parts_prices is via something that is an object accessor with a data_type (URT::CarParts)
#
# If these hold, then it can do the query differently:
#     1) Call URT::Car->get() with appropriate params that $person->cars would use
#     2) For each of the objects resulting from #1 (URT::Car), extract out the value that links
#        these to the final class (URT::CarParts)
#     3) Do a get on the final class filtering on the linking property and an 'in' clause
#        with the values from #2

use URT;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got a database handle');

ok($dbh->do('create table PERSON
            ( person_id int NOT NULL PRIMARY KEY, name varchar, is_cool integer )'),
   'created person table');
ok($dbh->do('create table CAR
            ( car_id int NOT NULL PRIMARY KEY, color varchar, is_primary int, owner_id integer references PERSON(person_id))'),
   'created car table');
ok($dbh->do('create table car_parts
             ( part_id int NOT NULL PRIMARY KEY, name varchar, price integer, car_id integer references CAR(car_id))'),
    'created car_parts table');

ok(UR::Object::Type->define(
    class_name => 'URT::Person',
    table_name => 'PERSON',
    id_by => [
        person_id => { is => 'NUMBER' },
    ],
    has => [
        name      => { is => 'String' },
        is_cool   => { is => 'Boolean' },
        cars       => { is => 'URT::Car', reverse_as => 'owner', is_many => 1, is_optional => 1 },
        primary_car => { is => 'URT::Car', via => 'cars', to => '__self__', where => ['is_primary true' => 1] },
        primary_car_parts => { via => 'primary_car', to => 'parts' },
        car_color => { via => 'cars', to => 'color' },

        car_parts => { is => 'URT::CarParts', via => 'cars', to => 'parts', is_optional => 1, is_many => 1 },
        car_parts_prices => { via => 'cars', to => 'parts_prices', is_optional => 1, is_many => 1 },
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
            parts   => { is => 'URT::CarParts', reverse_as => 'car', is_many => 1 },
            parts_prices => { via => 'parts', to => 'price', is_many => 1},
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "Created class for Car");

ok(UR::Object::Type->define(
        class_name => 'URT::CarParts',
        table_name => 'CAR_PARTS',
        id_by => 'part_id',
        has => [
            name => { is => 'String' },
            price => { is => 'Integer' },
            car   => { is => 'URT::Car', id_by => 'car_id' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "Created class for CarParts");
        


# Insert some data
# Bob and Mike have red cars, Fred and Joe have blue cars.  Frank has no car.  Bob, Joe and Frank are cool
# Bob also has a yellow car that's his primary car
my $insert = $dbh->prepare('insert into person values (?,?,?)');
foreach my $row ( [ 1, 'Bob',1 ], [2, 'Fred',0], [3, 'Mike',0],[4,'Joe',1], [5,'Frank', 1] ) {
    $insert->execute(@$row);
}
$insert->finish();

$insert = $dbh->prepare('insert into car values (?,?,?,?)');
foreach my $row ( [ 1,'red',0,  1], [ 2,'blue',1, 2], [3,'red',1,3],[4,'blue',1,4],[5,'yellow',1,1] ) {
    $insert->execute(@$row);
}
$insert->finish();

# Bob's non-primary car has wheels and engine,
# Bob's primary car has custom wheels and neon lights
# Fred's car has wheels and seats
# Mike's car has engine and radio
# Joe's car has seats and radio
$insert = $dbh->prepare('insert into car_parts values (?,?,?,?)');
foreach my $row ( [1, 'wheels', 100, 1],
                  [2, 'engine', 200, 1],
                  [3, 'wheels', 100, 2],
                  [4, 'seats',  50,  2],
                  [5, 'engine', 200, 3],
                  [6, 'radio',  50,  3],
                  [7, 'seats',  50,  4],
                  [8, 'radio',  50,  4],
                  [9, 'custom wheels', 200, 5],
                  [10,'neon lights',   100, 5],
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
my @colors = $person->cars();
is(scalar(@colors), 2, 'person has 2 cars with colors');
is($query_count, 1, 'made 1 query');


$query_count = 0;
my @prices = $person->car_parts_prices();
is(scalar(@prices), 4, "person's cars have 4 car_parts with prices");
is($query_count, 1, 'Made 1 query');

URT::CarParts->unload();
$query_count = 0;
my @parts = $person->car_parts;
is($query_count, 1, 'Made 1 query getting car_parts for person');
my @parts_ids = sort { $a <=> $b }
                map { $_->id } @parts;
is_deeply(\@parts_ids,
          [1, 2, 9, 10],
          'Got the correct CarParts objects');
