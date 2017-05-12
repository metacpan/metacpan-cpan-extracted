use strict;
use warnings;
use Test::More tests=> 12;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

# This tests a bugfix where specifying a hints to a property that
# includes a where-clause would omit the where params in the template/rule
# that gets recorded in the query cache.  As a result, a later query could
# incorrectly think it had already been loaded and miss data.

use URT;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got a database handle');

ok($dbh->do('create table PERSON
            ( person_id int NOT NULL PRIMARY KEY, name varchar, is_cool integer )'),
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
        name      => { is => 'String' },
        is_cool   => { is => 'Boolean' },
        cars       => { is => 'URT::Car', reverse_as => 'owner', is_many => 1, is_optional => 1 },
        car_colors => { via => 'cars', to => 'color', is_many => 1, },
        primary_car => { is => 'URT::Car', reverse_as => 'owner', where => ['is_primary true' => 1], is_many => 1 },
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


my $query_count = 0;
my $query_text = '';
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub {$query_text = $_[0]; $query_count++}),
    'Created a subscription for query');


$query_count = 0;
my $person = URT::Person->get(name => 'Bob', -hints => ['primary_car_color']);
ok($person, 'Got a person named Bob');
is($query_count, 1, 'Made 1 query');


$query_count = 0;
my $color = $person->primary_car_color();
is($color, 'yellow', "Bob's primary car color is yellow");
is($query_count, 0, 'Made no queries');


$query_count = 0;
my @cars = URT::Car->get(owner_id => $person->id);
is(scalar(@cars), 2, 'Bob has 2 cars');
is($query_count, 1, 'Made 1 query');


