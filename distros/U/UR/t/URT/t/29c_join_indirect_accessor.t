use warnings;
use strict;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 10;

# Tests a get() with an indirect property, where the delegation is resolved via
# another delegated property

ok(setup(), 'Create initial schema, data and classes');

my $emp = URT::Employee->get(1);
ok($emp, 'Got employee 1');

my $boss = $emp->boss;
is($boss->first_name, 'Bob', 'Got boss for employee 1');

my $company = $emp->company();
is($company->name, 'CoolCo', 'Got company for employee 1');

# For now, this is pretty inefficient.  An Employee's company_id is delegated through boss,
# which results in a tree structure for its join requirements.
my @emp = URT::Employee->get(company_name => 'CoolCo');
is(scalar(@emp), 2, 'Got 2 employees of CoolCo');


# define the data source, create a table and classes for it
sub setup {

    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
    ok($dbh, 'Got DB handle');
    ok($dbh->do('create table COMPANY (company_id, name varchar)'),
       'create table COMPANY');
    ok($dbh->do('create table BOSS (boss_id int, first_name varchar, last_name varchar, company_id int REFERENCES company(company_id))'),
       'create table BOSS');
    ok($dbh->do('create table EMPLOYEE (emp_id int, name varchar, is_secret, int, boss_id int references BOSS(BOSS_ID))'),
       'create table EMPLOYEE');

    my $sth = $dbh->prepare('insert into COMPANY (company_id, name) values (?,?)');
    $sth->execute(1, 'CoolCo');
    $sth->execute(2, 'Data Inc');
    $sth->finish;
 
    $sth = $dbh->prepare('insert into BOSS (boss_id, first_name, last_name, company_id) values (?,?,?,?)');
    $sth->execute(1, 'Bob', 'Smith', 1);
    $sth->execute(2, 'Robert', 'Jones', 2);
    $sth->finish();

    $sth = $dbh->prepare('insert into EMPLOYEE (emp_id, name, boss_id, is_secret) values (?,?,?,?)');
    $sth->execute(1,'Joe', 1, 0);
    $sth->execute(2,'James', 1, 0);
    $sth->execute(3,'Jack', 2, 1);
    $sth->execute(4,'Jim', 2, 0);
    $sth->execute(5,'Jacob', 2, 1);
    $sth->finish();
    
    ok($dbh->commit(), 'Commit records to DB');

    UR::Object::Type->define(
        class_name => 'URT::Company',
        id_by => 'company_id',
        has => ['name'],
        table_name => 'COMPANY',
        data_source => 'URT::DataSource::SomeSQLite',
    );

    UR::Object::Type->define(
        class_name => "URT::Boss",
        id_by => 'boss_id',
        has => [
            boss_id             =>  { type => "Number" },
            first_name          =>  { type => "String" },
            last_name           =>  { type => "String" },
            company_id          =>  { type => "Number" },
            company             =>  { is => 'URT::Company', id_by => 'company_id' },
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
            emp_id         => { type => "Number" },
            name           => { type => "String" },
            is_secret      => { is => 'Boolean' },
            boss_id        => { type => 'Number'},
            boss           => { type => "URT::Boss", id_by => 'boss_id' },
            company_id     => { via => 'boss' },
            company        => { is => 'URT::Company', id_by => 'company_id' },
            company_name   => { via => 'company', to => 'name' },
        ],
        table_name => 'EMPLOYEE',
        data_source => 'URT::DataSource::SomeSQLite',
    );

    return 1;
}

