#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace

use File::Temp;
use File::Spec;

my $sqlite_dir = File::Temp::tempdir( CLEANUP => 1 );

create_dir_with_schema_files($sqlite_dir);
define_classes($sqlite_dir);

my $person = URT::Person->get(car_make => 'ford');
is($person->name, 'bob', 'bob owns the ford');

$person = URT::Person->get(car_model => 'model s');
is($person->name, 'fred', 'fred owns the mode s');

$person = URT::Person->get(car_model => 'hupmobile');
ok(!$person, 'no one owns a hupmobile');

sub create_dir_with_schema_files {
    my$sqlite_dir = shift;
    my $main_schema_file = File::Spec->catfile($sqlite_dir, 'main.sqlite3');
    my $main_dbh = DBI->connect("dbi:SQLite:dbname=$main_schema_file",'','')
            || die "Can't create main schema file in dir $sqlite_dir: ".$DBI::errstr;
    $main_dbh->do('create table person (person_id integer primary key, name varchar)');
    $main_dbh->do("insert into person values (1, 'bob')");
    $main_dbh->do("insert into person values (2, 'fred')");

    my $car_schema_file = File::Spec->catfile($sqlite_dir, 'cars.sqlite3');
    my $car_dbh = DBI->connect("dbi:SQLite:dbname=$car_schema_file",'','')
            || die "Can't create cars schema file in dir $sqlite_dir: ".$DBI::errstr;
    $car_dbh->do('create table car (car_id integer primary_key, owner_id integer not null, make varchar, model varchar)');
    $car_dbh->do("insert into car values (1, 1, 'ford','galaxie')");
    $car_dbh->do("insert into car values (2, 1, 'chrysler', 'airstream')");
    $car_dbh->do("insert into car values (3, 2, 'tesla', 'model s')");
}

sub define_classes {
    my $sqlite_dir = shift;

    UR::Object::Type->define(
        class_name => 'URT::DataSource::SQLiteDir',
        is => 'UR::DataSource::SQLite',
        has_constant => [
            server => { value => $sqlite_dir },
        ],
    );

    UR::Object::Type->define(
        class_name => 'URT::Person',
        id_by => 'person_id',
        has => [
            name => { is => 'String' },
            cars => { is_many => 1, reverse_as => 'owner', is => 'URT::Car' },
            car_make => { via => 'cars', to => 'make' },
            car_model => { via => 'cars', to => 'model' },
        ],
        data_source => 'URT::DataSource::SQLiteDir',
        table_name => 'main.person',
    );

    UR::Object::Type->define(
        class_name => 'URT::Car',
        id_by => 'car_id',
        has => [
            owner => { id_by => 'owner_id', is => 'URT::Person' },
            make => { is => 'String' },
            model => { is => 'String' },
        ],
        data_source => 'URT::DataSource::SQLiteDir',
        table_name => 'cars.car',
    );
}

