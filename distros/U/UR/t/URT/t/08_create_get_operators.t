use strict;
use warnings;
use Test::More tests => 570;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

my @obj;

use UR;
use URT;

# Singleton classes for testing isa operator
UR::Object::Type->define(
    class_name => 'Acme::Status',
    is => 'UR::Singleton',
);
UR::Object::Type->define(
    class_name => 'Acme::Status::Design',
    is => 'Acme::Status',
);
UR::Object::Type->define(
    class_name => 'Acme::Status::Production',
    is => 'Acme::Status'
);


# memory-only class
UR::Object::Type->define(
    class_name => 'Acme::Product',
    has => ['name', 'manufacturer_name', 'genius', 'status',
        status_obj => { is => 'Acme::Status', id_by => 'status', id_class_by => 'status' },
    ],
);


# same properties, but in the DB
my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
$dbh->do('create table product (product_id integer NOT NULL PRIMARY KEY, name varchar, genius integer, manufacturer_name varchar, status varchar)')
    or die "Can't create product table";

UR::Object::Type->define(
    class_name => 'Acme::DBProduct',
    id_by => 'product_id',
    has => ['name', 'manufacturer_name', 'genius', 'status',
        status_obj => { is => 'Acme::Status', id_by => 'status', id_class_by => 'status' },
    ],
    table_name => 'product',
    data_source => 'URT::DataSource::SomeSQLite',
);


my @products = (
    [ name => "jet pack",     genius => 6,    manufacturer_name => "Lockheed Martin", status => 'Acme::Status::Design' ],
    [ name => "hang glider",  genius => 4,    manufacturer_name => "Boeing",          status => 'Acme::Status::Production'],
    [ name => "mini copter",  genius => 5,    manufacturer_name => "Boeing",          status => 'Acme::Status::Production'],
    [ name => "catapult",     genius => 5,    manufacturer_name => "Boeing",          status => 'Acme::Status::Design'],
    [ name => "firecracker",  genius => 6,    manufacturer_name => "Explosives R US", status => 'Acme::Status::Production'],
    [ name => "dynamite",     genius => 9,    manufacturer_name => "Explosives R US", status => 'Acme::Status::Production'],
    [ name => "plastique",    genius => 8,    manufacturer_name => "Explosives R US", status => 'Acme::Status::Design'],
);

my $insert = $dbh->prepare('insert into product values (?,?,?,?,?)');
my $id = 1;
foreach ( @products ) {
    Acme::Product->create(@$_);
    $insert->execute($id++, @$_[1,3,5, 7])
}
$insert->finish();
$dbh->commit();

my @tests = (
                # get params                                # num expected objects
    [ [ manufacturer_name => 'Boeing', genius => 5],            2 ],
    [ [ name => ['jet pack', 'dynamite'] ],                     2 ],
    [ [ manufacturer_name => ['Boeing','Lockheed Martin'] ],    4 ],
    [ [ 'genius !=' => 9 ],                                     6 ],
    [ [ 'genius not' => 9 ],                                    6 ],
    [ [ 'genius not =' => 9 ],                                  6 ],
    [ [ 'manufacturer_name !=' => 'Explosives R US' ],          4 ],
    [ [ 'manufacturer_name like' => '%arti%' ],                 1 ],
    [ [ 'manufacturer_name not like' => '%arti%' ],             6 ],
    [ [ 'genius <' => 6 ],                                      3 ],
    [ [ 'genius !<' => 6 ],                                     4 ],
    [ [ 'genius not <' => 6 ],                                  4 ],
    [ [ 'genius <=' => 6 ],                                     5 ],
    [ [ 'genius !<=' => 6 ],                                    2 ],
    [ [ 'genius not <=' => 6 ],                                 2 ],
    [ [ 'genius >' => 6 ],                                      2 ],
    [ [ 'genius !>' => 6 ],                                     5 ],
    [ [ 'genius not >' => 6 ],                                  5 ],
    [ [ 'genius >=' => 6 ],                                     4 ],
    [ [ 'genius !>=' => 6 ],                                    3 ],
    [ [ 'genius not >=' => 6 ],                                 3 ],
    [ [ 'genius between' => [4,6] ],                            5 ],
    [ [ 'genius !between' => [4,6] ],                           2 ],
    [ [ 'genius not between' => [4,6] ],                        2 ],
    [ [ 'genius >' => 5, 'status isa' => 'Acme::Status::Production' ],  2 ],
    [ [ 'status isa' => 'Acme::Status::Design'],                3 ],
    [ [ 'status isa' => 'Acme::Status' ],                       7 ],
    [ [ 'manufacturer_name >' => 'E' ],                         4 ],
    [ [ 'manufacturer_name not >' => 'E' ],                     3 ],
    [ [ 'manufacturer_name <' => 'E' ],                         3 ],
    [ [ 'manufacturer_name not <' => 'E' ],                     4 ],
    [ [ 'manufacturer_name >=' => 'E' ],                        4 ],
    [ [ 'manufacturer_name not >=' => 'E' ],                    3 ],
    [ [ 'manufacturer_name <=' => 'E' ],                        3 ],
    [ [ 'manufacturer_name not <=' => 'E' ],                    4 ],
    [ [ 'manufacturer_name between' => ['C', 'H'] ],            3 ],
    [ [ 'manufacturer_name not between' => ['C', 'H'] ],        4 ],
);

for my $class ( qw( Acme::Product Acme::DBProduct ) ) {
    # Test with get()
    for (my $testnum = 0; $testnum < @tests; $testnum++) {
        my $params = $tests[$testnum]->[0];
        my $expected = $tests[$testnum]->[1];
        my @objs = $class->get(@$params);
        is(scalar(@objs), $expected, "Got $expected objects for $class->get() test $testnum: ".join(' ', @$params));
    }

    # Test old syntax
    for (my $testnum = 0; $testnum < @tests; $testnum++) {
        my $params = $tests[$testnum]->[0];
        my $expected = $tests[$testnum]->[1];

        my %params;
        for(my $i = 0; $i < @$params; $i += 2) {
            my($prop, undef, $op) = $params->[$i] =~ m/^(\w+)(\s+(.*))?/;
            $params{$prop} = { operator => $op, value => $params->[$i+1] };
        }
        my @objs = $class->get(%params);
        is(scalar(@objs), $expected, "Got $expected objects for $class->get() old syntax test $testnum: ".join(' ', @$params));
    }

    # test get with a bx
    for (my $testnum = 0; $testnum < @tests; $testnum++) {
        my $params = $tests[$testnum]->[0];
        my $expected = $tests[$testnum]->[1];
        my $bx = $class->define_boolexpr(@$params);
        my @objs = $class->get($bx);
        is(scalar(@objs), $expected, "Got $expected objects for bx test $testnum: ".join(' ', @$params));

        # test each param in the BX
        my %params = @$params;
        foreach my $key ( keys %params ) {
            ($key) = $key =~ m/(\w+)/;
            ok($bx->specifies_value_for($key), "bx does specify value for $key");
        }

        foreach my $obj ( @objs) {
            ok($bx->evaluate($obj), 'Expected $obj '.$obj->id.' object passes the BoolExpr');
        }
    }
}
