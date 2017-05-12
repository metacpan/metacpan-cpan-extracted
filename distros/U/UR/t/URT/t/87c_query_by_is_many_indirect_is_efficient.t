use strict;
use warnings;
use Test::More tests=> 20;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

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
        car_color => { via => 'cars', to => 'color', is_many => 1 },

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
foreach my $row ( [ 1, 'Bob',1 ], [2, 'Fred',0], [3, 'Mike',0],[4,'Joe',1], [5,'Frank', 1], [6, 'Hobo Cliff', 0] ) {
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

$query_count = 0;
my @people = URT::Person->get(car_color => 'pink');
is(scalar(@people), 0, 'No person has a pink car');
is($query_count, 1, 'Made 1 query');

$query_count = 0;
@people = URT::Person->get(car_color => 'red');
is(scalar(@people), 2, '2 people have red cars');
is($query_count, 1, 'Made 1 query');

is($people[0]->name, 'Bob', 'Bob is the first person returned');
is($people[1]->name, 'Mike', 'Mike is the second person returned');

$query_count = 0;
my @cars = URT::Car->get(owner_id => $people[1]->id, color => 'red');
is(scalar(@cars), 1, 'Mike has 1 red car');
is($query_count, 0, 'Made no queries');

$query_count = 0;
@cars = URT::Car->get(owner_id => $people[0]->id);
is(scalar(@cars), 2, 'Bob has 2 cars');
is($query_count, 1, 'Made 1 query');  # Needed to query since the first via URT::Person only loaded red cars

$query_count = 0;
@people = URT::Person->get(is_cool => 0, -hints => ['cars']);
is(scalar(@people), 3, "got three people, with a hint to get their cars, when one has no cars");
for my $person (@people) {
    my @cars = $person->cars();
    note("person $person has " . scalar(@cars) . " cars");
}
is($query_count, 1, 'Made 1 query. The hints loaded all the related cars');

