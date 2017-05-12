use strict;
use warnings;
use Test::More tests=> 13;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use UR;
use URT::DataSource::SomeSQLite;

# Get an object into memory with a query.  Re-get it with a second query (which will hit the DB
# again because it doesn't know it doesn't really have to).  Finally, do the second query again
# and it should not hit the DB

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got a database handle');

ok($dbh->do('create table PERSON
            ( person_id int NOT NULL PRIMARY KEY, name varchar, is_cool integer )'),
   'created person table');

ok(UR::Object::Type->define(
    class_name => 'URT::Person',
    table_name => 'PERSON',
    id_by => [
        person_id => { is => 'NUMBER' },
    ],
    has => [
        name      => { is => 'String' },
        is_cool   => { is => 'Boolean' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
),
'Created class for people');


# Insert some data
# Bob, Joe and Frank are cool
# Fred and Mike are not
my $insert = $dbh->prepare('insert into person values (?,?,?)');
foreach my $row ( [ 1, 'Bob',1 ], [2, 'Fred',0], [3, 'Mike',0],[4,'Joe',1], [5,'Frank', 1] ) {
    $insert->execute(@$row);
}
$insert->finish();

my $query_count = 0;
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub { $query_count++ }),
   'Created a subscription for query');


my @p = URT::Person->get(name => ['Bob','Joe','Frank']);
is(scalar(@p), 3, 'Got 3 people with an in-clause');
is_deeply([map { $_->id } @p], [1,4,5], 'Got the right people');
is($query_count, 1, 'Made 1 query');

$query_count = 0;
@p = URT::Person->get(is_cool => 1);
is(scalar(@p), 3, 'Got the same 3 people with a different query');
is_deeply([map { $_->id } @p], [1,4,5], 'Got the right people');
is($query_count, 1, 'Made 1 query');

$query_count = 0;
@p = URT::Person->get(is_cool => 1);
is(scalar(@p), 3, 'Got the same 3 people with the second query again');
is_deeply([map { $_->id } @p], [1,4,5], 'Got the right people');
is($query_count, 0, 'Made 1 query');


