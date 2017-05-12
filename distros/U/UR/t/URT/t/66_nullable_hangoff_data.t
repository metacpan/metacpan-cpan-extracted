#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 6;

&setup_classes_and_db();

my $thing = URT::Thing->create(thing_id => 3, name => 'Fred');

# There's now 1 colorless thing in the DB and one in the object cache
my @colorless = URT::Thing->get(color => undef);
is(scalar(@colorless), 2, 'Got two colorless things');

# Remove the test DB
unlink(URT::DataSource::SomeSQLite->server);


sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle();

    ok($dbh, 'got DB handle');

    ok($dbh->do('create table things (thing_id integer, name varchar)'),
       'Created things table');

    my $insert = $dbh->prepare('insert into things (thing_id, name) values (?,?)');
    foreach my $row ( ( [1, 'Bob'],
                        [2, 'Joe'],
                      )) {
        unless ($insert->execute(@$row)) {
            die "Couldn't insert a row into 'things': $DBI::errstr";
        }
    }

    ok($dbh->do('create table attributes (attr_id integer, thing_id integer, key varchar, value varchar)'),
        'Created attributes table');
    $insert = $dbh->prepare('insert into attributes (attr_id, thing_id, key, value) values (?,?,?,?)');
    foreach my $row ( ( [1, 1, 'color', 'green'],
                        [2, 1, 'address', '1234 Main St'],
                        [3, 2, 'address', '2345 Oak St'],
                      )) {
        unless ($insert->execute(@$row)) {
            die "Couldn't insert a row into 'attributes': $DBI::errstr";
        }
    }

    $dbh->commit();
               
    ok(UR::Object::Type->define(
           class_name => 'URT::Thing',
           id_by => 'thing_id',
           has => [
               name => { is => 'String' },
               attributes => { is => 'URT::Attribute', reverse_as => 'thing', is_many => 1 },
               color => { is => 'String', via => 'attributes', to => 'value', where => [key => 'color'], is_optional => 1 },
           ],
           data_source => 'URT::DataSource::SomeSQLite',
           table_name => 'things'),
       'Created class URT::Thing');

    ok(UR::Object::Type->define(
           class_name => 'URT::Attribute',
           id_by => 'attr_id',
           has => [
               thing => { is => 'URT::Thing', id_by => 'thing_id' },
               key   => { is => 'String' },
               value => { is => 'String' },
           ],
           data_source => 'URT::DataSource::SomeSQLite',
           table_name => 'attributes'),
      'Created class URT::Attribute');
 }
               
