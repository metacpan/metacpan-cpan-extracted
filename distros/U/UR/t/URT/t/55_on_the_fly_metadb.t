#!/usr/bin/env perl

use Test::More;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use File::Temp;
use Sub::Install;

use strict;
use warnings;

# This test assummes the storage DB schema already exists, but that the metaDB has
# no record of it.  

plan tests => 20;

# Make a data source
# There is a bug w/ the file temp path generated on Mac OS X and SQLite.
# Fix, and restore this to use File::Temp.
my $db_file = '/tmp/pid' . $$; 
END {
    unlink $db_file;
}
# Hrm... seems that 'server' still isn't a proper property yet
IO::File->new($db_file,'w')->close();
sub URT::DataSource::OnTheFly::server { return $db_file }
my $ds = UR::Object::Type->define(
             class_name => 'URT::DataSource::OnTheFly',
             is => 'UR::DataSource::SQLite',
         );
ok($ds, 'Defined data source');

# Connect to the datasource's DB directly, create a couple of tables and some seed data
my $dbh = URT::DataSource::OnTheFly->get_default_handle;
ok($dbh->do('create table TABLE_A (a_id integer PRIMARY KEY, a_value varchar)'),
   'Created TABLE_A');
ok($dbh->do('create table TABLE_B (b_id integer PRIMARY KEY, a_id int references TABLE_A(a_id))'),
   'Created TABLE_B');
ok($dbh->do("insert into TABLE_A (a_id, a_value) values (10,'hello')"),
   'Inserted row into table_a');
ok($dbh->do("insert into TABLE_B (b_id, a_id) values (2,10)"),
   'Inserted row into table_b');

ok($dbh->commit(), 'Inserts committed to the DB');

# Define a couple of classes to go with those tables
# Note that we're not going to insert anything in the MetaDB about 
# these tables
my $class_a = UR::Object::Type->define(
                  class_name => 'URT::ClassA',
                  id_by => ['a_id'],
                  has => [
                      a_value => { is => 'Text' },
                  ],
                  data_source => $ds->id,
                  table_name => 'TABLE_A'
              );
ok($class_a, 'Defined ClassA');

my $class_b = UR::Object::Type->define(
                  class_name => 'URT::ClassB',
                  id_by => ['b_id'],
                  has => [
                      a_obj => { is => 'URT::ClassA', id_by => 'a_id' },
                  ],
                  data_source => $ds->id,
                  table_name => 'TABLE_B',
              );
ok($class_b, 'Defined ClassB');


# Now interact with the object API to get/create/save data
my @results;

@results = URT::ClassA->get(10);
ok(scalar(@results) == 1, 'We can get an item from ClassA');

@results = URT::ClassB->get(2);
ok(scalar(@results) == 1, 'We can get an item from ClassB');

@results = URT::ClassB->get(1);
ok(scalar(@results) == 0, 'Get ClassB with non-existent ID correctly returns 0 items');

my $new_a = URT::ClassA->create(a_value => 'there');
ok($new_a, 'We are able to create a new ClassA item');

my $new_b = URT::ClassB->create(a_id => $new_a->a_id);
ok($new_b, 'We are able to create a new ClassB item');

ok(UR::Context->commit(), 'Committed to the DB successfully');

# Check that the data made it to the DB

my $sth = $dbh->prepare('select * from table_a order by a_id');
ok($sth, 'select on table_a prepared');
$sth->execute();
my $results = $sth->fetchall_arrayref();
is(scalar(@$results), 2, 'There are 2 rows in table_a');
is_deeply($results,
          [[$new_a->id, 'there'], [10, 'hello']],
          'Data in table_a is correct');

$sth = $dbh->prepare('select * from table_b order by b_id');
ok($sth, 'select on table_b prepared');
$sth->execute();
$results = $sth->fetchall_arrayref();
is(scalar(@$results), 2, 'There are 2 rows in table_b');
is_deeply($results,
          [[$new_b->b_id, $new_a->a_id],[2,10]],
          'Data in table_a is correct');

 
                          
