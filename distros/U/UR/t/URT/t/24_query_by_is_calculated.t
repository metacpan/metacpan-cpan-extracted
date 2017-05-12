use strict;
use warnings;
use Test::More tests=> 9;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got a database handle');

ok($dbh->do('create table product
            ( product_id int NOT NULL PRIMARY KEY, product_name varchar, product_type varchar)'),
   'created product table');

ok($dbh->do("insert into product values (1,'race car', 'cool')"),
         'insert row into product for race car');
ok($dbh->do("insert into product values (2,'pencil','notcool')"),
         'insert row into product for pencil');

UR::Object::Type->define(
    class_name => 'URT::Product',
    id_by => 'product_id',
    has => [
        product_name  => { is => 'Text' },
        product_type => { is => 'Text' },
        is_cool      => { is => 'Boolean', calculate_from => 'product_type',
                          calculate => q( return ($product_type eq 'cool') ? 1 : 0 ) },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'product',
);


my @p = URT::Product->get(is_cool => 1);
is(scalar(@p), 1, 'Got one product that is_cool');
is($p[0]->product_name, 'race car', 'name is correct');

@p = URT::Product->get(is_cool => 0);
is(scalar(@p), 1, 'Got one product that is not is_cool');
is($p[0]->product_name, 'pencil', 'name is correct');

@p = URT::Product->get(-hints => ['is_cool']);
is(scalar(@p), 2, 'Getting products with -hints => is_cool got 2 items');
