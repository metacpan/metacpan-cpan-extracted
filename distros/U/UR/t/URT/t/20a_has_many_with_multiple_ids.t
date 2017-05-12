#!/usr/bin/env perl 

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use URT;
use Test::More tests => 11;

UR::Object::Type->define(
    class_name => 'URT::Order',
    table_name => 'orders',
    id_by => [
        order_id    => { is => 'integer', is_optional => 1, column_name => 'order_id' },
    ],
    has_many => [
        attributes      => { is => 'URT::OrderAttribute', reverse_as => 'order' },
        tracking_number => { is => 'String', via => 'attributes', to => 'value', where => [key => 'tracking_number'], is_mutable => 1},
        ship_date       => { is => 'String', via => 'attributes', to => 'value', where => [key => 'ship_date'], is_mutable => 1},
    ],
    data_source => 'URT::DataSource::SomeSQLite',
);

UR::Object::Type->define(
    class_name => 'URT::OrderAttribute',
    id_by => [
        order    => { is => 'URT::Order', id_by => 'order_id' },
        key      => { is => 'String' },
        value    => { is => 'String' },
    ],
    table_name => 'order_attributes',
    data_source => 'URT::DataSource::SomeSQLite',
);


my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
$dbh->do("create table orders (order_id integer NOT NULL PRIMARY KEY)");
$dbh->do("create table order_attributes ( order_id integer NOT NULL references orders(order_id),
                                          key varchar NOT NULL,
                                          value varchar NOT NULL,
                                          PRIMARY KEY(order_id, key,value))");
$dbh->do("insert into orders values (99)");
$dbh->do("insert into order_attributes values (99,'tracking_number','abc123')");
$dbh->do("insert into order_attributes values (99,'ship_date','2011 Jan 1')");


my $o = URT::Order->get(99);
ok($o, 'Retrieved an order');
is($o->tracking_number, 'abc123', 'tracking_number attribute is OK');
is($o->ship_date, '2011 Jan 1', 'ship_date attribute is OK');


$o = URT::Order->create(id => 1);
ok($o, "order object created");

ok($o->add_attribute(key => 'tracking_number', value => 'xyzzy'), 'Added tracking number attribute');
ok($o->add_ship_date('2011 Jan 7'), 'Added ship date');

ok(UR::Context->commit(), 'Commit');

my $rows = $dbh->selectrow_arrayref('select * from orders where order_id = 1');
ok($rows, 'Got row for order 1 from DB');
is($rows->[0], 1,'order_id is correct');

$rows = $dbh->selectall_arrayref('select * from order_attributes where order_id = 1 order by key');
ok($rows, 'Got attributes for order_id 1');
my $expected = [ [1,'ship_date','2011 Jan 7'], [1,'tracking_number','xyzzy']];
is_deeply($rows, $expected, 'Attribute data is ok');


