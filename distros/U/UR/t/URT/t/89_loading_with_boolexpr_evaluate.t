#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 12;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace

# Turn this on for debugging
#$ENV{UR_DBI_MONITOR_SQL}=1;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
ok($dbh, "got a db handle");
&create_db_tables($dbh);

my $query_count;
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub {$query_count++}),
    'Created a subscription for query');


$query_count = 0;
# Since this query is against a calculate property, it will do a more
# general query, import more data than is strictly necessary, and throw
# out objects after loading them because they don't pass BoolExpr evaluation
my @things = URT::Person->get(uc_name => 'lowercase');
is(scalar(@things), 0, 'No Persons with uc_name => "lowercase"');
is($query_count, 1, 'Made 1 query');

# This will actually trigger another DB query, though all the objects
# it loads will already exist in the context.  The underlying context
# iterator needs to correctly throw away non-matching objects and
# only return the one we're looking for
$query_count = 0;
@things = URT::Person->get(uc_name => 'FRED');
is(scalar(@things), 1, 'Got 1 thing with uc(name) FRED');
is($things[0]->name, 'Fred', 'Name is correct');
is($query_count, 1, 'Made 1 query');


sub create_db_tables {
    my $dbh = shift;

    ok($dbh->do('create table person
                ( person_id int NOT NULL PRIMARY KEY, name varchar )'),
       'created things table');

    ok(UR::Object::Type->define( 
            class_name => 'URT::Person',
            table_name => 'PERSON',
            id_by => [
                'person_id' =>     { is => 'NUMBER' },
            ],
            has => [
                'name' =>          { is => 'STRING' },
                'uc_name' =>     { calculate_from => 'name', calculate => 'uc($name)' },
            ],
            data_source => 'URT::DataSource::SomeSQLite',
        ),
        "Created class for Person");

    ok($dbh->do(q(insert into person (person_id, name) values (1, 'Bob'))), 'insert a person');
    ok($dbh->do(q(insert into person (person_id, name) values (2, 'Joe'))), 'insert a person');
    ok($dbh->do(q(insert into person (person_id, name) values (3, 'Fred'))), 'insert a person');
}


