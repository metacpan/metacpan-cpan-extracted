#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 11;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace

# Turn this on for debugging
#$ENV{UR_DBI_MONITOR_SQL}=1;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
ok($dbh, "got a db handle");
&create_db_tables($dbh);

{
    my $o = URT::Parent->get(parent_id => 1);
    ok($o, 'Got an object');
    isa_ok($o, 'URT::Parent');
    isa_ok($o, 'URT::Child');

    ok($o->delete, 'Object deleted ok');
}

{
    my $o = URT::Parent->get(parent_id => 1);
    ok(! $o, 'get() with the deleted ID returns nothing');
}

{
    my $o = URT::Parent->get(parent_id => 1);
    ok(! $o, 'get() with the deleted ID again returns nothing');
}
    

unlink(URT::DataSource::SomeSQLite->server);  # Remove the file from /tmp/



sub create_db_tables {
    my $dbh = shift;

    ok($dbh->do('create table PARENT_TABLE
                ( parent_id int NOT NULL PRIMARY KEY, name varchar)'),
       'created parent table');

    ok(UR::Object::Type->define( 
            class_name => 'URT::Parent',
            table_name => 'PARENT_TABLE',
            id_by => [
                'parent_id' =>     { is => 'NUMBER' },
            ],
            has => [
                'name' =>          { is => 'STRING' },
            ],
            data_source => 'URT::DataSource::SomeSQLite',
            sub_classification_method_name => 'reclassify_object',
        ),
        "Created class for Parent");

    ok(UR::Object::Type->define(
            class_name => 'URT::Child',
            is => [ 'URT::Parent' ],
        ),
        "Created class for Child"
    );

    ok($dbh->do(q(insert into parent_table (parent_id, name) values (1, 'Bob'))), "insert a parent object");
}

sub URT::Parent::reclassify_object {
    my($class,$obj) = @_;

    return 'URT::Child';
}

