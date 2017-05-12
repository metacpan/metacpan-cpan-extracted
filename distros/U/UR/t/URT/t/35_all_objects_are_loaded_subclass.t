#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 21;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace

# Turn this on for debugging
#$ENV{UR_DBI_MONITOR_SQL}=1;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
ok($dbh, "got a db handle");
&create_db_tables($dbh);

our $load_count = 0;
ok(URT::Parent->create_subscription(
                    method => 'load',
                    callback => sub {$load_count++}),
     'Created a subscription for load');

our $query_count = 0;
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub {$query_count++}),
    'Created a subscription for query');


$load_count = 0;
$query_count = 0;
my @o = URT::Parent->get();
is(scalar(@o),   2, 'URT::Parent->get returned 2 parent objects');
is($load_count,  2, 'loaded 2 Parent objects');
is($query_count, 2, 'get() triggered 2 queries');  # 1 on the parent table, 1 more for child joined to parent

$load_count = 0;
$query_count = 0;
@o = URT::Child->get();
is(scalar(@o),   1, 'URT::Child->get returned 1 child object');
is($load_count,  0, 'correctly loaded 0 objects - gotten from the cache');
is($query_count, 0, 'get() correctly triggered 0 queries');

$load_count = 0;
$query_count = 0;
@o = URT::OtherChild->get();
is(scalar(@o),   0, 'URT::OtherChild->get returned 0 other child objects');
is($load_count,  0, 'loaded 0 times - all from the cache');
# Note that the original parent get() would have triggered a query joining other_child table
# to parent if there were any other_child objects
is($query_count, 0, 'get() correctly triggered 0 query'); 

unlink(URT::DataSource::SomeSQLite->server);  # Remove the file from /tmp/



sub create_db_tables {
    my $dbh = shift;

    ok($dbh->do('create table PARENT_TABLE
                ( parent_id int NOT NULL PRIMARY KEY, name varchar, the_type_name varchar)'),
       'created parent table');
    ok($dbh->do('create table CHILD_TABLE
                 ( child_id int NOT NULL PRIMARY KEY CONSTRAINT child_parent_fk REFERENCES parent_table(parent_id),
                   child_value varchar )'),
        'created child table');
    ok($dbh->do('create table OTHER_CHILD_TABLE
                 ( child_id int NOT NULL PRIMARY KEY CONSTRAINT child_parent_fk REFERENCES parent_table(parent_id),
                   other_child_value varchar )'),
       'created other child table');

    #@URT::Parent::ISA = ('UR::ModuleBase');
    #@URT::Child::ISA = ('UR::ModuleBase');
    #@URT::OtherChild::ISA = ('UR::ModuleBase');
    #ok(UR::Object::Type->define(
    #        class_name => 'URT',
    #        is => 'UR::Namespace',
    #    ),
    #    "Created namespace for URT");

    ok(UR::Object::Type->define( 
            class_name => 'URT::Parent',
            table_name => 'PARENT_TABLE',
            id_by => [
                'parent_id' =>     { is => 'NUMBER' },
            ],
            has => [
                'name' =>          { is => 'STRING' },
                'the_type_name' => { is => 'STRING'},
            ],
            data_source => 'URT::DataSource::SomeSQLite',
            sub_classification_method_name => 'reclassify_object',
        ),
        "Created class for Parent");

    ok(UR::Object::Type->define(
            class_name => 'URT::Child',
            table_name => 'CHILD_TABLE',
            is => [ 'URT::Parent' ],
            id_by => [ 
                child_id => { is => 'NUMBER' },
            ],
            has => [
                child_value => { is => 'STRING' },
            ],
        ),
        "Created class for Child"
    );

    ok(UR::Object::Type->define(
            class_name => 'URT::OtherChild',
            table_name => 'OTHER_CHILD_TABLE',
            is => [ 'URT::Parent' ],
            id_by => [
                child_id => { is => 'NUMBER' },
            ],
            has => [
                other_child_value => { is => 'STRING' },
            ],
        ),
        "Created class for Other Child"
    );


    ok($dbh->do(q(insert into parent_table (parent_id, name, the_type_name) values (1, 'Bob', 'URT::Parent'))), "insert a parent object");

    ok($dbh->do(q(insert into parent_table (parent_id, name, the_type_name) values ( 2, 'Fred', 'URT::Child'))), "Insert part 1 of a child object");
    ok($dbh->do(q(insert into child_table  (child_id, child_value) values ( 2, 'stuff'))), "Insert part 2 of a child object");
}

sub URT::Parent::reclassify_object {
    my($class,$obj) = @_;

    return $obj->the_type_name;
}

