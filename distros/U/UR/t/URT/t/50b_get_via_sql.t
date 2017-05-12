use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 20;
use URT::DataSource::SomeSQLite;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
ok( $dbh->do('create table related_thing (thing_id integer not null primary key, name varchar not null)'),
    'create related_thing table');
ok( $dbh->do('create table thing (thing_id integer not null primary key, name varchar not null, related_id integer REFERENCES related_thing(thing_id))'),
    'create thing table');

my $insert_related = $dbh->prepare('insert into related_thing values (?,?)');
ok($insert_related, 'prepare to insert to related_thing');
$insert_related->execute(11,'red');
$insert_related->execute(12,'blue');
$insert_related->execute(13,'green');
$insert_related->finish();


my $insert_thing = $dbh->prepare('insert into thing values (?,?,?)');
ok($insert_thing, 'prepare to insert to thing');
$insert_thing->execute(1,'pink',11);
$insert_thing->execute(2,'cornflower',12);
$insert_thing->execute(3,'turquoise',13);
$insert_thing->finish();
ok($dbh->commit,'Commit data to DB');



UR::Object::Type->define(
    class_name => 'URT::RelatedThing',
    id_by => 'thing_id',
    has => [ 'name' ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'related_thing',
);

UR::Object::Type->define(
    class_name => 'URT::Thing',
    id_by => 'thing_id',  # not the same as related_thing.thing_id
    has => [
        name => { is => 'String' },
        related => { is => 'URT::RelatedThing', id_by => 'related_id' }
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'thing',
);
    

# Do a full join so the IDs returned by the SQL are duplicated
my @things = URT::Thing->get(sql => 'select thing.thing_id from thing join related_thing');
is(scalar(@things), 3, 'Got 3 things');
is_deeply([map { $_->id } @things],
            [1,2,3],
            'IDs are correct');

@things = URT::Thing->get(sql => 'select * from thing order by thing_id DESC');
is(scalar(@things), 3, 'Got 3 things');
is_deeply([map { $_->id } @things], 
            [1,2,3],
            'IDs are correct');

@things = eval { URT::Thing->get(sql => 'select name from thing') };
like($@,
    qr{The SQL supplied is missing one or more ID columns.*?missing: thing_id}s,
    'got exception from SQL without primary key');
is(scalar(@things), 0, 'Returned 0 things');


@things = URT::Thing->get(sql => ['select thing_id from thing where name = ?', 'pink']);
is(scalar(@things), 1, 'Got 1 thing with name pink using SQL with a placeholder');
is($things[0]->id, 1, 'It was the right ID');

@things = eval { URT::Thing->get(sql => ['select thing_id from thing where name = ? and thing_id = ?', 'pink']) };
like($@,
    qr{The number of params supplied \(1\) does not match the number of placeholders \(2\)},
    'got exception from SQL without primary key');
is(scalar(@things), 0, 'Returned 0 things');




ok( $dbh->do('create table multi_thing (id1 integer not null, id2 integer not null, name varchar, primary key(id1,id2))'),
    'Create table with 2 primary keys');
my $multi_insert = $dbh->prepare('insert into multi_thing values (?,?,?)');
$multi_insert->execute(1,1,'bob');
$multi_insert->execute(1,2,'bob');
$multi_insert->execute(2,1,'fred');
$multi_insert->execute(2,2,'fred');

UR::Object::Type->define(
    class_name => 'URT::MultiThing',
    id_by => ['id1', 'id2'],
    has => ['name'],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'multi_thing',
);

@things = URT::MultiThing->get(sql => 'select * from multi_thing order by id2');
is(scalar(@things), 4, 'Got 4 items from multi_thing table');
is_deeply([map { $_->id } @things],
        ["1\t1","1\t2","2\t1","2\t2"],
        'Objects returned in the right order');

@things = eval { URT::MultiThing->get(sql => 'select id1 from multi_thing') };
like($@,
    qr{The SQL supplied is missing one or more ID columns.*?missing: id2}s,
    'got exception from SQL missing one primary key');


@things = eval { URT::MultiThing->get(sql => 'select name from multi_thing') };
like($@,
    qr{The SQL supplied is missing one or more ID columns.*?missing: id1, id2}s,
    'got exception from SQL missing both primary keys');

