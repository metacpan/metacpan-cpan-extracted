#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 60;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace
use URT::DataSource::SomeSQLite;

# Turn this on for debugging
#$ENV{UR_DBI_MONITOR_SQL}=1;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
ok($dbh, "got a db handle");

# SQLite's rollback un-does the table creation, too, so we
# have to re-create the table and object when no-commit is on
# And this needs to be re-created each time the main Context rolls back
# because subscription creation is a transactional action
my $init_db = sub {
    $dbh->do('create table IF NOT EXISTS person ( person_id int NOT NULL PRIMARY KEY, name varchar)');
    $dbh->do(q(delete from person));
    $dbh->do(q(insert into person (person_id, name) values (1, 'Bob')));
};
$init_db->();

ok(UR::Object::Type->define( 
        class_name => 'URT::Person',
        table_name => 'person',
        id_by => [
            'person_id' =>     { is => 'NUMBER' },
        ],
        has => [
            'name' =>          { is => 'STRING' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
    ),
    "Created class for Person");

my $o = URT::Person->get(person_id => 1);
ok($o, 'Got an object');
{
    my $within = sub {
        ok($o->delete, 'Object deleted ok');
        isa_ok($o, 'UR::DeletedRef');

        ok(! URT::Person->get(person_id => 1), 'get() does not return the deleted object');
    };
    my $after = sub {
        isa_ok($o, 'URT::Person');
    
        my $o2 = URT::Person->get(person_id => 1);
        ok($o2, 'get() returns the object again');
        is($o2, $o, 'the returned object is the same reference as the original');
    };

    &try_in_sw_transaction($within, $after);
    &try_in_context_transaction($within,$after);
}


{
    my $within = sub {
        ok($o->delete, 'Delete the object');
        isa_ok($o, 'UR::DeletedRef');

        my $new_o = URT::Person->create(person_id => 1, name => 'Fred');
        ok($new_o, 'Created a new Person with the same ID as the deleted one');

        is($new_o, $o, 'They are the same reference');   # The IDs are the same, so they're the same thing
        isa_ok($new_o, 'URT::Person');
        is($new_o->name, 'Fred', 'Name is the new object name');
    };

    my $after = sub {
        isa_ok($o, 'URT::Person');

        my $o2 = URT::Person->get(person_id => 1);
        ok($o2, 'get() returns the object again');
        is($o2, $o, 'the returned object is the same reference as the original');
        is($o->name, 'Bob', 'Name is the original object name');
    };
    &try_in_sw_transaction($within, $after);
    &try_in_context_transaction($within,$after);
}


{
    # Doing this with the outer Context's transaction makes no sense
    # Just test in a software transaction

    my $trans1 = UR::Context::Transaction->begin();
    ok($trans1, 'Started a software transaction');

    ok($o->name('Fred'), 'Change object name to Fred');

    my $trans2 = UR::Context::Transaction->begin();
    ok($trans2,'Start an inner transaction');

    ok($o->delete,'Delete the object');
    isa_ok($o, 'UR::DeletedRef');
    ok(! URT::Person->get(person_id => 1), 'get() does not return the deleted object');

    ok($trans2->rollback, 'Rollback inner transaction');
    isa_ok($o, 'URT::Person');

    is($o->name, 'Fred', 'Object name is still Fred');

    ok($trans1->rollback, 'Rollback outter transaction');
    is($o->name, 'Bob', 'Object name is back to Bob');
}


{
    # And this one makes no sense with a software transaction since
    # it needs to hit the DB
    ok(UR::DBI->no_commit(1), 'Turn on no-commit');

    my $new_o = URT::Person->create(person_id => 2, name => 'Fred');
    ok($new_o, 'Create a new Person');

    ok(UR::Context->commit(),'Context commit');

    ok($new_o->delete(),'Delete the new object');
    isa_ok($new_o, 'UR::DeletedRef');

    ok(UR::Context->rollback(),'Context rollback');
    isa_ok($new_o, 'URT::Person');
    is($new_o->name, 'Fred', 'The object name is Fred');
}

    

#################################################################3

sub try_in_sw_transaction {
    my $within = shift;
    my $after = shift;

    my $trans = UR::Context::Transaction->begin();
    ok($trans, 'Started a software transaction');

    $within->();

    ok($trans->rollback(), 'rollback the software transaction');

    $after->();
}

sub try_in_context_transaction {
    my $within = shift;
    my $after = shift;

    $within->();

    ok(UR::Context->rollback(), 'rollback the context');
    $init_db->();

    $after->();
}

    
