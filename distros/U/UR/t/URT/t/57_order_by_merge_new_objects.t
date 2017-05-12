#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 11;

# There are 2 items in the DB and one newly created object in the cache
# that will satisfy the get().  Make sure they're all returned and in
# the order asked for

&setup_classes_and_db();

my $newobj = URT::Thing->create(thing_id => -1, name => 'Alan', data => 'baaa');

# The default order is by thing_id which would return them in the
# order 'Mike', 'Fred.  
my @o = URT::Thing->get('data like' => 'ba%', -order => ['name']);
is(scalar(@o), 3, 'Got 3 objects with data like ba%');

is($o[0], $newobj, 'First object is the newly created object');

is($o[1]->id, 4, 'Second object id is 4');
is($o[1]->name, 'Bobby', 'Second object name is Bobby');
is($o[1]->data, 'baz', 'Second object data is baz');

is($o[2]->id, 1, 'Third object id is 1');
is($o[2]->name, 'Joe', 'Third object name is Joe');
is($o[2]->data, 'bar', 'Third object data is bar');


# Remove the test DB
unlink(URT::DataSource::SomeSQLite->server);


sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle();

    ok($dbh, 'got DB handle');

    ok($dbh->do('create table things (thing_id integer, name varchar, data varchar)'),
       'Created things table');

    my $insert = $dbh->prepare('insert into things (thing_id, name, data) values (?,?,?)');
    foreach my $row ( ( [1, 'Joe', 'bar'],
                        [2, 'Bob', 'foo'],
                        [3, 'Fred', 'quux'],
                        [4, 'Bobby', 'baz'] )) {
        unless ($insert->execute(@$row)) {
            die "Couldn't insert a row into 'things': $DBI::errstr";
        }
    }

    $dbh->commit();

    # Now we need to fast-forward the sequence past 4, since that's the highest ID we inserted manually
    my $sequence = URT::DataSource::SomeSQLite->_get_sequence_name_for_table_and_column('things', 'thing_id');
    die "Couldn't determine sequence for table 'things' column 'thing_id'" unless ($sequence);

    my $id = -1;
    while($id <= 4) {
        $id = URT::DataSource::SomeSQLite->_get_next_value_from_sequence($sequence);
    }

    ok(UR::Object::Type->define(
           class_name => 'URT::Thing',
           id_by => 'thing_id',
           has => ['name', 'data'],
           data_source => 'URT::DataSource::SomeSQLite',
           table_name => 'things'),
       'Created class URT::Thing');

}
               

