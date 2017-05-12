use strict;
use warnings;
use Test::More tests=> 18;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

&create_tables_and_classes();

my $p1 = URT::Product->get(1);
ok(!$p1, 'Get by non-existent ID correctly returns nothing');

my $p2 = URT::Product->create(id => 1, name => 'jet pack', genius => 6, manufacturer_name => 'Lockheed Martin',sc => 'URT::TheSubclass');
ok($p2, 'Create a new Product with the same ID');

$p1 = URT::Product->get(1);
ok($p1, 'Get with the same ID returns something, now');

is($p1->id, 1, 'ID is correct');
is($p1->name, 'jet pack', 'name is correct');
is($p1->genius, 6, 'name is correct');
is($p1->manufacturer_name, 'Lockheed Martin', 'name is correct');

my @prods = URT::Product->get('genius between' => [1,10]);
is(scalar(@prods), 1, 'get() with between works');

my $composite_id = join("\t", 1, 2);
my $m = URT::MultiIdThing->get($composite_id);
ok($m, 'Got MultiIdThing by composite ID');
is($m->id1, 1, 'id1 value');
is($m->id2, 2, 'id2 value');
is($m->value, 'test value', 'value value');
 

sub create_tables_and_classes {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    ok($dbh, 'Got a database handle');
 
    ok($dbh->do('create table PRODUCT
                ( prod_id int NOT NULL PRIMARY KEY, name varchar, genius integer, manufacturer_name varchar, sc varchar)'),
       'created product table');

    ok($dbh->do('create table MULTI_ID_THING
                ( id1 int NOT NULL, id2 int NOT NULL, value varchar, PRIMARY KEY (id1, id2))'),
        'created multi id thing table');
    $dbh->do(q(insert into MULTI_ID_THING values (1, 2, 'test value')));

    ok(UR::Object::Type->define(
            class_name => 'URT::Product',
            table_name => 'PRODUCT',
            is_abstract => 1,
            id_by => [
                prod_id =>           { is => 'NUMBER' },
            ],
            has => [
                name =>              { is => 'STRING' },
                genius =>            { is => 'NUMBER' },
                manufacturer_name => { is => 'STRING' },
                sc                => { is => 'String' },
            ],
            subclassify_by => 'sc',
            data_source => 'URT::DataSource::SomeSQLite',
        ),
        "Created class for Product");

    ok(UR::Object::Type->define(
            class_name => 'URT::TheSubclass',
            is => 'URT::Product',
        ),
        "Created class for TheSubclass");

    ok(UR::Object::Type->define(
            class_name => 'URT::MultiIdThing',
            table_name => 'MULTI_ID_THING',
            id_by => ['id1','id2'],
            has => ['value'],
            data_source => 'URT::DataSource::SomeSQLite',
        ),
        'Created class for MultiIdThing');
}

