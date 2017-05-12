use strict;
use warnings;
use Test::More tests=> 13;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got a database handle');

ok($dbh->do('create table product
            ( product_id int NOT NULL PRIMARY KEY, product_name varchar, product_class varchar)'),
   'created product table');
ok($dbh->do('create table cool_product
            ( product_id int NOT NULL PRIMARY KEY, coolness integer )'),
   'created cool_product table');

ok($dbh->do("insert into product values (1,'race car', 'URT::Product::Cool')"),
         'insert row into product for race car');
ok($dbh->do("insert into cool_product values (1,10)"),
          'insert row into cool_product for race car');
ok($dbh->do("insert into product values (2,'pencil','URT::Product::NotCool')"),
         'insert row into product for pencil');

UR::Object::Type->define(
    class_name => 'URT::Product',
    is_abstract => 1,
    subclassify_by => 'product_class',
    id_by => 'product_id',
    has => [
        product_name  => { is => 'Text' },
        product_class => { is => 'Text' },
        coolness      => { is_abstract => 1, is_transient => 1 },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'product',
);
UR::Object::Type->define(
    class_name => 'URT::Product::Cool',
    is => 'URT::Product',
    id_by => 'product_id',
    has => [
        coolness => { is => 'Number' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'cool_product',
);
UR::Object::Type->define(
    class_name => 'URT::Product::NotCool',
    is => 'URT::Product',
    id_by => 'product_id',
    has_constant => [
        coolness => { is => 'Number', is_classwide => 1, value => 0  },
    ],
);



my @p = URT::Product->get('coolness >' => 0);
is(scalar(@p), 1, 'Got one product with positive coolness');
isa_ok($p[0], 'URT::Product::Cool');
is($p[0]->product_name, 'race car', 'name is correct');

@p = URT::Product->get(coolness => 0);
is(scalar(@p), 1, 'Got one product with zero coolness');
isa_ok($p[0], 'URT::Product::NotCool');
is($p[0]->product_name, 'pencil', 'name is correct');

@p = URT::Product->get('product_name true' => 1, -hints => ['coolness']);
is(scalar(@p), 2, 'Getting products with -hints => coolness got 2 items');



