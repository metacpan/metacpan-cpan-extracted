#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 7;

# This tests the scenario where we have several objects in the
# DB that fulfills a get() request.  But before performing that
# get(), we change one of the objects so that it will no longer
# match the later get().

&setup_classes_and_db();

my $o = URT::Thing->get(thing_id => 2);
$o->name('Fred');  # This shouldn't match the below query anymore

my @o = URT::Thing->get(name => 'Bob');

is(scalar(@o), 1, 'Get returned 1 object');
is($o[0]->thing_id, 4, 'its ID is correct');
is($o[0]->name, 'Bob', 'its name is correct');
is($o[0]->data, 'baz', 'its data is correct');

# Remove the test DB
unlink(URT::DataSource::SomeSQLite->server);


sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle();

    ok($dbh, 'got DB handle');

    ok($dbh->do('create table things (thing_id integer, name varchar, data varchar)'),
       'Created things table');

    my $insert = $dbh->prepare('insert into things (thing_id, name, data) values (?,?,?)');
    foreach my $row ( ( [2, 'Bob', 'foo'],
                        [4, 'Bob', 'baz'] )) {
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
               

