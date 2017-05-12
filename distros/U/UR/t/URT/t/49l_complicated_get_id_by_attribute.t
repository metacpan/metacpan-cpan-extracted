#!/usr/bin/env perl 

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use URT::DataSource::SomeSQLite;
use Test::More tests => 7;

# This test does a query involving an object accessor, where its id_by is indirect
# through a filtered attribute table.  We're making sure the join from person to
# car_attribute includes conditions on both person.person_id = attr.value _and_
# attr.key = 'owner_id'.
#
# Without that second condition, the query for green cars joins to both people
# because the green car has owner_id 1 and driver_id 2

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

$dbh->do('create table person (person_id integer not null primary key, name varchar not null)');
$dbh->do('create table car (car_id integer not null primary key, color varchar not null)');
$dbh->do('create table car_attribute (attr_id integer not null primary key, car_id integer not null, key varchar, value varchar)');

# Bob and Fred are people
$dbh->do("insert into person values (1,'Bob')");
$dbh->do("insert into person values (2,'Fred')");

# Bob has a green and yellow car, Fred has a black car
$dbh->do("insert into car values (1, 'green')");
$dbh->do("insert into car values (2, 'yellow')");
$dbh->do("insert into car values (3, 'black')");

$dbh->do("insert into car_attribute values (1, 1, 'owner_id', 1)");
$dbh->do("insert into car_attribute values (2, 1, 'driver_id', 2)");  # Also, Fred drives Bob's green car
$dbh->do("insert into car_attribute values (4, 1, 'owner_id', 1)");
$dbh->do("insert into car_attribute values (7, 3, 'owner_id', 2)");


UR::Object::Type->define(
    class_name => 'URT::Person',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'person',
    id_by => [
        person_id => { is => 'Text' },
    ],
    has => [
        name => { is => 'String' },
    ],
    has_many => [
        cars => { is => 'URT::Car', reverse_as => 'owner' },
        car_colors => { via => 'cars', to => 'color' },
    ]
);

UR::Object::Type->define(
    class_name => 'URT::Car',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'car',
    id_by => [
        car_id => { is => 'Integer' },
    ],
    has => [
        color => { is => 'Text' },
        owner_id  => { is => 'Text', via => 'attributes', to => 'value', where => ['key' => 'owner_id']},
        owner => { is => 'URT::Person', id_by => 'owner_id' },
    ],
    has_many => [
        attributes => { is => 'URT::CarAttribute', reverse_as => 'car' },
    ],
);


UR::Object::Type->define(
    class_name => 'URT::CarAttribute',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'car_attribute',
    id_by => [
        attr_id => { is => 'Integer' },
    ],
    has => [
        car => { is => 'URT::Car', id_by => 'car_id' },
        key => { is => 'Text', },
        value => { is => 'Text', },
    ],
);


my $query_count = 0;
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub {
 $query_count++ }),
   'Created a subscription for query');

my @p = URT::Person->get(car_colors => 'green');
is(scalar(@p), 1, 'Got one person with a green car');
is($query_count, 1, 'Made 1 query');

$query_count = 0;
is($p[0]->name, 'Bob', 'It is the right person');
is($query_count, 0, 'Made 0 queries');


# If the query by car_colors worked properly, then this get() should not hit the DB
# because it was loaded as part of the join connecting the car with its owner
$query_count = 0;
my $a = URT::CarAttribute->get(1);
is($query_count, 0, 'Getting car attribute ID 1 took no DB queries');

# But this should hit the DB, because it was for the 'driver_id' attribute, not owner_id
$query_count = 0;
$a = URT::CarAttribute->get(2);
is($query_count, 1, 'Getting car attribute ID 2 (driver_id) took 1 DB query');


