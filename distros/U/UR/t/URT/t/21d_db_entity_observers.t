#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 115;


# Test that basic signals get fired off correctly for DB entities

my $dbh = URT::DataSource::SomeSQLite->get_default_handle();
ok($dbh->do('CREATE TABLE person (person_id integer, name varchar, rank integer)'), 'create person table');
ok($dbh->do("INSERT into person VALUES (1, 'Bob', 1)"), 'insert into person table');
ok($dbh->do("INSERT into person VALUES (2, 'Fred', 2)"), 'insert into person table');
ok($dbh->do("INSERT into person VALUES (3, 'Joe', 3)"), 'insert into person table');
ok($dbh->do("INSERT into person VALUES (4, 'Mike', 4)"), 'insert into person table');

UR::Object::Type->define(
    class_name => 'URT::Person',
    id_by => 'person_id',
    has => [
        name => { is => 'String' },
        rank => { is => 'Integer' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'person',
);

my @person_observations = ();
my @person_ghost_observations = ();
my @object1_observations = ();
my @object2_observations = ();
my @ghost1_observations = ();

sub clear_observations {
    @person_observations = ();
    @person_ghost_observations = ();
    @object1_observations = ();
    @object2_observations = ();
    @ghost1_observations = ();
}


my $person_obv = URT::Person->add_observer(callback => sub {
                                                    my $obj = shift;
                                                    my $method = shift;
                                                    my @other_args = @_;
                                                    push @person_observations, [$obj, $method, @other_args];
                                              });
ok($person_obv, "made an observer on Person class");

# Observations on person1 won't fire after it's deleted because it's a ghost.  Make a new
# observer for the ghsot class
my $person_ghost_obv = URT::Person::Ghost->add_observer(callback => sub {
                                                    my $obj = shift;
                                                    my $method = shift;
                                                    my @other_args = @_;
                                                    push @person_ghost_observations, [$obj, $method, @other_args];
                                              });
ok($person_ghost_obv, 'Make observer for URT::Person::Ghost class');



clear_observations();
my $person1 = URT::Person->get(1);
ok($person1, 'Got person ID 1');
is(scalar(@person_observations), 1, 'Saw correct number of Person observations');
is_deeply(\@person_observations,
          [ [$person1, 'load'] ],     # subclasses/loaded as Employee
          'Person observations match expected');

@object1_observations = ();
my $person1_obj_observer = $person1->add_observer(callback => sub {
                                                    my $obj = shift;
                                                    my $method = shift;
                                                    my @other_args = @_;
                                                    push @object1_observations, [$obj,$method,@other_args]});
ok($person1_obj_observer, 'made an observer on person id 1');



clear_observations();
my $person2 = URT::Person->get(2);
ok($person2, 'Got person ID 2');
is(scalar(@person_observations), 1, 'Saw correct number of Person observations');
is(scalar(@person_ghost_observations), 0, 'No Person ghost observations');
is(scalar(@object1_observations), 0, 'person object 1 observer saw no observations');
my $person2_obj_observer = $person2->add_observer(callback => sub {
                                                    my $obj = shift;
                                                    my $method = shift;
                                                    my @other_args = @_;
                                                    push @object2_observations, [$obj,$method,@other_args]});
ok($person2_obj_observer, 'made an observer on person id 2');





# Call the rank mutator, but feed it the original value
clear_observations();
my $trans = UR::Context::Transaction->begin();
ok($trans, 'Begin software transaction');
is(scalar(@person_observations), 0, 'No Person observations from transaction creation');
is(scalar(@person_ghost_observations), 0, 'No Person ghost observations from transaction creation');
is(scalar(@object1_observations), 0, 'No object 1 observations from transaction creation');
is(scalar(@object2_observations), 0, 'No object 2 observations from transaction creation');


clear_observations();
ok($person1->rank(1), 'User rank mutator to set the same value');
is(scalar(@person_observations), 0, 'No Person observations from setting the same value');
is(scalar(@person_ghost_observations), 0, 'No Person ghost observations');
is(scalar(@object1_observations), 0, 'No object 1 observations from setting the same value');
is(scalar(@object2_observations), 0, 'No object 2 observations from setting the same value');


clear_observations();
ok($trans->rollback(), 'Rollback software transaction');
is(scalar(@person_observations), 0, 'No Person observations from transaction rollback');
is(scalar(@person_ghost_observations), 0, 'No Person ghost observations');
is(scalar(@object1_observations), 0, 'No object 1 observations from transaction rollback');
is(scalar(@object2_observations), 0, 'No object 2 observations from transaction rollback');


# Now set the rank to a new value
clear_observations();
$trans = UR::Context::Transaction->begin();
ok($trans, 'Begin software transaction');
is(scalar(@person_observations), 0, 'No Person observations from transaction creation');
is(scalar(@person_ghost_observations), 0, 'No Person ghost observations');
is(scalar(@object1_observations), 0, 'No object 1 observations from transaction creation');
is(scalar(@object2_observations), 0, 'No object 2 observations from transaction creation');


clear_observations();
ok($person1->rank(2), 'Use rank mutator to change value');
is(scalar(@person_observations), 1, 'One observation on Person class');
is_deeply(\@person_observations,
          [ [$person1, 'rank', 1, 2] ],
          'Person observations match expected');

is(scalar(@person_ghost_observations), 0, 'No Person ghost observations');
is(scalar(@object1_observations), 1, 'One observation on person object');
is_deeply(\@object1_observations,
          [ [$person1, 'rank', 1, 2] ],
          'person object observations match expected');
is(scalar(@object2_observations), 0, 'No object 2 observations from transaction creation');



clear_observations();
ok($trans = UR::Context::Transaction->rollback(), 'rollback');
is(scalar(@person_observations), 1, 'One observation on Person class');
is_deeply(\@person_observations,
          [ [$person1, 'rank', 2, 1] ],
          'Person observations match expected');
is(scalar(@person_ghost_observations), 0, 'No Person ghost observations');

is(scalar(@object1_observations), 1, 'One observation on person object');
is_deeply(\@object1_observations,
          [ [$person1, 'rank', 2, 1] ],
          'person object observations match expected');
is(scalar(@object2_observations), 0, 'No object 2 observations from transaction creation');




# Set the rank to a new value and commit the software transaction
clear_observations();
$trans = UR::Context::Transaction->begin();
ok($trans, 'Begin software transaction');
is(scalar(@person_observations), 0, 'No Person observations from transaction creation');
is(scalar(@person_ghost_observations), 0, 'No Person ghost observations');
is(scalar(@object1_observations), 0, 'No object observations from transaction creation');
is(scalar(@object2_observations), 0, 'No object 2 observations from transaction creation');


clear_observations();
ok($person1->rank(2), 'Use rank mutator to change value');
is(scalar(@person_observations), 1, 'One observation on Person class');
is_deeply(\@person_observations,
          [ [$person1, 'rank', 1, 2] ],
          'Person observations match expected');
is(scalar(@person_ghost_observations), 0, 'No Person ghost observations');

is(scalar(@object1_observations), 1, 'One observation on person object');
is_deeply(\@object1_observations,
          [ [$person1, 'rank', 1, 2] ],
          'person object observations match expected');
is(scalar(@object2_observations), 0, 'No object 2 observations from transaction creation');



clear_observations();
ok($trans = UR::Context::Transaction->commit(), 'Commit software transaction');
is(scalar(@person_observations), 0, 'No Person observations from transaction commit');
is(scalar(@person_ghost_observations), 0, 'No Person ghost observations');
is(scalar(@object1_observations), 0, 'No object observations from transaction commit');
is(scalar(@object2_observations), 0, 'No object 2 observations from transaction creation');



# Now commit to the underlying context, with no-commit on
ok(UR::DBI->no_commit(1), 'Turn on no-commit flag');
clear_observations();
ok(UR::Context->commit, 'Commit to the DB');
is(scalar(@person_observations), 0, 'No Person observations from Context commit with no_commit on');
is(scalar(@person_ghost_observations), 0, 'No Person ghost observations');
is(scalar(@object1_observations), 0, 'No object observations from Context commit with no_commit on');
is(scalar(@object2_observations), 0, 'No object 2 observations from transaction creation');



# Make another change, turn no-commit off, and try committing again
clear_observations();
ok($person1->rank(3), 'Use rank mutator to change value');
is(scalar(@person_observations), 1, 'One observation on Person class');
is_deeply(\@person_observations,
          [ [$person1, 'rank', 2, 3] ],
          'Person observations match expected');
is(scalar(@person_ghost_observations), 0, 'No Person ghost observations');

is(scalar(@object1_observations), 1, 'One observation on person object');
is_deeply(\@object1_observations,
          [ [$person1, 'rank', 2, 3] ],
          'person object observations match expected');
is(scalar(@object2_observations), 0, 'No object 2 observations from transaction creation');



ok(! UR::DBI->no_commit(0), 'Turn off no-commit flag');
clear_observations();
ok(UR::Context->commit, 'Commit to the DB');
is(scalar(@person_observations), 1, 'One observation on Person class');
is_deeply(\@person_observations,
          [ [$person1, 'commit'] ],
          'Person observations match expected');
is(scalar(@person_ghost_observations), 0, 'No Person ghost observations');

is(scalar(@object1_observations), 1, 'One observation on person object');
is_deeply(\@object1_observations,
          [ [$person1, 'commit'] ],
          'person object observations match expected');
is(scalar(@object2_observations), 0, 'No object 2 observations from transaction commit');



# Delete person object 1, change person 2 and commit
clear_observations();
ok($person1->delete, 'Delete person object 1');
my $person1_ghost = URT::Person::Ghost->get(1);
is(scalar(@person_observations), 1, 'One observation on Person class');
is_deeply(\@person_observations,
          [ [$person1, 'delete'] ],
          'Person observations match expected');
is(scalar(@person_ghost_observations), 1, 'One Person ghost observations');
is_deeply(\@person_ghost_observations,
          [ [$person1_ghost, 'create'] ],
          'Person ghost  observations match expected');

is(scalar(@object1_observations), 1, 'One observation on person object');
is_deeply(\@object1_observations,
          [ [$person1, 'delete'] ],
          'person object observations match expected');
is(scalar(@object2_observations), 0, 'No object 2 observations from delete');

my $object1_ghost_obv = $person1_ghost->add_observer(callback => sub {
                                                    my $obj = shift;
                                                    my $method = shift;
                                                    my @other_args = @_;
                                                    push @ghost1_observations, [$obj, $method, @other_args];
                                              });
ok($object1_ghost_obv, 'Create observer for now-deleted Person object 1');

clear_observations();
ok($person2->rank(5), 'Change rank of person 2');
is(scalar(@person_observations), 1, 'One observation on Person class');
is_deeply(\@person_observations,
          [ [$person2, 'rank', 2, 5] ],
          'Person observations match expected');
is(scalar(@person_ghost_observations), 0, 'No Person ghost observations');
is(scalar(@object1_observations), 0, 'No object 1 observations');
is(scalar(@ghost1_observations), 0, 'No ghost 1 observations');
is(scalar(@object2_observations), 1, 'One observation on person object 2');
is_deeply(\@object2_observations,
          [ [$person2, 'rank', 2, 5] ],
          'person 2 object observations match expected');


clear_observations();
ok(UR::Context->commit, 'Commit to DB');
is(scalar(@person_observations), 1, 'One observation on Person class');
is_deeply(\@person_observations,
          [ [$person2, 'commit'] ], 
          'Person observations match expected');
is(scalar(@person_ghost_observations), 1, 'One observation on Person Ghost class');
is_deeply(\@person_ghost_observations,
          [ [$person1_ghost, 'commit'] ],
          'Person Ghost observations match expected');

is(scalar(@object1_observations), 0, 'No observations on person 1 object');
is(scalar(@ghost1_observations), 1, 'One observation on person 1 ghost object');
is_deeply(\@ghost1_observations,
          [ [$person1_ghost, 'commit'] ],
          'person ighost object observations match expected');
is(scalar(@object2_observations), 1, 'One observation on person 2 object');
is_deeply(\@object2_observations,
          [ [$person2, 'commit'] ],
          'person 2 object observations match expected');












1;



