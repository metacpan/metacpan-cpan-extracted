#!/usr/bin/env perl 

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use URT::DataSource::SomeSQLite;
use Test::More tests => 3;


# tests a get() where the delegated property's join chain has a UR::Value class in the middle
#
# Before the fix, the QueryPlan would see that UR::Values are not resolvable in the DB, and so
# stops trying to connect joins together, leading to multiple queries.  The fix was to splice
# out these non-db joins while constructing the SQL

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

$dbh->do('create table person (person_id integer not null primary key, name varchar not null)');
$dbh->do('create table attribute (attr_id integer not null primary key, person_id integer references person(person_id), key varchar, value varchar)');
$dbh->do('create table car (car_id integer not null primary key, make varchar, model varchar)');

$dbh->do("insert into person values (1,'Bob')");
$dbh->do("insert into car values (2,'Chevrolet','Impala')");
$dbh->do("insert into attribute values (3,1,'car_id', 2)");

UR::Object::Type->define(
    class_name => 'Person',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'person',
    id_by => [
        person_id => { is => 'Integer' },
    ],
    has => [
       name => { is => 'String', },
       attributes => { is => 'Attribute', reverse_as => 'person', is_many => 1 },
       car_id => { is => 'Integer', via => 'attributes', to => 'value', where => [key => 'car_id'] },
       car => { is => 'Car', id_by => 'car_id' },
       car_make => { is => 'String', via => 'car', to => 'make' },
    ],
);

UR::Object::Type->define(
    class_name => 'Attribute',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'attribute',
    id_by => [
        attr_id => { is => 'Integer' },
    ],
    has => [
        person => { is => 'Person', id_by => 'person_id' },
        key => { is => 'String', },
        value => { is => 'String', },
    ],
);

UR::Object::Type->define(
    class_name => 'Car',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'car',
    id_by => [
        car_id => { is => 'Integer' },
    ],
    has => [
        make => { is => 'String' },
        model => { is => 'String' },
    ],
);


my $query_count = 0;
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub { $query_count++ }),
   'Created a subscription for query');
my $p = Person->get(car_make => 'Chevrolet');
ok($p, 'Got the person');
is($query_count, 1, 'Made one query');
