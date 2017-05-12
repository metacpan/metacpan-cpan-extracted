#!/usr/bin/env perl 

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use URT::DataSource::SomeSQLite;
use Test::More tests => 5;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

# The 'father_name' property of Person requires a join back to Person
# Now that we don't index delegated properties, we should be able to
# load the whole result in one query

$dbh->do('create table person (person_id integer primary key not null, name varchar, father_id integer references person(person_id))');
# Bob is Fred's father.  Bob doesn't have a father recorded in the table
$dbh->do("insert into person values (1,'Bob', null)");
$dbh->do("insert into person values (2,'Fred', 1)");
# Mike is Joe's father
$dbh->do("insert into person values (3,'Mike', null)");
$dbh->do("insert into person values (4,'Joe', 3)");
# Bob (no relation to the first Bob) is Frank's father, and Bubba is Bob's father
$dbh->do("insert into person values (5,'Bubba', null)");
$dbh->do("insert into person values (6,'Bob', 5)");
$dbh->do("insert into person values (7,'Frank', 6)");

UR::Object::Type->define(
    class_name  => 'Person',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name  => 'person',
    id_by => 'person_id',
    has => [
        name => { is => 'String' },
        father => { is => 'Person', id_by => 'father_id' },
        father_name => { via => 'father', to => 'name' },
    ],
);
    

my $query_count = 0;
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub { $query_count++ }),
   'Created a subscription for query');
my @p = Person->get(father_name => 'Bob');
is(scalar(@p), 2, 'Got 2 people back');
is($p[0]->name, 'Fred', 'First is the right person');
is($p[1]->name, 'Frank', 'Second is the right person');
is($query_count, 1, 'Made one query');


