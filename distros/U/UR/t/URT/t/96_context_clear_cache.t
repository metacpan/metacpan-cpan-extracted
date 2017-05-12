use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";

use URT;
use Test::More tests => 19;

use URT::DataSource::SomeSQLite;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle();
$dbh->do('create table thing (thing_id integer PRIMARY KEY, value varchar)');
my $sth = $dbh->prepare('insert into thing values (?,?)');
foreach my $id ( 1..5 ) {
    $sth->execute($id,$id);
}
$sth->finish;

UR::Object::Type->define(
    class_name => 'URT::Thing',
    id_by => 'thing_id',
    has => ['value'],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'thing',
);

my $query_count = 0;
URT::DataSource::SomeSQLite->create_subscription(
                                   method => 'query',
                                   callback => sub { $query_count++ });


$query_count = 0;
my @things = URT::Thing->get();
is(scalar(@things), 5, 'Got all 5 things');
is($query_count, 1, 'Made 1 query');

$query_count = 0;
@things = URT::Thing->is_loaded();
is(scalar(@things), 5, 'is_loaded returns all 5 things');
is($query_count, 0, 'Made no queries');


UR::Context->dump_warning_messages(0);
ok(UR::Context->current->clear_cache(), 'clear cache');

$query_count = 0;
@things = URT::Thing->is_loaded();
is(scalar(@things), 0, 'is_loaded now shows no things in memory');
is($query_count, 0, 'Made no queries');

$query_count = 0;
@things = URT::Thing->get();
is(scalar(@things), 5, 'Got all 5 things');
is($query_count, 1, 'Made 1 query');

ok(UR::Context->current->clear_cache(), 'clear cache');

$query_count = 0;
@things = URT::Thing->get('value <' => 3);
is(scalar(@things), 2, 'Got 2 things with value < 3');
is($query_count, 1, 'Made 1 query');


$query_count = 0;
@things = URT::Thing->get('value >' => 3);
is(scalar(@things), 2, 'Got 2 things with value > 3');
is($query_count, 1, 'Made 1 query');

ok(UR::Context->current->clear_cache(), 'clear cache');

my @things2 = URT::Thing->is_loaded();
is(scalar(@things2), 0, 'Still saw 0 things in memory');

#print Data::Dumper::Dumper(\@things);
is(scalar(@things), 2, '2 objects are still held in the list');
isa_ok($_, 'UR::DeletedRef') foreach @things;

