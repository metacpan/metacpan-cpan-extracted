use strict;
use warnings;
use Test::More tests=> 22;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

&create_tables_and_classes();

my $p1 = URT::Product->get(1);
ok(!$p1, 'Get by non-existent ID correctly returns nothing');

my $p2 = URT::Product->create(id => 1, name => 'jet pack', genius => 6, manufacturer_name => 'Lockheed Martin',cost => 5);
ok($p2, 'Create a new Product with the same ID');

$p1 = URT::Product->get(1);
ok($p1, 'Get with the same ID returns something, now');

is($p1->id, 1, 'ID is correct');
is($p1->name, 'jet pack', 'name is correct');
is($p1->genius, 6, 'name is correct');
is($p1->manufacturer_name, 'Lockheed Martin', 'name is correct');

my $p3 = URT::Product->get(100);
ok($p3, 'Retrieve product with ID 100');
is($p3->cost, 100, 'Its cost is 100');
is($p3->genius, 1, 'Its genius is 1');
ok($p3->cost(5000), 'Change cost to 5000');
ok($p3->genius(99), 'Change genius to 99');

my $p4 = URT::Product->get(101);
ok($p4, 'Retrieve product with ID 101');
ok($p4->delete, 'Delete it');

ok(UR::Context->commit(), 'Commit');

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
my $sth = $dbh->prepare('select * from product');
$sth->execute();
my %products_by_id;
while (my $row = $sth->fetchrow_hashref) {
    my %copy = %$row;
    $products_by_id{$copy{'product_prod_id'}} = \%copy;
}
$sth->finish;

is(scalar(keys %products_by_id), 2, 'There were 2 products in the database');

my $expected = { 
    1 => { 
        product_prod_id => 1,
        product_name => 'jet pack',
        product_genius => 6,
        product_mfg_name => 'Lockheed Martin',
        cost => 5,
    },
    100 => {
        product_prod_id => 100,
        product_name => 'Something to update',
        product_genius => 99,
        product_mfg_name => 'Acme',
        cost => 5000,
    },
};
is_deeply(\%products_by_id, $expected, 'Data in DB is as expected');

#note(Data::Dumper::Dumper(\%products_by_id));



sub create_tables_and_classes {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    ok($dbh, 'Got a database handle');
 
    ok($dbh->do('create table PRODUCT
                ( product_prod_id int NOT NULL PRIMARY KEY, product_name varchar, product_genius integer, product_mfg_name varchar, cost integer)'),
       'created product table');

    ok(UR::Object::Type->define(
            class_name => 'URT::Product',
            table_name => 'PRODUCT',
            id_by => [
                prod_id =>           { is => 'NUMBER', sql => 'product_prod_id' },
            ],
            has => [
                name =>              { is => 'STRING', sql => 'product_name' },
                genius =>            { is => 'NUMBER', sql => 'product_genius' },
                manufacturer_name => { is => 'STRING', sql => 'product_mfg_name' },
                cost =>              { is => 'NUMBER' },
            ],
            data_source => 'URT::DataSource::SomeSQLite',
        ),
        "Created class for Product");

    ok($dbh->do("insert into product (product_prod_id,product_name,product_genius,product_mfg_name,cost) values (100,'Something to update',1,'Acme',100)"), 'Inserted item 1');
    ok($dbh->do("insert into product (product_prod_id,product_name,product_genius,product_mfg_name,cost) values (101,'Something to delete',1,'Acme',200)"), 'Inserted item 101');

    $dbh->commit();
}

