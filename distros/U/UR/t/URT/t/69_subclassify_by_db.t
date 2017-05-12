use warnings;
use strict;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use URT::DataSource::SomeSQLite;

use Test::More tests => 41;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;;
ok($dbh, 'Got database handle');

# Employees are subclassed into eith Workers or Bosses.
# workers have no additional table, but bosses do
ok($dbh->do('create table EMPLOYEE
             (employee_id integer NOT NULL PRIMARY KEY, name varchar NOT NULL, subclass_name varchar NOT NULL)'),
   'create employee table');
ok($dbh->do('create table BOSS
             (boss_id integer NOT NULL PRIMARY KEY REFERENCES employee(employee_id), office varchar)'),
   'create boss table');

# odd numbered employees are workers, evens are bosses
my $insert_emp = $dbh->prepare('insert into employee values (?,?,?)');
my $insert_boss = $dbh->prepare('insert into boss values (?,?)');
foreach my $id ( 1 .. 10 ) {
    if ($id % 2) {
        # odd
        $insert_emp->execute($id, 'Bob '.$id, 'URT::Worker');
    } else {
        $insert_emp->execute($id, 'Bob '.$id, 'URT::Boss');
        $insert_boss->execute($id, $id);
    }
}
$insert_emp->finish;
$insert_boss->finish;



UR::Object::Type->define(
    class_name => 'URT::Employee',
    subclassify_by => 'subclass_name',
    is_abstract => 1,
    id_by => 'employee_id',
    has => [
        name => { type => "String" },
        subclass_name => { type => 'String' },
    ],
    table_name => 'EMPLOYEE',
    data_source => 'URT::DataSource::SomeSQLite',
);

UR::Object::Type->define(
    class_name => 'URT::Worker',
    is => 'URT::Employee',
);

UR::Object::Type->define(
    class_name => 'URT::Boss',
    is => 'URT::Employee',
    id_by => 'boss_id',
    has => [
        office => { is => 'String' },
    ],
    table_name => 'BOSS',
    data_source => 'URT::DataSource::SomeSQLite',
);

my @query_text;
my $query_count = 0;
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub {push @query_text, $_[2]; $query_count++}),
    'Created a subscription for query');

@query_text = ();
$query_count = 0;
my $o = URT::Employee->get(1);
ok($o, 'Got employee with id 1');
isa_ok($o,'URT::Worker');
is($query_count, 1, 'Made one query');
like($query_text[0],
     qr(from EMPLOYEE),
     'Query hits the EMPLOYEE table');
unlike($query_text[0], 
     qr(where subclass_name),
     'Query does not filter by subclass_name');
unlike($query_text[0],
     qr(from BOSS),
     'Query does not hit the BOSS table');


@query_text = ();
$query_count = 0;
$o = URT::Worker->get(3);
ok($o, 'Got worker with id 3');
isa_ok($o,'URT::Worker');
is($query_count, 1, 'Made one query');
like($query_text[0],
     qr(from EMPLOYEE),
     'Query hits the EMPLOYEE table');
like($query_text[0],
     qr(EMPLOYEE.subclass_name),
     'Query filters by subclass_name');
unlike($query_text[0],
     qr(from BOSS),
     'Query does not hit the BOSS table');


@query_text = ();
$query_count = 0;
$o = URT::Employee->get(2);
ok($o, 'Got employee with id 2');
isa_ok($o,'URT::Boss');
is($query_count, 2, 'Made 2 queries');
like($query_text[0],
    qr(from EMPLOYEE),
    'first query selects from EMPLOYEE table');
unlike($query_text[0],
    qr(BOSS),
    'first query does not touch the BOSS table');
unlike($query_text[0],
    qr(EMPLOYEE.subclass_name = \?),
    'first query does not filter by subclass_name');
like($query_text[1],
     qr(from BOSS),
     'second query selects from the BOSS table');
like($query_text[1],
     qr(INNER join EMPLOYEE),
     'second query joins to the EMPLOYEE table');
unlike($query_text[1],
    qr(EMPLOYEE.subclass_name = \?),
    'second query does not filter by subclass_name');


@query_text = ();
$query_count = 0;
$o = URT::Boss->get(4);
ok($o, 'Got boss with id 4');
isa_ok($o,'URT::Boss');
is($query_count, 1, 'Made 1 query');
like($query_text[0],
    qr(from BOSS),
    'Query selects from BOSS table');
like($query_text[0],
    qr(INNER join EMPLOYEE),
    'query joins to the EMPLOYEE table');
like($query_text[0],
    qr(EMPLOYEE.subclass_name = \?),
    'query filters by subclass_name');


@query_text = ();
$query_count = 0;
$o = URT::Worker->get(6);
ok(!$o, 'Did not find a Worker with id 6');
is($query_count, 1, 'Made 1 query');
like($query_text[0],
    qr(from EMPLOYEE),
    'query selects from EMPLOYEE table');
unlike($query_text[0],
    qr(BOSS),
    'query does not mention BOSS table');
like($query_text[0],
    qr(EMPLOYEE.subclass_name = \?),
    'query filters by subclass_name');

@query_text = ();
$query_count = 0;
$o = URT::Boss->get(7);
ok(!$o, 'Did not find a boss with id 6');
is($query_count, 1, 'Made 1 query');
like($query_text[0],
    qr(INNER join EMPLOYEE),
    'query joins to EMPLOYEE table');
like($query_text[0],
    qr(from BOSS),
    'query selects from BOSS table');
like($query_text[0],
    qr(EMPLOYEE.subclass_name = \?),
    'query filters by subclass_name');

