#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 7;

# When a different ordering is requested, make sure a get() that hits
# the DB returns items in the same order as one that returns cached objects.
# It should be sorted first by the requested key, then by ID

my $dbh = URT::DataSource::SomeSQLite->get_default_handle();

ok($dbh, 'got DB handle');

ok($dbh->do('create table things (thing_id integer, name varchar, data varchar)'),
   'Created things table');

my $insert = $dbh->prepare('insert into things (thing_id, name, data) values (?,?,?)');
# Inserting them purposfully in non-ID order so they'll get returned in non-id
# order if the ID column isn't included in the 'order by' clause
foreach my $row ( ( 
                    [4, 'Bobby', 'abc'],
                    [2, 'Bob', 'abc'],
                    [1, 'Bobert', 'zzz'],
                    [6, 'Bobert', 'infinity'],
                    [5, 'Bobs', 'aaa'],
                )) {
    unless ($insert->execute(@$row)) {
        die "Couldn't insert a row into 'things': $DBI::errstr";
    }
}

$dbh->commit();

ok(UR::Object::Type->define(
       class_name => 'URT::Thing',
       id_by => 'thing_id',
       has => [
           name => { is => 'String' },
           uc_name => { is => 'String', calculate_from => ['name'], calculate => q( uc($name) ) },
           data => { is => 'String' },
           uc_data => { is => 'String', calculate_from => ['data'], calculate => q( uc($data) ) },
       ],
       data_source => 'URT::DataSource::SomeSQLite',
       table_name => 'things'),
   'Created class URT::Thing');


my @o = URT::Thing->get('name like' => 'Bob%', -order => ['uc_data']);
is(scalar(@o), 5, 'Got 2 things with name like Bob% ordered by uc_name');

my @got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;

my @expected = ( { id => 5, name => 'Bobs',   data => 'aaa' },
                 { id => 2, name => 'Bob',    data => 'abc' },
                 { id => 4, name => 'Bobby',  data => 'abc' },
                 { id => 6, name => 'Bobert', data => 'infinity' },
                 { id => 1, name => 'Bobert', data => 'zzz' },
               );

is_deeply(\@got, \@expected, 'Returned data is as expected')
    or diag(Data::Dumper::Dumper(@got));

# Now try it again, cached
@o = URT::Thing->get('name like' => 'Bob%', -order => ['uc_data']);
is(scalar(@o), 5, 'Got 2 things with name like Bob% ordered by data');

@got = map { { id => $_->id, name => $_->name, data => $_->data } } @o;
is_deeply(\@got, \@expected, 'Returned cached data is as expected')
    or diag(Data::Dumper::Dumper(\@got,\@expected));

