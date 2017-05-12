use warnings;
use strict;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 8;

# Tests a get() with a delegated property, where the delegation is resolved via a 
# calculated property

ok(setup(), 'Create initial schema, data and classes');

my $emp = URT::Employee->get(1);
ok($emp, 'Got employee 1');

my $boss = $emp->boss;
ok($boss, 'Got boss for employee 1');

my @emp = URT::Employee->get(company => 'CoolCo');
is(scalar(@emp), 2, 'Got 2 employees of CoolCo');


# define the data source, create a table and classes for it
sub setup {

    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
    ok($dbh, 'Got DB handle');
    ok($dbh->do('create table BOSS (boss_id int, first_name varchar, last_name varchar, company varchar)'),
       'create table BOSS');
    ok($dbh->do('create table EMPLOYEE (emp_id int, name varchar, is_secret, int, boss_id int CONSTRAINT boss_fk references BOSS(BOSS_ID))'),
       'create table EMPLOYEE');

    my $sth = $dbh->prepare('insert into BOSS (boss_id, first_name, last_name, company) values (?,?,?,?)');
    $sth->execute(1, 'Bob', 'Smith', 'CoolCo');
    $sth->execute(2, 'Robert', 'Jones', 'Data Inc');
    $sth->finish();

    $sth = $dbh->prepare('insert into EMPLOYEE (emp_id, name, boss_id, is_secret) values (?,?,?,?)');
    $sth->execute(1,'Joe', 1, 0);
    $sth->execute(2,'James', 1, 0);
    $sth->execute(3,'Jack', 2, 1);
    $sth->execute(4,'Jim', 2, 0);
    $sth->execute(5,'Jacob', 2, 1);
    $sth->finish();
    
    ok($dbh->commit(), 'Commit records to DB');

    # Bosses are pretty normal
    UR::Object::Type->define(
        class_name => "URT::Boss",
        id_by => 'boss_id',
        has => [
            boss_id             =>  { type => "Number" },
            first_name          =>  { type => "String" },
            last_name           =>  { type => "String" },
            company             =>  { type => "String" },
            employees           =>  { is => 'URT::Employee', is_many => 1, reverse_as => 'boss' },
            secret_employees    =>  { is => 'URT::Employee', is_many => 1, reverse_as => 'boss', where => [is_secret => 1] },

        ],
        table_name => 'BOSS',
        data_source => 'URT::DataSource::SomeSQLite',
    );

    # An employee's boss is connected through the calculated property calc_boss_id
    UR::Object::Type->define(
        class_name => 'URT::Employee',
        id_by => 'emp_id',
        has => [
            emp_id => { type => "Number" },
            name => { type => "String" },
            is_secret => { is => 'Boolean' },
            boss_id => { type => 'Number'},
            calc_boss_id => { calculate => q( return $self->boss_id ) }, # silly, but it's still a calculation
            boss => { type => "URT::Boss", id_by => 'calc_boss_id' },
            company   => { via => 'boss' },
        ],
        table_name => 'EMPLOYEE',
        data_source => 'URT::DataSource::SomeSQLite',
    );

    return 1;
}

