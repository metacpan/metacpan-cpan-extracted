#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 5;

# This tests the scenario where the Context's loading iterator must
# merge objects fulfilling a get() request between objects in
# the cache and objects loaded from a DB

&setup_classes_and_db();

URT::Thing->create(thing_id => 1, name => 'Bob', data => '1234');
URT::Thing->create(thing_id => 3, name => 'Bob', data => '5678');
my @o = URT::Thing->get(name => 'Bob');

# 2 objects in the DB plus 2 more that we created
is(scalar(@o), 4, 'Get returned 4 objects');

my @expected = (
    { thing_id => 1, name => 'Bob', data => '1234' },
    { thing_id => 2, name => 'Bob', data => 'foo'  },
    { thing_id => 3, name => 'Bob', data => '5678' },
    { thing_id => 4, name => 'Bob', data => 'baz' },
  );

my @got = map { { thing_id => $_->thing_id, name => $_->name, data => $_->data } }
          @o;
is_deeply(\@got, \@expected, 'Data returned is as expected');



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
               

