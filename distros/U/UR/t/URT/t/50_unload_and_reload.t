use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 86;
use URT::DataSource::SomeSQLite;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
$dbh->do('create table thing (thing_id integer PRIMARY KEY, color varchar)');
$dbh->do("insert into thing values (1,'blue')");
$dbh->do("insert into thing values (2,'red')");
$dbh->do("insert into thing values (3,'green')");

UR::Object::Type->define(
    class_name => 'URT::Thing',
    id_by => [
        thing_id => { is => 'Integer' },
    ],
    has => [
        color => { is => 'String' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name  => 'thing',
);

my $query_count;
URT::DataSource::SomeSQLite->create_subscription(
                                   method => 'query',
                                   callback => sub { $query_count++ });
# First, try with a single object
$query_count = 0;
my $thing = URT::Thing->get(1);
ok($thing, 'Got thing with ID 1');
is($query_count, 1, 'Made 1 query');

$query_count = 0;
$thing = URT::Thing->get(1);
ok($thing, 'Got thing with ID 1 again');
is($query_count, 0, 'Made no queries');

$query_count = 0;
my $cx = UR::Context->current;
$thing = $cx->reload('URT::Thing', 1);
ok($thing, 'Got thing with ID 1 with reload');
is($query_count, 1, 'make 1 query');
$query_count = 0;
$thing = URT::Thing->get(1);
ok($thing, 'Got thing with ID 1 again');
is($query_count, 0, 'Made no queries');

$query_count = 0;
$thing->unload();
$thing = URT::Thing->get(1);
ok($thing, 'Got thing with ID 1 after single-object unload with get()');
is($query_count, 1, 'Made 1 query');
$query_count = 0;
$thing = URT::Thing->get(1);
ok($thing, 'Got thing with ID 1 again');
is($query_count, 0, 'Made no queries');

$query_count = 0;
$thing->unload();
$thing = $cx->reload('URT::Thing', 1);
ok($thing, 'Got thing with ID 1 after single-object unload with reload');
is($query_count, 1, 'Made 1 query');
$query_count = 0;
$thing = URT::Thing->get(1);
ok($thing, 'Got thing with ID 1 again');
is($query_count, 0, 'Made no queries');

$query_count = 0;
URT::Thing->unload();
$thing = URT::Thing->get(1);
ok($thing, 'Got thing with ID 1 after class unload with get()');
is($query_count, 1, 'Made 1 query');
$query_count = 0;
$thing = URT::Thing->get(1);
ok($thing, 'Got thing with ID 1 again');
is($query_count, 0, 'Made no queries');

$query_count = 0;
URT::Thing->unload();
$thing = $cx->reload('URT::Thing', 1);
ok($thing, 'Got thing with ID 1 after class unload with reload');
is($query_count, 1, 'Made 1 query');
$query_count = 0;
$thing = URT::Thing->get(1);
ok($thing, 'Got thing with ID 1 again');
is($query_count, 0, 'Made no queries');




# Now try with all the objects of a class
$query_count = 0;
my @things = URT::Thing->get();
is(scalar(@things), 3, 'get() got 3 things');
is($query_count, 1, 'Made 1 query');

$query_count = 0;
@things = URT::Thing->get();
is(scalar(@things), 3, 'get() got 3 things again');
is($query_count, 0, 'Made no queries');

$query_count = 0;
@things = $cx->reload('URT::Thing');
is(scalar(@things), 3, 'got 3 things with reload');
is($query_count, 1, 'Made 1 query');
$query_count = 0;
@things = URT::Thing->get();
is(scalar(@things), 3, 'got 3 things again');
is($query_count, 0, 'Made no queries');


$query_count = 0;
$_->unload() foreach @things;
@things = URT::Thing->get();
ok(scalar(@things), 'Got thing with ID 1 after single-object unload with get()');
is($query_count, 1, 'Made 1 query');
$query_count = 0;
@things = URT::Thing->get();
is(scalar(@things), 3, 'got 3 things again');
is($query_count, 0, 'Made no queries');

$query_count = 0;
$_->unload() foreach @things;
@things = $cx->reload('URT::Thing');
is(scalar(@things), 3, 'Got 3 things  after single-object unload with reload');
is($query_count, 1, 'Made 1 query');
$query_count = 0;
@things = URT::Thing->get();
is(scalar(@things), 3, 'got 3 things again');
is($query_count, 0, 'Made no queries');

$query_count = 0;
URT::Thing->unload();
@things = URT::Thing->get();
is(scalar(@things), 3, 'Got 3 things after class unload with get()');
is($query_count, 1, 'Made 1 query');
$query_count = 0;
@things = URT::Thing->get();
is(scalar(@things), 3, 'got 3 things again');
is($query_count, 0, 'Made no queries');

$query_count = 0;
URT::Thing->unload();
@things = $cx->reload('URT::Thing');
is(scalar(@things), 3, 'Got 3 things after class unload with reload');
is($query_count, 1, 'Made 1 query');
$query_count = 0;
@things = URT::Thing->get();
is(scalar(@things), 3, 'got 3 things again');
is($query_count, 0, 'Made no queries');


# Try removing rows from the DB
ok($dbh->do('delete from thing where thing_id = 1'), 'delete thing ID 1 from the database directly');
$query_count = 0;
@things = URT::Thing->get();
is(scalar(@things), 3, 'got 3 things after delete with get');
is_deeply([sort map { $_->id } @things],
          [1,2,3],
          'Object IDs were correct');
is($query_count, 0, 'Made no queries');

$query_count = 0;
@things = $cx->reload('URT::Thing');
is(scalar(@things), 2, 'reload still returns 3 things'); # ID 1 is gone
is_deeply([sort map { $_->id } @things],
          [2,3],
          'Object IDs were correct');
is($query_count, 2, 'Made 2 queries');  # 1 to get all the objects, another to verify ID 1 was gone

$query_count = 0;
URT::Thing->unload();
@things = URT::Thing->get();
is(scalar(@things), 2, 'After class unload, get() returns 2 things');
is_deeply([sort map { $_->id } @things],
          [2,3],
          'Object IDs were correct');
is($query_count, 1, 'Made 1 query');

ok($dbh->do('delete from thing where thing_id = 2'), 'delete thing ID 2 from the database directly');
$query_count = 0;
@things = $cx->reload('URT::Thing');
is(scalar(@things), 1, 'After delete, reload returns 1 thing');  # ID 1 a and 2 are deleted
is_deeply([sort map { $_->id } @things],
          [3],
          'Object IDs were correct');
is($query_count, 2, 'Made 2 queries');  # 1 to get all the objects, another to verify ID 1 was gone

$query_count = 0;
URT::Thing->unload();
@things = $cx->reload('URT::Thing');
is(scalar(@things), 1, 'After delete, reload returns 1 thing');
is_deeply([sort map { $_->id } @things],
          [3],
          'Object IDs were correct');
is($query_count, 1, 'Made 1 query');


ok($dbh->do("insert into thing values (4,'orange')"), 'Insert a new row into the database directly');
$query_count = 0;
URT::Thing->unload();
@things = URT::Thing->get();
is(scalar(@things), 2, 'After DB insert and class unload, get() returns 2 things');
is_deeply([sort map { $_->id } @things],
          [3,4],
          'Object IDs were correct');
is($query_count, 1, 'Made 1 query');

ok($dbh->do("insert into thing values (5,'purple')"), 'Insert a new row into the database directly');
$query_count = 0;
@things = $cx->reload('URT::Thing');
is(scalar(@things), 3, 'After DB insert, reload returns 3 things');
is_deeply([sort map { $_->id } @things],
          [3,4,5],
          'Object IDs were correct');
is($query_count, 1, 'Made 1 query');


ok($dbh->do('delete from thing'), 'delete all rows from the database directly');
$query_count = 0;
URT::Thing->unload();
@things = URT::Thing->get();
is(scalar(@things), 0, 'After DB delete and class unload, get() returns 0 things');
is($query_count, 1, 'Made 1 query');


#$DB::single=1;
ok($dbh->do("insert into thing values (6,'black')"), 'Insert a new row into the database directly');
$query_count = 0;
URT::Thing->unload();
@things = URT::Thing->get();
is(scalar(@things), 1, 'After DB delete and class unload, get() returns 1 thing');
is($things[0]->id, 6, 'Object ID was correct');
is($query_count, 1, 'Made 1 query');


ok($dbh->do('delete from thing'), 'again, delete all rows from the database directly');
@things = $cx->reload('URT::Thing');
is(scalar(@things), 0, 'reload returns no things');

URT::Thing->unload();
@things = $cx->reload('URT::Thing');
is(scalar(@things), 0, 'reload returns 0 things after unload');
ok($dbh->do("insert into thing values (7,'brown')"), 'Insert a new row into the database directly');
$query_count = 0;
@things = $cx->reload('URT::Thing');
is(scalar(@things), 1, 'reload returns 1 thing');
is($query_count, 1, 'Made 1 query');

