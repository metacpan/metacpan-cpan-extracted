#!/usr/bin/env perl 

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use URT::DataSource::SomeSQLite;
use Test::More tests => 19;

# This test does a query that joins three tables.
# The get() is done on an is-many property, and its reverse_as is a delegated
# property through a third class

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

$dbh->do('create table car (car_id integer not null primary key, model varchar not null)');
$dbh->do('create table driver (driver_id integer not null primary key, name varchar not null)');
$dbh->do('create table car_driver (car_id integer not null references car(car_id), driver_id integer not null references driver(driver_id))');

$dbh->do("insert into car values (1,'batmobile')");
$dbh->do("insert into car values (2,'race car')");
$dbh->do("insert into car values (3,'mach 5')");
$dbh->do("insert into car values (4,'junked car')");

$dbh->do("insert into driver values (1,'batman')");
$dbh->do("insert into driver values (2,'mario')");
$dbh->do("insert into driver values (3,'speed racer')");
$dbh->do("insert into driver values (4,'superman')");

# batman drives the batmobile
$dbh->do("insert into car_driver values (1,1)");

# mario and speed racer drive the race car
$dbh->do("insert into car_driver values (2,2)");
$dbh->do("insert into car_driver values (2,3)");

# speed racer also drives the mach 5
$dbh->do("insert into car_driver values (3,3)");

# superman doesn't drive anything
# no one drives the junked car

UR::Object::Type->define(
    class_name => 'URT::Car',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'car',
    id_by => [
        car_id => { is => 'Integer' },
    ],
    has => [
        model => { is => 'String', },
    ],
    has_many => [
        car_drivers  => { is => 'URT::CarDriver', reverse_as => 'car' },
        drivers      => { is => 'URT::Driver', via => 'car_drivers', to => 'driver' },  # regular many-to-many property def'n
        driver_names => { is => 'String', via => 'drivers', to => 'name' },
    ],
);

UR::Object::Type->define(
    class_name => 'URT::Driver',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'driver',
    id_by => [
        driver_id => { is => 'Integer' },
    ],
    has => [
        name => { is => 'String' },
    ],
    has_many => [
        cars       => { is => 'URT::Car', reverse_as => 'drivers' }, # not the usual way to make a many-to-many property def'n
        car_models => { is => 'String', via => 'cars', to => 'model' },
    ],
);

UR::Object::Type->define(
    class_name => 'URT::CarDriver',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'car_driver',
    id_by => [
        car_id   => { is => 'Integer' },
        driver_id => { is => 'Integer' },
    ],
    has => [
        car    => { is => 'URT::Car', id_by => 'car_id' },
        driver => { is => 'URT::Driver', id_by => 'driver_id' },
    ],
);


my $query_count = 0;
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub { $query_count++ }),
   'Created a subscription for query');

$query_count = 0;
my $driver = URT::Driver->get(name => 'batman');
ok($driver, 'got the batman driver');
is($query_count, 1, 'Made 1 query');

$query_count = 0;
my @cars = $driver->cars();
is(scalar(@cars), 1, 'batman drives 1 car');
is($query_count, 1, 'Made 1 query');
is($cars[0]->model, 'batmobile', 'It is the right car');

$query_count = 0;
@cars = $driver->cars();
is(scalar(@cars), 1, 'trying again, batman drives 1 car');
TODO: {
    local $TODO = "query cache doesn't track properties like drivers.id";
    is($query_count, 0, 'Made no queries');
}
is($cars[0]->model, 'batmobile', 'It is the right car');


$query_count = 0;
my @models = $driver->car_models();
is(scalar(@models), 1, 'batman has 1 car model');
is_deeply(\@models, ['batmobile'], 'Got the right car');
is($query_count, 0, 'Made 0 queries');



$driver = URT::Driver->get(name => 'speed racer');
ok($driver, 'Got speed racer');

$query_count = 0;
@models = $driver->car_models();
is(scalar(@models), 2, 'speed racer drives 2 cars');
@models = sort @models;
is_deeply(\@models, ['mach 5', 'race car'], 'Got the right cars');
is($query_count, 1, 'Made 1 query');



$driver = URT::Driver->get(name => 'superman');
ok($driver, 'Got superman');

$query_count = 0;
@models = $driver->car_models();
is(scalar(@models), 0, 'superman drives 0 cars');
TODO: {
    local $TODO = "UR::BX::Template->resolve needs to support meta opt -hints to make this work";
    is($query_count, 1, 'Made 1 query');
}
