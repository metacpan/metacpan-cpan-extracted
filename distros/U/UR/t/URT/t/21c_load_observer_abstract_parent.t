#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 22;


# Make an abstract class with a table, and a child class with no table of its own.
# The 'load' signal should only ever be fired once for each object loaded

my $dbh = URT::DataSource::SomeSQLite->get_default_handle();
ok($dbh->do('CREATE TABLE person (person_id integer, name varchar, subclass_name varchar)'), 'create table');
ok($dbh->do("INSERT into person VALUES (1, 'Bob', 'URT::Employee')"), 'insert into person table');
ok($dbh->do("INSERT into person VALUES (2, 'Fred', 'URT::Employee')"), 'insert into person table');
ok($dbh->do("INSERT into person VALUES (3, 'Joe', 'URT::Employee')"), 'insert into person table');
ok($dbh->do("INSERT into person VALUES (4, 'Mike', 'URT::Employee')"), 'insert into person table');

UR::Object::Type->define(
    class_name => 'URT::Person',
    is_abstract => 1,
    subclassify_by => 'subclass_name',
    id_by => 'person_id',
    has => [
        name => { is => 'String' },
        subclass_name => { is => 'String' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'person',
);

UR::Object::Type->define(
    class_name => 'URT::Employee',
    is => 'URT::Person',
);

my @person_observations;
my $person_obv = URT::Person->add_observer(callback => sub {
                                                             my($obj,$method) = @_;
                                                             push @person_observations, [$method, $obj->class, $obj->id];
                                                             #print "*** Got $method signal for obj ".$obj->id." named ".$obj->name." in class ".$obj->class."\n";
                                                             #print Carp::longmess();
                                                           });
ok($person_obv, "made an observer on Person class");

my @employee_observations;
my $employee_obv = URT::Employee->add_observer(callback => sub {
                                                             my($obj,$method) = @_;
                                                             push @employee_observations, [$method, $obj->class, $obj->id];
                                                           });
ok($employee_obv, "made an observer on Employee class");

@person_observations = ();
@employee_observations = ();
my $person = URT::Person->get(1);
ok($person, 'Got person ID 1');
is(scalar(@person_observations), 1, 'Saw correct number of Person observations');
is_deeply(\@person_observations,
          [ ['load',   'URT::Employee', 1] ],     # subclasses/loaded as Employee
          'Person observations match expected');

is(scalar(@employee_observations), 1, 'Saw correct number of Employee observations');
is_deeply(\@employee_observations,
          [ ['load', 'URT::Employee', 1] ],
          'Employee observations match expected');


@person_observations = ();
@employee_observations = ();
$person = URT::Employee->get(2);
ok($person, 'Got Employee ID 2');
is(scalar(@person_observations), 1, 'Saw correct number of Person observations');
is_deeply(\@person_observations,
          [ ['load',   'URT::Employee', 2] ],
          'Person observations match expected');

is(scalar(@employee_observations), 1, 'Saw correct number of Employee observations');
is_deeply(\@employee_observations,
          [ [ 'load', 'URT::Employee', 2] ],
          'Employee observations match expected');
 

@person_observations = ();
@employee_observations = ();
my @people = URT::Person->get();
is(scalar(@people), 4, 'Got 4 Person objects');
is(scalar(@person_observations), 2, 'Saw correct number of Person observations');
is_deeply(\@person_observations,
          [ ['load',   'URT::Employee', 3],
            ['load',   'URT::Employee', 4] ],
          'Person observations match expected');

is(scalar(@employee_observations), 2, 'Saw correct number of Employee observations');
is_deeply(\@employee_observations,
          [ ['load', 'URT::Employee', 3],
            ['load', 'URT::Employee', 4] ],
          'Employee observations match expected');

