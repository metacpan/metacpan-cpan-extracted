use strict;
use warnings;
use Test::More tests=> 12;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

# the initial code is from test 91b, to set-up some joinable data

use URT;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got a database handle');

ok($dbh->do('create table PERSON
            ( person_id int NOT NULL PRIMARY KEY, name varchar)'),
   'created person table');
ok($dbh->do('create table VEHICLE
            ( vehicle_id int NOT NULL PRIMARY KEY, color varchar, subclass_name varchar)'),
   'created car table');
ok($dbh->do('create table REGISTRATION
            (registration_id int NOT NULL PRIMARY KEY, vehicle_id integer, vehicle_class_name varchar, owner_id integer references PERSON(person_id), type varchar)'),
   'created registration table');

ok(UR::Object::Type->define(
    class_name => 'URT::Person',
    table_name => 'PERSON',
    id_by => [
        person_id           => { is => 'Number' },
    ],
    has => [
        name                => { is => 'Text' },
        registrations       => { is => 'URT::Registration', reverse_as => 'owner', is_many => 1 },
        vehicles            => { is => 'URT::Vehicle', via => 'registrations', to => 'vehicle' },
        primary_car         => { is => 'URT::Car', via => 'registrations', to => 'vehicle', where => [type => 'primary'], is_optional => 1 },
        secondary_car       => { is => 'URT::Car', via => 'registrations', to => 'vehicle', where => [type => 'secondary'], is_optional => 1 },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
),
'Created class for people');

ok(UR::Object::Type->define(
    class_name => 'URT::Vehicle',
    is_abstract => 1,
    table_name => 'VEHICLE',
    subclassify_by => 'subclass_name',
    id_by => [
        vehicle_id      => { is => 'Number' },
    ],
    has => [
        color           => { is => 'String' },
        registrations   => { is => 'URT::Registration', reverse_as => 'vehicle', is_many => 1 },
        owner           => { is => 'URT::Person', via => 'registrations', to => 'owner' },
        subclass_name   => { is => 'String' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
), 'created class for Vehicle');

ok(UR::Object::Type->define(
    class_name => 'URT::Car',
    is => ['URT::Vehicle'],
),
"Created class for Car");

ok(UR::Object::Type->define(
        class_name => 'URT::Registration',
        table_name => 'REGISTRATION',
        id_by => [
            registration_id     => { is => 'Number' },
        ],
        has => [
            owner               => { is => 'URT::Person', id_by => 'owner_id' },
            vehicle_id          => { is => 'Number' },
            vehicle_class_name  => { is => 'Text' },
            vehicle             => { is => 'URT::Vehicle', id_by => 'vehicle_id', id_class_by => 'vehicle_class_name' },
            type                => { is => 'Number' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "Created class for Engine");

# Insert some data
# Bob and Mike have red cars, Fred and Joe have blue cars.  Frank has no car.  Bob, Joe and Frank are cool
# Bob also has a yellow car that's his primary car
my $insert = $dbh->prepare('insert into person values (?,?)');
foreach my $row ( [ 11, 'Bob' ], [12, 'Fred'] ) {
    $insert->execute(@$row);
}
$insert->finish();

$insert = $dbh->prepare('insert into vehicle values (?,?,?)');
foreach my $row ( [ 1,'red','URT::Car'], [ 2,'blue','URT::Car'], [3,'red','URT::Car'],[4,'yellow','URT::Car']) {
    $insert->execute(@$row);
}
$insert->finish();

$insert = $dbh->prepare('insert into registration values (?,?,?,?,?)');
foreach my $row ( [101,1,'URT::Car',11,'primary'], [102,2,'URT::Car',11,'secondary'], [103,3,'URT::Car',12,'primary'], [104,4,'URT::Car',12,'secondary']) {
    $insert->execute(@$row);
}
$insert->finish();

my $query_count = 0;
my $query_text = '';

# chain property equiv
my $bx1 = URT::Person->define_boolexpr('primary_car.vehicle_id' => 1, 'secondary_car.vehicle_id' => 2);
ok($bx1, "got bx with property chain");

my @p1 = URT::Person->get($bx1);
is(scalar(@p1), 1, "got one person with the requested cars using a property chain");

my @p2 = URT::Person->get('primary_car.color' => 'red', 'secondary_car.color' => 'yellow');
is(scalar(@p2), 1, "got one person with cars by color");

isnt($p1[0], $p2[0], 'the person with a yellow car is not the person with vehicle 1');
