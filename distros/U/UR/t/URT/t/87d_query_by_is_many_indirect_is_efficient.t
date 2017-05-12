use strict;
use warnings;
use Test::More tests=> 22;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got a database handle');

ok($dbh->do('create table MAINTABLE
            ( main_id int NOT NULL PRIMARY KEY, name varchar )'),
   'created person table');
ok($dbh->do('create table RELATED1
            (related1_id int NOT NULL PRIMARY KEY, related_id integer REFERENCES maintable(main_id), value varchar)'),
    'created related1 table');
ok($dbh->do('create table RELATED2
            (related2_id int NOT NULL PRIMARY KEY, related_id integer REFERENCES related1(related1_id), value varchar)'),
    'created related2 table');
ok($dbh->do('create table RELATED3
            (related3_id int NOT NULL PRIMARY KEY, related_id integer REFERENCES related2(related2_id), value varchar)'),
    'created related3 table');
ok($dbh->do('create table RELATED4
            (related4_id int NOT NULL PRIMARY KEY, related_id integer REFERENCES related3(related3_id), value varchar)'),
    'created related4 table');

$dbh->do("insert into maintable values (1,'Bob')");
$dbh->do("insert into related1 values (1,1,'related1')");
$dbh->do("insert into related2 values (1,1,'related2')");
$dbh->do("insert into related3 values (1,1,'related3')");
$dbh->do("insert into related4 values (1,1,'related4')");
$dbh->do("insert into maintable values (2,'Joe')");
$dbh->do("insert into related1 values (2,2,'related1alt')");
$dbh->do("insert into related2 values (2,2,'related2alt')");
$dbh->do("insert into related3 values (2,2,'related3alt')");
$dbh->do("insert into related4 values (2,2,'related4alt')");

ok(UR::Object::Type->define(
    class_name => 'URT::Main',
    table_name => 'maintable',
    id_by => [
        main_id => { is => 'NUMBER' },
    ],
    has => [
        name      => { is => 'String' },
    ],
    has_many => [
        related_1s       => { is => 'URT::Related1', reverse_as => 'related' },
        related_values   => { via => 'related_1s', to => 'value' },
        related_2s       => { is => 'URT::Related2', via => 'related_1s', to => 'related2s' },
        related_2_values => { via => 'related_2s', to => 'value' },
        related_3s       => { is => 'URT::Related3', via => 'related_2s', to => 'related3s' },
        related_3_values => { via => 'related_3s', to => 'value' },
        related_4s       => { is => 'URT::Related4', via => 'related_3s', to => 'related4s' },
        related_4_values => { via => 'related_4s', to => 'value' },

        related_4_values_alt => { via => 'related_1s', to => 'related_4_values_alt' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
),
'Created class for main');

ok(UR::Object::Type->define(
        class_name => 'URT::Related1',
        table_name => 'related1',
        id_by => [
            related1_id =>           { is => 'NUMBER' },
        ],
        has => [
            related => { is => 'URT::Main', id_by => 'related_id' },
            value => { is => 'string' },

            related2s => { is => 'URT::Related2', reverse_as => 'related', is_many => 1},
            related_4_values_alt => { via => 'related2s', to => 'related_4_values_alt' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "Created class for related 1");

ok(UR::Object::Type->define(
        class_name => 'URT::Related2',
        table_name => 'related2',
        id_by => [
            related2_id =>           { is => 'NUMBER' },
        ],
        has => [
            related => { is => 'URT::Related1', id_by => 'related_id' },
            value => { is => 'string' },

            related3s => { is => 'URT::Related3', reverse_as => 'related', is_many => 1},
            related_4_values_alt => { via => 'related3s', to => 'related_4_values_alt' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "Created class for related 2");

ok(UR::Object::Type->define(
        class_name => 'URT::Related3',
        table_name => 'related3',
        id_by => [
            related3_id =>           { is => 'NUMBER' },
        ],
        has => [
            related => { is => 'URT::Related2', id_by => 'related_id' },
            value => { is => 'string' },

            related4s => { is => 'URT::Related4', reverse_as => 'related', is_many => 1},
            related_4_values_alt => { via => 'related4s', to => 'value' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "Created class for related 3");

ok(UR::Object::Type->define(
        class_name => 'URT::Related4',
        table_name => 'related4',
        id_by => [
            related4_id =>           { is => 'NUMBER' },
        ],
        has => [
            related => { is => 'URT::Related3', id_by => 'related_id' },
            value => { is => 'string' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "Created class for related 4");


my $query_count = 0;
my $query_text = '';
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub {$query_text = $_[0]; $query_count++}),
    'Created a subscription for query');
my $thing;

$query_count = 0;
#$DB::single=1;
$thing = URT::Main->get(related_4_values => 'related4');
ok($thing, 'Got one object for a 5-table join');
is($query_count, 1, 'Made 1 query');

$query_count = 0;
$thing = URT::Related1->get(related_id => 1);
ok($thing, 'Got 1 related URT::Related1 thing by related_id');
is($query_count, 0, 'Made no queries');

$query_count = 0;
$thing = URT::Related2->get(related_id => 1);
ok($thing, 'Got 1 related URT::Related2 thing by related_id');
is($query_count, 0, 'Made no queries');

$query_count = 0;
$thing = URT::Related3->get(related_id => 1);
ok($thing, 'Got 1 related URT::Related3 thing by related_id');
is($query_count, 0, 'Made no queries');

$query_count = 0;
$thing = URT::Related4->get(related_id => 1, value => 'related4');
ok($thing, 'Got 1 related URT::Related4 thing by related_id');
is($query_count, 0, 'Made no queries');

