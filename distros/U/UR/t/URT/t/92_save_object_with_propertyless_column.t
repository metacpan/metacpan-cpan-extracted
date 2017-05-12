use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 17;
use URT::DataSource::SomeSQLite;

# Make a class attached to a table where some columns in the table have
# no associated property.  Test that we can CRUD

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
ok($dbh->do("create table foo (foo_id integer NOT NULL PRIMARY KEY, name varchar, missing varchar)"), 'create table');
ok($dbh->do("insert into foo values (100,'DeleteMe', 'blah')"), 'insert row');
ok($dbh->do("insert into foo values (101,'UpdateMe', 'blah')"), 'insert row');

UR::Object::Type->define(
    class_name => 'URT::Foo',
    id_by => 'foo_id',
    has => [
        name => { is => 'String' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'foo',
);

my $obj = URT::Foo->get(name => 'DeleteMe');
ok($obj, 'Got an object');
ok($obj->delete(), 'Called delete()');

$obj = URT::Foo->get(name => 'UpdateMe');
ok($obj, 'Got a second object');
ok($obj->name('Updated'), 'Changed its name');

$obj = URT::Foo->create(name => 'Created');
ok($obj, 'Created an object');
my $new_object_id = $obj->id;

my $commit = eval { UR::Context->commit() };
ok($commit, 'commit');
ok(! $@, 'No exceptions during commit');
diag($@) if $@;

my @row = $dbh->selectrow_array('select foo_id,name,missing from foo where foo_id = 100');
ok(!scalar(@row), 'Deleted object was deleted from database');

@row = $dbh->selectrow_array('select foo_id,name,missing from foo where foo_id = 101');
ok(scalar(@row), 'Found row in database for updated object');
is($row[1], 'Updated', 'name column was updated correctly');
is($row[2], 'blah', 'missing column was not touched');

@row = $dbh->selectrow_array("select foo_id,name,missing from foo where foo_id = $new_object_id");
ok(scalar(@row), 'Found row in database for created object');
is($row[1], 'Created', 'name column is correct');
is($row[2], undef, 'missing column is correctly NULL/undef');


