use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More skip_all => 'in development'; #tests => 34;
use URT::DataSource::SomeSQLite;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
&setup_classes_and_db($dbh);

is(UR::Context->current->query_underlying_context,
   undef,
   'Initial value for query_underlying_context is undef');


my $query_count = 0;
URT::DataSource::SomeSQLite->create_subscription(
                                   method => 'query',
                                   callback => sub { $query_count++ });

UR::Context->current->query_underlying_context(1);

$query_count = 0;
my $thing = URT::Thing->get(1);
ok($thing, 'Got thing id 1');
is($query_count,1, 'Made 1 query');

$query_count = 0;
$thing = URT::Thing->get(1);
ok($thing, 'Got thing id 1 again');
is($query_count,1, 'Made 1 query again');

$query_count = 0;
my @things = URT::Thing->get('id <' => 100);
is(scalar(@things), 3, 'Got all 3 things');
is($query_count, 1, 'Made 1 query');

$query_count = 0;
@things = URT::Thing->get('id <' => 100);
is(scalar(@things), 3, 'Got all 3 things again');
is($query_count, 1, 'Made 1 query');


$query_count = 0;
$thing = URT::Thing->get(1);
ok($thing, 'Got thing id 1 again');
is($query_count,1, 'Made 1 query again');


$query_count = 0;
$thing = URT::Thing->get(2);
ok($thing, 'Got thing id 2');
is($query_count,1, 'Made 1 query again');


$query_count = 0;
$thing = URT::Thing->get(4);
ok(! $thing, 'No thing with ID 4');
is($query_count,1, 'Made 1 query again');


UR::Context->current->query_underlying_context(undef);

$query_count = 0;
$thing = URT::Thing->get(2);
ok($thing, 'Got thing id 2');
is($query_count, 0, 'Made no queries because query_underlying_context is undef');


$query_count = 0;
$thing = URT::Thing->get(4);
ok(! $thing, 'No thing with ID 4');
is($query_count, 0, 'Made no queries because query_underlying_context is undef and query was done before');


ok($dbh->do("insert into thing values (10, 'Bubba', 'Person', 'red')"), 'insert new row into table');
$query_count = 0;
@things = URT::Thing->get('id <' => 100);
is(scalar(@things), 4, 'There are now 4 things');
is($query_count, 1, 'Made 1 query, even though get() was done before');


UR::Context->current->query_underlying_context(0);

$query_count = 0;
$thing = URT::Thing->get(2);
ok($thing, 'Got thing id 2');
is($query_count, 0, 'Made no queries, query_underlying_context is 0');

$query_count = 0;
$thing = URT::Thing->get(5);
ok(! $thing, 'No thing with ID 5');
is($query_count, 0, 'Made no queries because query_underlying_context is 0');


$query_count = 0;
@things = URT::Thing->get();
is(scalar(@things), 4, 'Got all 4 things');
is($query_count, 0, 'Made no queries because query_underlying_context is 0');




sub setup_classes_and_db {
    my $dbh = shift;

    ok($dbh, 'Got DB handle');

    ok( $dbh->do("create table thing (thing_id integer, name varchar, color varchar, type varchar)"),
       'Created thing table');

    my $ins_things = $dbh->prepare("insert into thing (thing_id, name, type, color) values (?,?,?,?)");
    foreach my $row ( ( [1, 'Bob', ,'Person', 'green' ],
                        [2, 'Fred', 'Person', 'black' ],
                        [3, 'Christine', 'Car', 'red' ] )) {
        ok($ins_things->execute(@$row), 'Inserted a thing');
    }

    ok($dbh->commit(), 'DB commit');
           
    UR::Object::Type->define(
        class_name => 'URT::Thing',
        id_by => 'thing_id',
        has => ['name', 'color', 'type' ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'thing',
    );
}

