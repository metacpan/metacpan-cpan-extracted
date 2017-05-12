use strict;
use warnings;
use Test::More tests=> 18;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

# Test getting some objects that includes -hints, and then that later get()s
# don't re-query the DB

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
        car_parts => { via => 'cars', to => 'parts', is_optional => 1 },
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


$query_count = 0;
my @people = URT::Person->get(is_cool => 1, -hints => ['car_parts']);
is(scalar(@people), 3, '3 people are cool');
is($query_count, 1, 'Made 1 query');

$query_count = 0;
my @car = $people[0]->cars;
is(scalar(@car), 2, 'Got car objects from first person through accessor');
is($query_count, 0, 'Made no queries');

$query_count = 0;
@car = URT::Car->get(owner_id => $people[0]->id);
is(scalar(@car),2 , 'Got car objects from first person from URT::Car class');
is($query_count, 0, 'Made no queries');


$query_count = 0;
@people = URT::Person->get(is_cool => 1);
is(scalar(@people), 3, '3 people are cool (no hints)');
is($query_count, 0, 'Made no queries');

$query_count = 0;
my @parts = $people[0]->primary_car->parts;
is(scalar(@parts), 2, "First person's car has 2 parts");
is($query_count, 0, 'Made no queries');
