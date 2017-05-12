#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 30;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace


my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
ok($dbh, "got a handle");
isa_ok($dbh, 'UR::DBI::db', 'Returned handle is the proper class');

# Make 3 tables, one with lower case names, one with upper, one with mixed case
# do some CRUD and then commit().  Make sure the real data got saved and the
# metadata is created correctly

ok($dbh->do('create table person (person_id integer NOT NULL PRIMARY KEY, name varchar)'),
   'create person table');
ok($dbh->do('create table EMPLOYEE (EMPLOYEE_ID integer NOT NULL PRIMARY KEY references person(person_id), OFFICE varchar)'),
   'create EMPLOYEE table');
ok($dbh->do('create table InvenTory (InvenToryId integer NOT NULL PRIMARY KEY, Owner integer references EMPLOYEE(EMPLOYEE_ID), Name varchar)'),
   'create InvenTory table');

# insert some data
ok($dbh->do("insert into person values (100, 'UpdateName')"), 'insert person');
ok($dbh->do("insert into person values (101, 'DoNotChange')"), 'insert person');
ok($dbh->do("insert into person values (102, 'DeleteName')"), 'insert person');
ok($dbh->do("insert into person values (103, 'GetByJoin')"), 'insert person');

ok($dbh->do("insert into EMPLOYEE values (100, 'office 100')"), 'insert EMPLOYEE');
ok($dbh->do("insert into EMPLOYEE values (101, 'office 101')"), 'insert EMPLOYEE');
ok($dbh->do("insert into EMPLOYEE values (102, 'office 102')"), 'insert EMPLOYEE');
ok($dbh->do("insert into EMPLOYEE values (103, 'GetByJoin')"), 'insert person');

# person ID 100 has a black car and a red stapler
# person ID 101 has a green chair and green phone
# person ID 102 has nothing to begin with
# person ID 103 has an item called 'Join'
ok($dbh->do("insert into InvenTory values (100, 100, 'black car')"), 'insert InvenTory');
ok($dbh->do("insert into InvenTory values (101, 100, 'red stapler')"), 'insert InvenTory');
ok($dbh->do("insert into InvenTory values (102, 101, 'greep chair')"), 'insert InvenTory');
ok($dbh->do("insert into InvenTory values (103, 101, 'green phone')"), 'insert InvenTory');
ok($dbh->do("insert into InvenTory values (104, 103, 'Join')"), 'insert InvenTory');


# And now class definitions for those 3 tables
UR::Object::Type->define(
    class_name => 'URT::Person',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'person',
    is_abstract => 1,
    id_by => 'person_id',
    has => ['name'],
);

UR::Object::Type->define(
    class_name => 'URT::Inventory',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'InvenTory',
    id_by => 'InvenToryId',
    has => [
        owner_id => { is => 'Integer', column_name => 'Owner' },
        owner    => { is => 'URT::Employee', id_by => 'owner_id' },
        name     => { is => 'String', column_name => 'Name' },
    ],
);
    
UR::Object::Type->define(
    class_name => 'URT::Employee',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'EMPLOYEE',
    is => 'URT::Person',
    id_by => 'EMPLOYEE_ID',
    has => [
        office    => { is => 'String', column_name => 'OFFICE' },
        inventory => { is => 'URT::Inventory', reverse_as => 'owner', is_many => 1 },
    ],
);

my @sql = ();
URT::DataSource::SomeSQLite->add_observer(
    aspect => 'query',
    callback => sub {
        my($data_source, $method, $sql) = @_;
        if ($method eq 'query') {
            $sql =~ s/^\s+|\s+$//g;  # remove leading and trailing whitespace
            $sql =~ s/\s+/ /g; # change whitespace to a single space
            push(@sql, $sql);
        }
    }
);

@sql = ();
my $person = URT::Employee->get(name => 'NotThere');
ok(!$person, 'Get employee by name failed for non-existent name');
is(scalar(@sql), 1, 'Made 1 query');
is($sql[0],
   'select EMPLOYEE.EMPLOYEE_ID, EMPLOYEE.OFFICE, person.name, person.person_id from EMPLOYEE INNER join person on EMPLOYEE.EMPLOYEE_ID = person.person_id where person.name = ? order by EMPLOYEE.EMPLOYEE_ID',
   'SQL is correct');

@sql = ();
$person = URT::Employee->get(name => 'UpdateName');
ok($person, 'Get employee by name worked');
is(scalar(@sql), 1, 'Made 1 query');
is($sql[0],
   'select EMPLOYEE.EMPLOYEE_ID, EMPLOYEE.OFFICE, person.name, person.person_id from EMPLOYEE INNER join person on EMPLOYEE.EMPLOYEE_ID = person.person_id where person.name = ? order by EMPLOYEE.EMPLOYEE_ID',
   'SQL is correct');

@sql = ();
ok($person->name('Changed'), 'Change name for person');
is(scalar(@sql), 0, 'Made no queries');


@sql = ();
my @inventory = $person->inventory();
is(scalar(@inventory), 2, 'That person has 2 inventory items');
is(scalar(@sql), 1, 'Made 1 query');
is($sql[0], 
   'select InvenTory.InvenToryId, InvenTory.Name, InvenTory.Owner from InvenTory where InvenTory.Owner = ? order by InvenTory.InvenToryId',
   'SQL is correct');


@sql = ();
$person = URT::Employee->get(name => 'DeleteName');
ok($person, 'Got Employee by name');

