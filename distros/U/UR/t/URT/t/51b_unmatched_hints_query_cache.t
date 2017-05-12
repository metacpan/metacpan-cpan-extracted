#!/usr/bin/env perl 

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";

use UR;
use URT;

use Test::More tests => 23;

# When doing a get that includes a delegated property, and the delegation
# does not match anything, make sure a later query correctly does not re-query
# the database

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
ok($dbh, 'Got DB handle');

$dbh->do('create table manufacturer (mfg_id integer NOT NULL PRIMARY KEY, name varchar)');
$dbh->do('create table model (model_id integer NOT NULL PRIMARY KEY, name varchar, mfg_id integer REFERENCES manufacturer(mfg_id))');

my $insert = $dbh->prepare('insert into manufacturer values (?,?)');
ok($insert, 'Insert manufacturers');
foreach my $row ( [1,'Ford'], [2,'Toyota'], [3,'Packard']) {
    $insert->execute(@$row);
}
$insert->finish;

# Ford has 2 models: Focus and F150
# Toyota has 2 models: Prius and Tundra
# Packard and Desoto have no models
$insert = $dbh->prepare('insert into model values (?,?,?)');
ok($insert, 'Insert models');
foreach my $row ( [1,'Focus',1], [2,'F150',1], [3,'Prius',2], [4,'Tundra', 2] ) {
    $insert->execute(@$row);
}
$insert->finish;


UR::Object::Type->define(
    class_name => 'URT::Manufacturer',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'manufacturer',
    id_by => [
        mfg_id    => { is => 'integer' },
    ],
    has => [
        name      => { is => 'String' },
        models    => { is => 'URT::Model', is_many => 1, reverse_as => 'manufacturer', is_optional => 1 },
        #model_ids => { via => 'models', to => 'model_id', is_many => 1, is_optional => 1 },
        model_ids => { via => 'models', to => 'model_id', is_many => 1, is_optional => 1 },
    ],
);

UR::Object::Type->define(
    class_name => 'URT::Model',
    table_name => 'model',
    data_source => 'URT::DataSource::SomeSQLite',
    id_by => [
        model_id => { is => 'Integer' },
    ],
    has => [
        name              => { is => 'String' },
        manufacturer      => { is => 'URT::Manufacturer', id_by => 'mfg_id' },
        manufacturer_name => { via => 'manufacturer', to => 'name' },
    ],
);


my $query_count = 0;
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub {$query_count++}),
    'Created a subscription for query');


# Test a get() with hints
$query_count = 0;
my @mfg = URT::Manufacturer->get(id => 1, -hints => ['model_ids']);
is(scalar(@mfg),1, 'Got 1 manufacturer with id 1');
is($query_count, 1, 'Made 1 query');


$query_count = 0;
my @models = URT::Model->get(1);  # model_id 1 should have been loaded by the above mfg get()
is(scalar(@models), 1, 'Get model by id 1 got one object');
is($query_count, 0, 'Made no queries');


$query_count = 0;
@models = URT::Model->get(mfg_id => 1);  # These should also have been loaded before
is(scalar(@models), 2, 'Two models with mfg_id => 1');
is($query_count, 0, 'Made no queries');


# Test a get() with a delegated property
$query_count = 0;
@mfg = URT::Manufacturer->get(model_ids => 3);
is(scalar(@mfg), 1, 'Got 1 manufacturer with model_id 3');
is($mfg[0]->name, 'Toyota', 'Was the right manufacturer');
is($query_count, 1, 'Made 1 query');


$query_count = 0;
@models = URT::Model->get(model_id => 3);    # Should have been loaded by mfg get() with model_id 3
is(scalar(@models), 1, 'Got 1 model with model_id 3');
is($query_count, 0, 'Made no queries');


# test a get() with hints where the hinted property matches nothing
$query_count = 0;
@mfg = URT::Manufacturer->get(id => 3, -hints => ['model_ids']);
is(scalar(@mfg), 1, 'Got 1 manufacturer with id 3');
is($query_count, 1, 'Made 1 query');


$query_count = 0;
@models = URT::Model->get(mfg_id => 3);   # Should have been loaded as part of the mfg get() with id 3
is(scalar(@models), 0, 'Got no models with mfg_id 3');
is($query_count, 0, 'Made no queries');



# This is to avoid an additional query in the next get() when objects are
# indexed.  It's a side-effect of model_ids being is_many, and the Index
# not indexing by is_many properties
URT::Model->get(mfg_id => 2);

# Test a get() by delegated property that matches nothing
$query_count = 0;
@mfg = URT::Manufacturer->get(model_ids => 99);
is(scalar(@mfg), 0, 'Got no manufacturers with model_id 99');
is($query_count, 1, 'Made 1 query');


$query_count = 0;
@models = URT::Model->get(model_id => 99);
is(scalar(@models), 0, 'Got no models with model_id 99');
SKIP: {
    skip "via properties don't record info in all_params_loaded yet", 1;
    is($query_count, 0, 'Made no queries');
}


1;


