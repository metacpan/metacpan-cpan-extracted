#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";

use URT;

use Test::More tests => 20;

# This tests a get() by subclass specific parameters on a subclass with no table of its own.
# The idea is to make sure that queries run with any subclass specific parameters (which can
# be stored in hangoff tables or calculated) do not cause the cache to believe it had loaded
# more objects of that specific subclass than it actually has.

setup_classes_and_db();

my $fido = URT::Dog->get(color => 'black');
ok($fido, 'Got fido by hangoff parameter (color)');
is($fido->name, 'fido', 'Fido has correct name');
is($fido->id, 1, 'Fido has correct id');

my $rex = URT::Dog->get(color => 'brown');
ok($rex, 'Got rex by hangoff parameter (color)');
SKIP: {
    skip 'Failed to get rex, not testing his properties', 2 if !defined $rex;
    is($rex->name, 'rex', 'Rex has correct name');
    is($rex->id, 2, 'Rex has correct id');
};

$fido = URT::Dog->get(tag_id => 1);
ok($fido, 'Got fido by calculated property (tag_id)');
is($fido->name, 'fido', 'Fido has correct name');
is($fido->id, 1, 'Fido has correct id');

$rex = URT::Dog->get(tag_id => 2);
ok($rex, 'Got rex by calculated property (tag_id)');
SKIP: {
    skip 'Failed to get rex, not testing his properties', 2 if !defined $rex;
    is($rex->name, 'rex', 'Rex has correct name');
    is($rex->id, 2, 'Rex has correct id');
};


sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    ok($dbh, 'Got DB handle');

    ok($dbh->do(q{
            create table animal (
                animal_id   integer,
                name        varchar,
                subclass    varchar)}),
        'Created animal table');

    ok($dbh->do(q{
            create table animal_param (
                animal_param_id integer,
                animal_id       integer references animal(animal_id),
                param_name      varchar,
                param_value     varchar)}),
        'Created animal_param table');

    ok($dbh->do("insert into animal (animal_id, name, subclass) values (1,'fido','URT::Dog')"),
        'Inserted fido');
    ok($dbh->do("insert into animal_param (animal_param_id, animal_id, param_name, param_value) values (1, 1, 'color', 'black')"),
        'Turned fido black');

    ok($dbh->do("insert into animal (animal_id, name, subclass) values (2,'rex','URT::Dog')"),
        'Inserted rex');
    ok($dbh->do("insert into animal_param (animal_param_id, animal_id, param_name, param_value) values (2, 2, 'color', 'brown')"),
        'Turned rex brown');
   
    ok($dbh->commit(), 'DB commit');
           
    UR::Object::Type->define(
        class_name => 'URT::Animal',
        id_by => [
            animal_id => { is => 'NUMBER', len => 10 },
        ],
        has => [
            name => { is => 'Text' },
            subclass => { is => 'Text' },
        ],
        has_many_optional => [
            params => { is => 'URT::AnimalParam', reverse_as => 'animal', },
        ],
        is_abstract => 1,
        subclassify_by => 'subclass',
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'animal',
    ); 

    UR::Object::Type->define(
        class_name => 'URT::Dog',
        is => 'URT::Animal',
        has => [
            tag_id => {
                calculate_from => [ 'animal_id' ],
                calculate => q{ return $animal_id; },
            },
            color => { 
                via => 'params',
                is => 'Text',
                to => 'param_value',
                where => [ param_name => 'color', ],
            },
        ],
    );

    UR::Object::Type->define(
        class_name => 'URT::AnimalParam',
        id_by => [
            animal_param_id => { is => 'NUMBER' },
        ],
        has => [
            animal => { id_by => 'animal_id', is => 'URT::Animal' },
            param_name => { is => 'Text' },
            param_value => { is => 'Text' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'animal_param',
    );
}

