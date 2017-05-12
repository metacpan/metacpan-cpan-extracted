#!/usr/bin/env perl

use Test::More;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use strict;
use warnings;

# This test assummes the storage DB schema already exists, but that the metaDB has
# incomplete or outdated info about it, though the class and actual DB schema do match

plan tests => 26;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle();
ok($dbh->do('create table TABLE_A (a_id integer PRIMARY KEY, value1 varchar, value2 varchar)'),
   'Create table');
ok($dbh->do("insert into TABLE_A values (1,'hello','there')"),
   'insert row 1');
ok($dbh->do("insert into TABLE_A values (2,'goodbye','cruel world')"),
   'insert row 2');

ok(UR::Object::Type->define(
    class_name => 'URT::A',
    id_by => 'a_id',
    has => ['value1','value2'],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'TABLE_A',
  ),
  'Define class A');

# Fab up metaDB info, but leave out the value2 column
my %table_info = ( data_source => 'URT::DataSource::SomeSQLite', owner => 'main', table_name => 'TABLE_A');
#my %table_info = ( data_source => 'URT', owner => 'main', table_name => 'TABLE_A');
ok(UR::DataSource::RDBMS::Table->__define__(%table_info,
                                         last_object_revision => time(),
                                         er_type => 'entity',
                                         table_type => 'table'),
   'Make table metadata obj');
ok(UR::DataSource::RDBMS::TableColumn->__define__(%table_info,
                                         last_object_revision => time(),
                                               column_name => 'a_id',
                                               data_type => 'integer',
                                               nullable => 'N'),
    'Make column metadata obj for a_id');
ok(UR::DataSource::RDBMS::TableColumn->__define__(%table_info,
                                         last_object_revision => time(),
                                               column_name => 'value1',
                                               data_type => 'varchar',
                                               nullable => 'Y'),
    'Make column metadata obj for value1');
ok(UR::DataSource::RDBMS::PkConstraintColumn->__define__(%table_info,
                                               column_name => 'a_id',
                                               rank => 0),
    'Make Pk constraint metadata obj for a_id');


my $obj = URT::A->get(1);
ok($obj, 'Got object with ID 1');

my %values = ( a_id => 1, value1 => 'hello', value2 => 'there');
foreach my $key ( keys %values ) {
    is($obj->$key, $values{$key}, "$key property is correct");
}

ok($obj->value2('gracie'), 'Change value for value2');


$obj = URT::A->get(2);
ok($obj, 'Got object with ID 2');
%values = ( a_id => 2, value1 => 'goodbye', value2 => 'cruel world');
foreach my $key ( keys %values ) {
    is($obj->$key, $values{$key}, "$key property is correct");
}

ok($obj->delete, 'Delete object ID 2');

$obj = URT::A->create(a_id => 3, value1 => 'it', value2 => 'works');
ok($obj, 'Created a new object');

ok(UR::Context->current->commit, 'Commit');

my $sth = $dbh->prepare('select * from table_a where a_id = ?');
ok($sth, 'Make statement handle for checking data');

$sth->execute(1);
my $objdata = $sth->fetchrow_hashref();
ok($objdata, 'Got data for a_id == 1');
is_deeply($objdata,
          { a_id => 1, value1 => 'hello', value2 => 'gracie'},
          'Saved data is correct');

$sth->execute(2);
$objdata = $sth->fetchrow_hashref();
ok(!$objdata, 'Data for a_id == 2 was deleted');

$sth->execute(3);
$objdata = $sth->fetchrow_hashref();
ok($objdata, 'Got data for a_id == 3');
is_deeply($objdata,
          { a_id => 3, value1 => 'it', value2 => 'works'},
          'Saved data is correct');

