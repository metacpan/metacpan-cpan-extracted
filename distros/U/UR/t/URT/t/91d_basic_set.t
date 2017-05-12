use strict;
use warnings;
use Test::More tests => 28;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

ok(UR::Object::Type->define(
    class_name => 'URT::ThingNoDataSource',
    id_by => [
        name => { is => 'String' },
    ],
    has => [
        group_name => { is => 'String' },
        total_size => { is => 'Integer' },
    ],
  ),
  'Define class without a data source');

ok(UR::Object::Type->define(
    class_name => 'URT::ThingWithDataSource',
    id_by => [
        name => { is => 'String' },
    ],
    has => [
        group_name => { is => 'String' },
        total_size => { is => 'Integer' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'things',
  ),
  'Define class with a data source');

my $dbh = URT::DataSource::SomeSQLite->get_default_handle();
$dbh->do('create table things (name varchar not null primary key, group_name varchar, total_size integer)');

foreach my $test_class ( 'URT::ThingNoDataSource', 'URT::ThingWithDataSource' ) {
    ok($test_class->create(name => 'a', group_name => '1', total_size => 10), "create $test_class a");
    ok($test_class->create(name => 'b', group_name => '1', total_size => 20), "create $test_class b");
    ok($test_class->create(name => 'c', group_name => '2', total_size => 30), "create $test_class c");
    ok($test_class->create(name => 'd', group_name => '2', total_size => 40), "create $test_class d");

    #my @sets = $test_class->get(-group_by => ['group_name'], -order_by => ['group_name'] );
    my @sets = $test_class->define_set()->group_by('group_name');
    is(scalar(@sets), 2, 'Got two sets back grouped by group_name');

    is($sets[0]->group_name, '1', 'Group name 1 is first');
    is($sets[0]->min('total_size'), 10, '10 is min total_size');
    is($sets[0]->max('total_size'), 20, '20 is max total_size');
    is($sets[0]->sum('total_size'), 30, '30 is sum total_size');

    is($sets[1]->group_name, '2', 'Disk group 2 is second');
    is($sets[1]->min('total_size'), 30, '30 is min total_size');
    is($sets[1]->max('total_size'), 40, '40 is max total_size');
    is($sets[1]->sum('total_size'), 70, '70 is sum total_size');
}
